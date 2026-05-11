package handlers

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"

	"hub-registry/shared/pkg/models"
)

// ImageHandler 镜像处理器
type ImageHandler struct {
	DB          *gorm.DB
	RegistryURL string
	StoragePath string
	AuditLogger *AuditLogHandler
}

// NewImageHandler 创建 ImageHandler
func NewImageHandler(db *gorm.DB, registryURL string, storagePath string) *ImageHandler {
	return &ImageHandler{
		DB:          db,
		RegistryURL: registryURL,
		StoragePath: storagePath,
		AuditLogger: NewAuditLogHandler(db),
	}
}

// ImageInfo 镜像信息
type ImageInfo struct {
	Namespace  string   `json:"namespace"`
	Repository string   `json:"repository"`
	Tags       []string `json:"tags"`
	Size       int64    `json:"size"`
	CreatedAt  string   `json:"created_at"`
}

// UploadResult 上传结果
type UploadResult struct {
	Repository string `json:"repository"`
	Tag        string `json:"tag"`
	Digest     string `json:"digest"`
	Size       int64  `json:"size"`
}

// DockerTarManifest Docker save tar中的manifest.json结构
type DockerTarManifest struct {
	Config   string   `json:"Config"`
	RepoTags []string `json:"RepoTags"`
	Layers   []string `json:"Layers"`
}

// OCIIndex OCI image index 结构（skopeo 等工具导出的格式）
type OCIIndex struct {
	SchemaVersion int                      `json:"schemaVersion"`
	MediaType     string                   `json:"mediaType"`
	Manifests     []OCIIndexManifestEntry `json:"manifests"`
}

// OCIIndexManifestEntry OCI index manifest 条目
type OCIIndexManifestEntry struct {
	MediaType string                 `json:"mediaType"`
	Digest    string                 `json:"digest"`
	Size      int64                  `json:"size"`
	Annotations map[string]string    `json:"annotations"`
}

// OCIManifest OCI manifest 结构
type OCIManifest struct {
	SchemaVersion int                   `json:"schemaVersion"`
	MediaType     string                `json:"mediaType"`
	Config        OCIManifestDescriptor `json:"config"`
	Layers        []OCIManifestDescriptor `json:"layers"`
}

// OCIManifestDescriptor OCI manifest descriptor
type OCIManifestDescriptor struct {
	MediaType string `json:"mediaType"`
	Digest    string `json:"digest"`
	Size      int64  `json:"size"`
}

// UploadImage 上传镜像tar/tar.gz文件
func (h *ImageHandler) UploadImage(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "未找到上传文件"})
		return
	}

	namespace := c.PostForm("namespace")
	repository := c.PostForm("repository")
	tag := c.PostForm("tag")

	if namespace == "" || repository == "" || tag == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "缺少必要参数：namespace, repository, tag"})
		return
	}

	// 验证命名空间名称格式
	if !isValidNamespaceName(namespace) {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_NAME", "message": "命名空间名称只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾"})
		return
	}

	// 验证仓库名称格式
	if !isValidRepositoryName(repository) {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_NAME", "message": "仓库名称只能包含小写字母、数字、下划线、点、连字符，且不能以点或连字符开头或结尾"})
		return
	}

	// 验证标签名称格式
	if !isValidTagName(tag) {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_NAME", "message": "标签名称只能包含字母、数字、下划线、点、连字符"})
		return
	}

	// 从上下文获取当前用户名
	username := "anonymous"
	if u, exists := c.Get("username"); exists {
		username = u.(string)
	}

	tempPath := filepath.Join("/tmp", file.Filename)
	if err := c.SaveUploadedFile(file, tempPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "SAVE_ERROR", "message": "保存临时文件失败"})
		return
	}
	defer os.Remove(tempPath)

	result, err := h.processImageFile(tempPath, namespace, repository, tag, username)
	if err != nil {
		// 记录上传失败审计日志
		h.AuditLogger.CreateAuditLog(c, models.ActionUpload, models.ResourceImage, "", fmt.Sprintf("%s/%s:%s", namespace, repository, tag),
			"镜像上传失败", false, err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"code": "PROCESS_ERROR", "message": fmt.Sprintf("处理镜像文件失败: %v", err)})
		return
	}

	// 记录上传成功审计日志
	h.AuditLogger.CreateAuditLog(c, models.ActionUpload, models.ResourceImage, "", fmt.Sprintf("%s/%s:%s", namespace, repository, tag),
		"镜像上传成功", true, "")

	c.JSON(http.StatusOK, gin.H{"code": "success", "message": "镜像上传成功", "data": result})
}

