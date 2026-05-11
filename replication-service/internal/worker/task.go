package worker

import (
	"context"
	"crypto/sha256"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// TaskExecutor 任务执行器
type TaskExecutor struct {
	DB         *gorm.DB
	Registry   string // 目标registry地址
	MaxRetries int
}

// NewTaskExecutor 创建任务执行器
func NewTaskExecutor(db *gorm.DB, registry string) *TaskExecutor {
	return &TaskExecutor{
		DB:         db,
		Registry:   registry,
		MaxRetries: 3,
	}
}

// ReplicateRequest 复制请求
type ReplicateRequest struct {
	TaskID            string
	SourceImage       string
	DestNamespace     string
	DestRepository    string
	DestTag           string
	Username          string
	Password          string
	InsecureSkipVerify bool
}

// Execute 执行镜像复制任务
func (e *TaskExecutor) Execute(ctx context.Context, req *ReplicateRequest) error {
	// 1. 更新任务状态为running，进度10%
	var task models.ReplicationTask
	if err := e.DB.Where("id = ?", req.TaskID).First(&task).Error; err != nil {
		return fmt.Errorf("找不到任务: %v", err)
	}

	now := time.Now()
	task.Status = "running"
	task.Progress = 10
	task.StartedAt = &now
	e.DB.Save(&task)

	// 2. 构建目标镜像地址
	destImage := fmt.Sprintf("%s/%s/%s:%s", e.Registry, req.DestNamespace, req.DestRepository, req.DestTag)

	// 3. 创建任务详情记录
	startTime := time.Now()
	detail := models.ReplicationTaskDetail{
		TaskID:           task.ID,
		ResourceType:     "image",
		SourceNamespace:  parseNamespace(req.SourceImage),
		SourceRepository: parseRepository(req.SourceImage),
		SourceTag:        parseTag(req.SourceImage),
		Status:           "running",
		StartedAt:        &startTime,
	}
	e.DB.Create(&detail)

	// 更新进度到20%（开始复制）
	task.Progress = 20
	e.DB.Save(&task)

	// 4. 执行skopeo复制
	config := &SkopeoConfig{
		SourceImage:        req.SourceImage,
		DestImage:          destImage,
		Username:           req.Username,
		Password:           req.Password,
		InsecureSkipVerify: req.InsecureSkipVerify,
		DestInsecure:       true, // 目标registry（registry-core）使用HTTP，跳过TLS验证
		RetryTimes:         e.MaxRetries,
	}

	result, err := ExecuteSkopeo(ctx, config)

	// 输出调试日志
	log.Printf("Task %s: Skopeo stdout=%s, stderr=%s, digest=%s, err=%v", req.TaskID, result.Stdout, result.Stderr, result.Digest, err)

	// 更新进度到90%（复制完成，创建记录）
	task.Progress = 90
	e.DB.Save(&task)

	// 获取 digest - 如果 skopeo 没有返回，使用 HTTP GET 请求获取
	digest := result.Digest
	log.Printf("Task %s: Initial digest from skopeo: %s", req.TaskID, digest)
	if digest == "" && err == nil {
		// 使用 HTTP GET 请求从 registry 获取 manifest 并提取 digest
		// GET 比 HEAD 更可靠，因为 HEAD 可能不返回 Docker-Content-Digest header
		for retry := 0; retry < 3 && digest == ""; retry++ {
			manifestURL := fmt.Sprintf("http://%s/v2/%s/%s/manifests/%s", e.Registry, req.DestNamespace, req.DestRepository, req.DestTag)
			log.Printf("Task %s: Attempt %d: fetching manifest from %s", req.TaskID, retry+1, manifestURL)
			getResp, getErr := http.Get(manifestURL)
			if getErr != nil {
				log.Printf("Task %s: HTTP GET error: %v", req.TaskID, getErr)
				getResp = nil
			} else {
				log.Printf("Task %s: HTTP GET status=%d, headers=%v", req.TaskID, getResp.StatusCode, getResp.Header)
				if getResp.StatusCode == 200 {
					// 首先尝试从 header 获取
					digest = getResp.Header.Get("Docker-Content-Digest")
					log.Printf("Task %s: Docker-Content-Digest header: %s", req.TaskID, digest)
					if digest != "" && strings.HasPrefix(digest, "sha256:") {
						break
					}
					// 如果 header 没有，从响应体计算 digest
					body, readErr := io.ReadAll(getResp.Body)
					getResp.Body.Close()
					if readErr == nil && len(body) > 0 {
						log.Printf("Task %s: Manifest body length=%d, computing digest from body", req.TaskID, len(body))
						hash := sha256.Sum256(body)
						digest = fmt.Sprintf("sha256:%x", hash[:])
						log.Printf("Task %s: Computed digest: %s", req.TaskID, digest)
						break
					}
				}
				if getResp.Body != nil {
					getResp.Body.Close()
				}
			}
			// 等待后重试
			time.Sleep(time.Duration(retry+1) * time.Second)
		}
	}

	// 5. 更新任务详情和状态
	endTime := time.Now()
	if err != nil {
		detail.Status = "failed"
		detail.ErrorMessage = err.Error()
		detail.EndedAt = &endTime

		task.Status = "failed"
		task.Progress = 100
		task.FailedCount = 1
		task.TotalResources = 1
		task.EndedAt = &endTime
		task.ErrorMessage = err.Error()
	} else {
		detail.Status = "success"
		detail.EndedAt = &endTime
		detail.SourceDigest = digest
		detail.BytesTransferred = result.BytesTransferred

		task.Status = "success"
		task.Progress = 100
		task.SucceededCount = 1
		task.TotalResources = 1
		task.EndedAt = &endTime

		// 创建命名空间、仓库和标签记录
		if createErr := e.createNamespaceAndRepo(req.DestNamespace, req.DestRepository, req.DestTag, digest); createErr != nil {
			// 记录创建失败但复制成功
			task.ErrorMessage = "镜像复制成功但创建记录失败: " + createErr.Error()
			detail.ErrorMessage = createErr.Error()
		}
	}

	e.DB.Save(&detail)
	e.DB.Save(&task)

	return err
}

// createNamespaceAndRepo 创建命名空间、仓库和标签记录
func (e *TaskExecutor) createNamespaceAndRepo(namespace, repository, tag, digest string) error {
	// 检查 digest 是否有效
	if digest == "" || !strings.HasPrefix(digest, "sha256:") {
		return fmt.Errorf("无效的镜像 digest: %s", digest)
	}

	// 创建或获取命名空间
	var ns models.Namespace
	if err := e.DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
		ns = models.Namespace{
			Name:        namespace,
			DisplayName: namespace,
			Description: "通过镜像复制创建",
			IsPublic:    true,
		}
		if err := e.DB.Create(&ns).Error; err != nil {
			return fmt.Errorf("创建命名空间失败: %v", err)
		}
	}

	// 创建或获取仓库
	var repo models.Repository
	if err := e.DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
		repo = models.Repository{
			NamespaceID: ns.ID,
			Name:        repository,
			Description: "通过镜像复制创建",
			IsPublic:    true,
		}
		if err := e.DB.Create(&repo).Error; err != nil {
			return fmt.Errorf("创建仓库失败: %v", err)
		}
	}

	// 检查是否已存在相同 digest 的 manifest
	var manifest models.Manifest
	if err := e.DB.Where("repository_id = ? AND digest = ?", repo.ID, digest).First(&manifest).Error; err != nil {
		// 创建新的 manifest 记录
		manifest = models.Manifest{
			RepositoryID: repo.ID,
			Digest:       digest,
			MediaType:    "application/vnd.docker.distribution.manifest.v2+json",
		}
		if err := e.DB.Create(&manifest).Error; err != nil {
			return fmt.Errorf("创建 manifest 失败: %v", err)
		}
	}

	// 创建或更新标签
	var tagRecord models.Tag
	if err := e.DB.Where("repository_id = ? AND name = ?", repo.ID, tag).First(&tagRecord).Error; err != nil {
		tagRecord = models.Tag{
			RepositoryID: repo.ID,
			Name:         tag,
			ManifestID:   manifest.ID,
			PushedBy:     "replication",
			PushedAt:     time.Now(),
		}
		if err := e.DB.Create(&tagRecord).Error; err != nil {
			return fmt.Errorf("创建 tag 失败: %v", err)
		}
	} else {
		tagRecord.ManifestID = manifest.ID
		tagRecord.PushedAt = time.Now()
		if err := e.DB.Save(&tagRecord).Error; err != nil {
			return fmt.Errorf("更新 tag 失败: %v", err)
		}
	}

	// 已移除 image_count 更新（字段不存在）

	return nil
}

// parseNamespace 从镜像地址解析namespace
func parseNamespace(image string) string {
	parts := strings.Split(image, "/")
	if len(parts) >= 3 {
		return parts[1]
	}
	return "library"
}

// parseRepository 从镜像地址解析repository
func parseRepository(image string) string {
	parts := strings.Split(image, "/")
	if len(parts) >= 3 {
		repoParts := strings.Split(parts[2], ":")
		return repoParts[0]
	}
	if len(parts) == 2 {
		repoParts := strings.Split(parts[1], ":")
		return repoParts[0]
	}
	return ""
}

// parseTag 从镜像地址解析tag
func parseTag(image string) string {
	parts := strings.Split(image, ":")
	if len(parts) > 1 {
		return parts[len(parts)-1]
	}
	return "latest"
}