// processImageFile 处理上传的tar/tar.gz文件
func (h *ImageHandler) processImageFile(filePath, namespace, repository, tag, username string) (*UploadResult, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var tr *tar.Reader
	if strings.HasSuffix(filePath, ".tar.gz") || strings.HasSuffix(filePath, ".tgz") {
		gzr, err := gzip.NewReader(f)
		if err != nil {
			return nil, fmt.Errorf("解压gzip失败: %v", err)
		}
		defer gzr.Close()
		tr = tar.NewReader(gzr)
	} else {
		tr = tar.NewReader(f)
	}

	var dockerManifests []DockerTarManifest
	var ociIndex *OCIIndex
	var configData []byte
	var configFileName string
	layersData := make(map[string][]byte)
	blobsData := make(map[string][]byte) // 存储所有 blobs/sha256/ 下的数据

	// 首先读取所有文件内容
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		buf := new(bytes.Buffer)
		if _, err := io.Copy(buf, tr); err != nil {
			return nil, err
		}

		// 存储所有 blobs/sha256/ 下的数据
		if strings.HasPrefix(hdr.Name, "blobs/sha256/") {
			// 提取 sha256 后的 digest 部分
			// 格式: blobs/sha256/abc123 或 blobs/sha256/abc123.blob
			digestPart := strings.TrimPrefix(hdr.Name, "blobs/sha256/")
			digestPart = strings.TrimSuffix(digestPart, ".blob")
			if len(digestPart) >= 64 {
				// sha256 digest 应该是 64 个十六进制字符
				blobsData[digestPart] = buf.Bytes()
				log.Printf("Found blob: %s, size: %d", digestPart, len(buf.Bytes()))
			}
		} else if hdr.Name == "manifest.json" {
			// Docker save 格式的 manifest
			if err := json.Unmarshal(buf.Bytes(), &dockerManifests); err != nil {
				log.Printf("Failed to parse Docker manifest.json: %v", err)
			}
		} else if hdr.Name == "index.json" {
			// OCI 格式的 index
			if err := json.Unmarshal(buf.Bytes(), &ociIndex); err != nil {
				log.Printf("Failed to parse OCI index.json: %v", err)
			}
		} else if strings.HasSuffix(hdr.Name, ".json") && !strings.HasPrefix(hdr.Name, "blobs/") {
			// Docker save 格式的 config 文件（在根目录）
			configFileName = hdr.Name
			configData = buf.Bytes()
			log.Printf("Found Docker config file: %s, size: %d", configFileName, len(configData))
		}
	}

	log.Printf("Parsed tar file: dockerManifests=%d, ociIndex=%v, configData=%d, blobsData=%d",
		len(dockerManifests), ociIndex != nil, len(configData), len(blobsData))

	// 判断是 Docker save 格式还是 OCI 格式
	if len(dockerManifests) > 0 && len(configData) > 0 {
		// Docker save 格式
		return h.processDockerFormat(dockerManifests, configData, configFileName, layersData, blobsData, namespace, repository, tag, username)
	} else if ociIndex != nil && len(blobsData) > 0 {
		// OCI 格式
		return h.processOCIFormat(ociIndex, blobsData, namespace, repository, tag, username)
	} else if len(blobsData) > 0 {
		// 只有 blobs 数据，尝试自动判断
		return h.processBlobsOnlyFormat(blobsData, namespace, repository, tag, username)
	}

	return nil, fmt.Errorf("无法识别镜像格式：缺少 manifest.json 或 index.json，且无有效 blob 数据")
}

// processDockerFormat 处理 Docker save 格式的镜像
func (h *ImageHandler) processDockerFormat(dockerManifests []DockerTarManifest, configData []byte, configFileName string, layersData map[string][]byte, blobsData map[string][]byte, namespace, repository, tag, username string) (*UploadResult, error) {
	// 获取 Docker tar manifest 中的 layer 信息
	dockerLayers := []string{}
	if len(dockerManifests) > 0 {
		dockerLayers = dockerManifests[0].Layers
	}

	// 如果没有从根目录读取到 config，尝试从 blobs 读取
	if len(configData) == 0 && len(blobsData) > 0 {
		// 从 manifest 中获取 config digest
		if len(dockerManifests) > 0 && dockerManifests[0].Config != "" {
			configDigestFromFile := strings.TrimSuffix(dockerManifests[0].Config, ".json")
			if len(configDigestFromFile) >= 64 {
				if data, ok := blobsData[configDigestFromFile]; ok {
					configData = data
					log.Printf("Found config from blobs: %s, size: %d", configDigestFromFile, len(configData))
				}
			}
		}
	}

	return h.pushImageToRegistry(configData, dockerLayers, layersData, blobsData, namespace, repository, tag, username)
}

// processOCIFormat 处理 OCI 格式的镜像
func (h *ImageHandler) processOCIFormat(ociIndex *OCIIndex, blobsData map[string][]byte, namespace, repository, tag, username string) (*UploadResult, error) {
	if len(ociIndex.Manifests) == 0 {
		return nil, fmt.Errorf("OCI index 中没有 manifest 条目")
	}

	// 获取第一个 manifest 条目
	manifestEntry := ociIndex.Manifests[0]
	manifestDigest := strings.TrimPrefix(manifestEntry.Digest, "sha256:")

	// 从 blobs 中读取 manifest 数据
	manifestData, ok := blobsData[manifestDigest]
	if !ok {
		return nil, fmt.Errorf("OCI manifest blob 不存在: sha256:%s", manifestDigest)
	}

	// 解析 OCI manifest
	var ociManifest OCIManifest
	if err := json.Unmarshal(manifestData, &ociManifest); err != nil {
		return nil, fmt.Errorf("解析 OCI manifest 失败: %v", err)
	}

	// 获取 config digest
	configDigest := strings.TrimPrefix(ociManifest.Config.Digest, "sha256:")
	configData, ok := blobsData[configDigest]
	if !ok {
		return nil, fmt.Errorf("OCI config blob 不存在: sha256:%s", configDigest)
	}

	log.Printf("OCI format: config=%s, layers=%d", configDigest, len(ociManifest.Layers))

	// 构建 layer 列表
	ociLayers := []string{}
	for _, layer := range ociManifest.Layers {
		layerDigest := strings.TrimPrefix(layer.Digest, "sha256:")
		ociLayers = append(ociLayers, "blobs/sha256/"+layerDigest)
	}

	return h.pushImageToRegistry(configData, ociLayers, nil, blobsData, namespace, repository, tag, username)
}

// processBlobsOnlyFormat 处理只有 blobs 数据的镜像（尝试自动识别）
func (h *ImageHandler) processBlobsOnlyFormat(blobsData map[string][]byte, namespace, repository, tag, username string) (*UploadResult, error) {
	// 尝试识别 manifest blob
	// manifest blob 通常包含 "schemaVersion" 和 "layers" 字段
	var manifestDigest string
	var manifestData []byte
	var configDigest string

	for digest, data := range blobsData {
		// 尝试解析为 manifest
		var testManifest OCIManifest
		if err := json.Unmarshal(data, &testManifest); err == nil {
			if testManifest.SchemaVersion == 2 && len(testManifest.Layers) > 0 {
				// 这是一个 manifest
				manifestDigest = digest
				manifestData = data
				configDigest = strings.TrimPrefix(testManifest.Config.Digest, "sha256:")
				log.Printf("Found manifest blob: sha256:%s, config: sha256:%s", digest, configDigest)
				break
			}
		}
	}

	if manifestDigest == "" {
		return nil, fmt.Errorf("无法识别 manifest blob")
	}

	// 读取 config blob
	configData, ok := blobsData[configDigest]
	if !ok {
		return nil, fmt.Errorf("config blob 不存在: sha256:%s", configDigest)
	}

	// 解析 manifest 获取 layers
	var ociManifest OCIManifest
	json.Unmarshal(manifestData, &ociManifest)

	// 构建 layer 列表
	layers := []string{}
	for _, layer := range ociManifest.Layers {
		layerDigest := strings.TrimPrefix(layer.Digest, "sha256:")
		layers = append(layers, "blobs/sha256/"+layerDigest)
	}

	return h.pushImageToRegistry(configData, layers, nil, blobsData, namespace, repository, tag, username)
}

// pushImageToRegistry 推送镜像到 registry-core
func (h *ImageHandler) pushImageToRegistry(configData []byte, dockerLayers []string, layersData map[string][]byte, blobsData map[string][]byte, namespace, repository, tag, username string) (*UploadResult, error) {

	var ns models.Namespace
	if err := h.DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
		ns = models.Namespace{Name: namespace, DisplayName: namespace, Description: "通过镜像上传创建"}
		if err := h.DB.Create(&ns).Error; err != nil {
			return nil, fmt.Errorf("创建命名空间失败: %v", err)
		}
	}

	var repo models.Repository
	if err := h.DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
		repo = models.Repository{NamespaceID: ns.ID, Name: repository, Description: "通过镜像上传创建"}
		if err := h.DB.Create(&repo).Error; err != nil {
			return nil, fmt.Errorf("创建仓库失败: %v", err)
		}
	}

	// 通过 registry-core API 推送所有 blob
	imageName := fmt.Sprintf("%s/%s", namespace, repository)

	// 推送 config blob
	configDigest := ""
	configSize := 0
	if len(configData) > 0 {
		hash := sha256.Sum256(configData)
		configDigest = fmt.Sprintf("sha256:%x", hash)
		configSize = len(configData)
		log.Printf("Pushing config blob: %s, size: %d", configDigest, configSize)
		if err := h.pushBlobToRegistry(imageName, configDigest, configData); err != nil {
			return nil, fmt.Errorf("推送config blob失败: %v", err)
		}
	} else {
		return nil, fmt.Errorf("未找到config数据，镜像文件可能无效")
	}

	// 推送 layer blobs，按照传入的 layer 列表顺序
	layerDigests := []string{}
	layerSizes := make(map[string]int)
	for _, layerPath := range dockerLayers {
		// layerPath 格式可能是 "blobs/sha256/abc123" 或直接 "abc123"
		layerName := layerPath
		if strings.HasPrefix(layerPath, "blobs/sha256/") {
			layerName = strings.TrimPrefix(layerPath, "blobs/sha256/")
		}

		// 优先从 blobsData 读取，如果没有则从 layersData 读取
		var data []byte
		var exists bool
		if blobsData != nil {
			data, exists = blobsData[layerName]
		}
		if !exists || len(data) == 0 {
			if layersData != nil {
				data, exists = layersData[layerName]
			}
		}
		if !exists || len(data) == 0 {
			log.Printf("Warning: layer %s not found or empty", layerName)
			continue
		}

		layerDigest := fmt.Sprintf("sha256:%s", layerName)
		log.Printf("Pushing layer blob: %s, size: %d", layerDigest, len(data))
		if err := h.pushBlobToRegistry(imageName, layerDigest, data); err != nil {
			return nil, fmt.Errorf("推送layer blob %s失败: %v", layerDigest, err)
		}
		layerDigests = append(layerDigests, layerDigest)
		layerSizes[layerDigest] = len(data)
	}

	// 验证至少有一个layer
	if len(layerDigests) == 0 {
		return nil, fmt.Errorf("未找到有效的layer数据，镜像文件可能无效")
	}

	// 构建并推送 manifest
	layersArray := []map[string]interface{}{}
	for _, layerDigest := range layerDigests {
		layersArray = append(layersArray, map[string]interface{}{
			"mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
			"digest":    layerDigest,
			"size":      layerSizes[layerDigest],
		})
	}

	manifestJSON := map[string]interface{}{
		"schemaVersion": 2,
		"mediaType":     "application/vnd.docker.distribution.manifest.v2+json",
		"config": map[string]interface{}{
			"mediaType": "application/vnd.docker.container.image.v1+json",
			"digest":    configDigest,
			"size":      configSize,
		},
		"layers": layersArray,
	}

	manifestData, _ := json.Marshal(manifestJSON)
	manifestDigest := fmt.Sprintf("sha256:%x", sha256.Sum256(manifestData))
	log.Printf("Pushing manifest: %s, size: %d, layers: %d", manifestDigest, len(manifestData), len(layerDigests))

	if err := h.pushManifestToRegistry(imageName, tag, manifestData); err != nil {
		return nil, fmt.Errorf("推送manifest失败: %v", err)
	}

	// 计算实际总大小
	actualTotalSize := int64(configSize)
	for _, digest := range layerDigests {
		actualTotalSize += int64(layerSizes[digest])
	}

	// 创建或查找 manifest 记录
	mf := models.Manifest{
		RepositoryID:  repo.ID,
		Digest:        manifestDigest,
		MediaType:     "application/vnd.docker.distribution.manifest.v2+json",
		ConfigDigest:  configDigest,
		ConfigSize:    int64(configSize),
		LayersCount:   len(layerDigests),
		TotalSize:     actualTotalSize,
	}

	// 检查是否已存在相同的manifest
	var existingManifest models.Manifest
	if err := h.DB.Where("repository_id = ? AND digest = ?", repo.ID, manifestDigest).First(&existingManifest).Error; err == nil {
		// manifest已存在，使用现有记录
		mf = existingManifest
		log.Printf("Manifest %s already exists, using existing record", manifestDigest)
	} else {
		// 创建新manifest
		if err := h.DB.Create(&mf).Error; err != nil {
			return nil, fmt.Errorf("创建manifest失败: %v", err)
		}
	}

	// 创建或更新 tag
	newTag := models.Tag{RepositoryID: repo.ID, Name: tag, ManifestID: mf.ID, PushedBy: username, PushedAt: time.Now()}
	if err := h.DB.Where("repository_id = ? AND name = ?", repo.ID, tag).Assign(newTag).FirstOrCreate(&newTag).Error; err != nil {
		log.Printf("创建或更新tag失败: %v", err)
	}

	return &UploadResult{
		Repository: fmt.Sprintf("%s/%s", namespace, repository),
		Tag:        tag,
		Digest:     manifestDigest,
		Size:       actualTotalSize,
	}, nil
}

// pushBlobToRegistry 推送 blob 到 registry-core
func (h *ImageHandler) pushBlobToRegistry(imageName, digest string, data []byte) error {
	// 初始化上传
	initURL := fmt.Sprintf("%s/v2/%s/blobs/uploads/", h.RegistryURL, imageName)
	resp, err := http.Post(initURL, "application/octet-stream", nil)
	if err != nil {
		return fmt.Errorf("初始化blob上传失败: %v", err)
	}
	resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted {
		return fmt.Errorf("初始化blob上传返回错误状态: %d", resp.StatusCode)
	}

	// 获取上传URL
	location := resp.Header.Get("Location")
	if location == "" {
		return fmt.Errorf("未获取到上传Location")
	}

	// 完成上传
	uploadURL := fmt.Sprintf("%s%s?digest=%s", h.RegistryURL, location, digest)
	req, _ := http.NewRequest("PUT", uploadURL, bytes.NewReader(data))
	req.Header.Set("Content-Type", "application/octet-stream")
	req.Header.Set("Content-Length", fmt.Sprintf("%d", len(data)))

	resp, err = http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("上传blob失败: %v", err)
	}
	resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("上传blob返回错误状态: %d", resp.StatusCode)
	}

	log.Printf("Blob %s uploaded successfully", digest)
	return nil
}

// pushManifestToRegistry 推送 manifest 到 registry-core
func (h *ImageHandler) pushManifestToRegistry(imageName, tag string, data []byte) error {
	manifestURL := fmt.Sprintf("%s/v2/%s/manifests/%s", h.RegistryURL, imageName, tag)
	req, _ := http.NewRequest("PUT", manifestURL, bytes.NewReader(data))
	req.Header.Set("Content-Type", "application/vnd.docker.distribution.manifest.v2+json")
	req.Header.Set("Content-Length", fmt.Sprintf("%d", len(data)))

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("上传manifest失败: %v", err)
	}
	resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		return fmt.Errorf("上传manifest返回错误状态: %d", resp.StatusCode)
	}

	log.Printf("Manifest uploaded successfully for %s:%s", imageName, tag)
	return nil
}

// ExportImage 导出镜像为tar.gz文件
func (h *ImageHandler) ExportImage(c *gin.Context) {
	namespace := c.Query("namespace")
	repository := c.Query("repository")
	tag := c.Query("tag")

	// 修正参数获取
	if repository == "" {
		repository = c.Query("namespace")
	}

	if namespace == "" || repository == "" || tag == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "缺少必要参数"})
		return
	}

	// 检查认证
	authHeader := c.GetHeader("Authorization")
	tokenParam := c.Query("token")
	if authHeader == "" && tokenParam == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": "UNAUTHORIZED", "message": "需要认证"})
		return
	}

	var ns models.Namespace
	if err := h.DB.Where("name = ?", namespace).First(&ns).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "命名空间不存在"})
		return
	}

	var repo models.Repository
	if err := h.DB.Where("namespace_id = ? AND name = ?", ns.ID, repository).First(&repo).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "仓库不存在"})
		return
	}

	var tagRecord models.Tag
	if err := h.DB.Where("repository_id = ? AND name = ?", repo.ID, tag).First(&tagRecord).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "标签不存在"})
		return
	}

	var manifest models.Manifest
	if err := h.DB.Where("id = ?", tagRecord.ManifestID).First(&manifest).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": "NOT_FOUND", "message": "Manifest不存在"})
		return
	}

	// 从 registry-core 获取 manifest 数据
	manifestURL := fmt.Sprintf("%s/v2/%s/%s/manifests/%s", h.RegistryURL, namespace, repository, manifest.Digest)
	log.Printf("Exporting image: %s/%s:%s, manifestURL: %s", namespace, repository, tag, manifestURL)
	manifestResp, err := http.Get(manifestURL)
	if err != nil {
		log.Printf("Failed to fetch manifest: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": "ERROR", "message": "获取manifest失败"})
		return
	}
	manifestData, err := io.ReadAll(manifestResp.Body)
	manifestResp.Body.Close()
	if err != nil {
		log.Printf("Failed to read manifest data: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": "ERROR", "message": "读取manifest失败"})
		return
	}
	log.Printf("Manifest fetched, size: %d bytes, digest: %s", len(manifestData), manifest.Digest)

	// 解析 manifest 获取 layers 和 config
	var manifestContent map[string]interface{}
	json.Unmarshal(manifestData, &manifestContent)

	layers := []string{}
	if layersArr, ok := manifestContent["layers"].([]interface{}); ok {
		for _, l := range layersArr {
			if layer, ok := l.(map[string]interface{}); ok {
				if digest, ok := layer["digest"].(string); ok {
					shortDigest := strings.TrimPrefix(digest, "sha256:")
					layers = append(layers, shortDigest)
				}
			}
		}
	}

	configDigest := ""
	if config, ok := manifestContent["config"].(map[string]interface{}); ok {
		if digest, ok := config["digest"].(string); ok {
			configDigest = strings.TrimPrefix(digest, "sha256:")
		}
	}

	// 先获取所有 blob 数据到内存，确保大小准确
	configData := []byte{}
	if configDigest != "" {
		configURL := fmt.Sprintf("%s/v2/%s/%s/blobs/sha256:%s", h.RegistryURL, namespace, repository, configDigest)
		log.Printf("Fetching config blob: %s", configURL)
		configResp, err := http.Get(configURL)
		if err != nil {
			log.Printf("Failed to fetch config %s: %v", configDigest, err)
		} else {
			configData, err = io.ReadAll(configResp.Body)
			configResp.Body.Close()
			if err != nil {
				log.Printf("Failed to read config %s: %v", configDigest, err)
			} else {
				log.Printf("Config %s fetched successfully, size: %d bytes", configDigest, len(configData))
			}
		}
	}

	layersData := make(map[string][]byte)
	for _, layerDigest := range layers {
		layerURL := fmt.Sprintf("%s/v2/%s/%s/blobs/sha256:%s", h.RegistryURL, namespace, repository, layerDigest)
		log.Printf("Fetching layer blob: %s", layerURL)
		layerResp, err := http.Get(layerURL)
		if err != nil {
			log.Printf("Failed to fetch layer %s: %v", layerDigest, err)
			continue
		}
		data, err := io.ReadAll(layerResp.Body)
		layerResp.Body.Close()
		if err != nil {
			log.Printf("Failed to read layer %s: %v", layerDigest, err)
			continue
		}
		log.Printf("Layer %s fetched successfully, size: %d bytes", layerDigest, len(data))
		layersData[layerDigest] = data
	}

	// 创建 Docker tar manifest（使用实际大小）
	dockerLayers := []string{}
	for _, layerDigest := range layers {
		dockerLayers = append(dockerLayers, layerDigest)
	}
	dockerManifest := DockerTarManifest{
		Config:   fmt.Sprintf("%s.json", configDigest),
		RepoTags: []string{fmt.Sprintf("%s/%s:%s", namespace, repository, tag)},
		Layers:   dockerLayers,
	}
	dockerManifestData, _ := json.Marshal([]DockerTarManifest{dockerManifest})

	// 设置响应头
	filename := fmt.Sprintf("%s-%s-%s.tar.gz", namespace, repository, tag)
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Header("Content-Type", "application/gzip")
	c.Header("Cache-Control", "no-cache")
	c.Status(http.StatusOK)

	// 创建 gzip 和 tar writer
	gzw := gzip.NewWriter(c.Writer)
	tw := tar.NewWriter(gzw)

	// 写入 manifest.json（使用实际大小）
	hdr := &tar.Header{Name: "manifest.json", Mode: 0644, Size: int64(len(dockerManifestData))}
	tw.WriteHeader(hdr)
	tw.Write(dockerManifestData)

	// 写入 config blob（使用实际读取的大小）
	if len(configData) > 0 {
		hdr := &tar.Header{Name: dockerManifest.Config, Mode: 0644, Size: int64(len(configData))}
		tw.WriteHeader(hdr)
		tw.Write(configData)
	}

	// 写入 layer blobs（使用实际读取的大小）
	actualTotalSize := int64(len(dockerManifestData)) + int64(len(configData))
	for _, layerDigest := range layers {
		data := layersData[layerDigest]
		if len(data) > 0 {
			hdr := &tar.Header{Name: fmt.Sprintf("blobs/sha256/%s", layerDigest), Mode: 0644, Size: int64(len(data))}
			tw.WriteHeader(hdr)
			tw.Write(data)
			actualTotalSize += int64(len(data))
		}
	}

	// 关闭写入器
	tw.Close()
	gzw.Close()

	// 更新 manifest 的 total_size 为实际大小
	if actualTotalSize > 0 {
		h.DB.Model(&manifest).Update("total_size", actualTotalSize)
		log.Printf("Updated manifest total_size: %d bytes (was %d)", actualTotalSize, manifest.TotalSize)
	}

	log.Printf("Image export completed: %s/%s:%s, actual size: %d bytes, config size: %d, layers count: %d", namespace, repository, tag, actualTotalSize, len(configData), len(layers))

	// 更新下载次数
	h.DB.Model(&repo).Update("pull_count", repo.PullCount+1)

	// 记录下载审计日志
	h.AuditLogger.CreateAuditLog(c, models.ActionDownload, models.ResourceImage, "", fmt.Sprintf("%s/%s:%s", namespace, repository, tag),
		"镜像导出下载", true, "")
}

// ListImages 获取可导出的镜像列表
func (h *ImageHandler) ListImages(c *gin.Context) {
	var images []ImageInfo
	var repos []models.Repository
	h.DB.Preload("Namespace").Find(&repos)

	for _, repo := range repos {
		var tags []models.Tag
		h.DB.Where("repository_id = ?", repo.ID).Find(&tags)

		tagNames := []string{}
		var totalSize int64 = 0
		for _, t := range tags {
			tagNames = append(tagNames, t.Name)
			var mf models.Manifest
			if h.DB.Where("id = ?", t.ManifestID).First(&mf).Error == nil {
				totalSize += mf.TotalSize
			}
		}

		if len(tagNames) > 0 {
			images = append(images, ImageInfo{
				Namespace:  repo.Namespace.Name,
				Repository: repo.Name,
				Tags:       tagNames,
				Size:       totalSize,
				CreatedAt:  formatBeijingTime(repo.CreatedAt),
			})
		}
	}

	c.JSON(http.StatusOK, gin.H{"data": images})
}

// ReplicateImageRequest 镜像复制请求
type ReplicateImageRequest struct {
	SourceImage        string `json:"source_image" binding:"required"`
	DestNamespace      string `json:"dest_namespace" binding:"required"`
	DestRepository     string `json:"dest_repository"`
	DestTag            string `json:"dest_tag"`
	Username           string `json:"username"`
	Password           string `json:"password"`
	InsecureSkipVerify bool   `json:"insecure_skip_verify"`
	RegistryEndpointID string `json:"registry_endpoint_id"`
}

// ReplicateImage 从其他Registry复制镜像到本地
func (h *ImageHandler) ReplicateImage(c *gin.Context) {
	var req ReplicateImageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "请求参数无效"})
		return
	}

	// 清理 source_image - 去除 Markdown 链接格式
	// 处理 [text](url) 格式，提取 url 部分
	req.SourceImage = cleanMarkdownLink(req.SourceImage)
	req.DestNamespace = cleanMarkdownLink(req.DestNamespace)
	req.DestRepository = cleanMarkdownLink(req.DestRepository)
	req.DestTag = cleanMarkdownLink(req.DestTag)

	// 解析源镜像地址
	// 格式: registry.example.com/namespace/image:tag 或 registry.example.com/image:tag
	sourceParts := strings.Split(req.SourceImage, "/")
	if len(sourceParts) < 2 {
		c.JSON(http.StatusBadRequest, gin.H{"code": "INVALID_REQUEST", "message": "源镜像地址格式无效"})
		return
	}

	// 解析tag
	sourcePath := strings.Join(sourceParts[1:], "/")
	tag := "latest"
	if strings.Contains(sourcePath, ":") {
		pathParts := strings.Split(sourcePath, ":")
		tag = pathParts[1]
	}

	// 确定目标仓库名和标签
	destRepo := req.DestRepository
	destTag := req.DestTag
	if destRepo == "" {
		imagePath := sourcePath
		if strings.Contains(imagePath, ":") {
			imagePath = strings.Split(imagePath, ":")[0]
		}
		if strings.Contains(imagePath, "/") {
			pathParts := strings.Split(imagePath, "/")
			destRepo = pathParts[len(pathParts)-1]
		} else {
			destRepo = imagePath
		}
	}
	if destTag == "" {
		destTag = tag
	}

	// 调用replication-service执行复制
	replicationURL := os.Getenv("REPLICATION_SERVICE_URL")
	if replicationURL == "" {
		replicationURL = "http://replication-service:8082"
	}

	// 构建请求体
	reqBody := map[string]interface{}{
		"source_image":        req.SourceImage,
		"dest_namespace":      req.DestNamespace,
		"dest_repository":     destRepo,
		"dest_tag":            destTag,
		"username":            req.Username,
		"password":            req.Password,
		"insecure_skip_verify": req.InsecureSkipVerify,
	}
	if req.RegistryEndpointID != "" {
		reqBody["registry_endpoint_id"] = req.RegistryEndpointID
	}

	jsonBody, _ := json.Marshal(reqBody)

	// 发送请求到replication-service
	resp, err := http.Post(replicationURL+"/api/v1/tasks", "application/json", bytes.NewBuffer(jsonBody))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR", "message": "调用复制服务失败: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": "INTERNAL_ERROR", "message": "解析响应失败"})
		return
	}

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, result)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    "success",
		"message": "镜像复制任务已创建",
		"data": gin.H{
			"task_id":        result["data"].(map[string]interface{})["task_id"],
			"status":         result["data"].(map[string]interface{})["status"],
			"source_image":   req.SourceImage,
			"dest_repository": fmt.Sprintf("%s/%s", req.DestNamespace, destRepo),
			"dest_tag":       destTag,
		},
	})
}

// cleanMarkdownLink 清理 Markdown 链接格式，提取纯文本或 URL
// 处理 [text](url) 格式，如果包含 http(s) 则返回 url，否则返回 text
func cleanMarkdownLink(s string) string {
	s = strings.TrimSpace(s)

	// 匹配 Markdown 链接格式: [text](url)
	if strings.HasPrefix(s, "[") && strings.Contains(s, "](") {
		// 提取 [ 和 ]( 之间的 text
		endBracket := strings.Index(s, "]")
		if endBracket > 1 {
			text := s[1:endBracket]
			// 提取 ( 和 ) 之间的 url
			startParen := strings.Index(s[endBracket:], "(")
			endParen := strings.Index(s[endBracket:], ")")
			if startParen != -1 && endParen > startParen {
				url := s[endBracket+startParen+1 : endBracket+endParen]
				// 如果 url 是 http(s) 链接，返回 url；否则返回 text
				if strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://") {
					// 从 url 中提取镜像地址（去掉 http:// 前缀）
					if idx := strings.Index(url, "://"); idx != -1 {
						return url[idx+3:]
					}
					return url
				}
				return text
			}
		}
	}

	return s
}

func parseUUID(s string) uuid.UUID {
	id, err := uuid.Parse(s)
	if err != nil {
		return uuid.Nil
	}
	return id
}