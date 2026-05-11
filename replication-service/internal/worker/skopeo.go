package worker

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"time"
)

// SkopeoConfig skopeo命令配置
type SkopeoConfig struct {
	SourceImage        string
	DestImage          string
	Username           string
	Password           string
	InsecureSkipVerify bool
	DestInsecure       bool // 目标registry是否跳过TLS验证
	RetryTimes         int
}

// SkopeoResult skopeo执行结果
type SkopeoResult struct {
	Stdout          string
	Stderr          string
	Success         bool
	Digest          string
	BytesTransferred int64
	Duration        time.Duration
}

// BuildSkopeoCommand 构建skopeo copy命令
func BuildSkopeoCommand(config *SkopeoConfig) []string {
	cmd := []string{"copy"}

	// 添加认证
	if config.Username != "" && config.Password != "" {
		cmd = append(cmd, fmt.Sprintf("--src-creds=%s:%s", config.Username, config.Password))
	}

	// TLS验证设置
	cmd = append(cmd, fmt.Sprintf("--src-tls-verify=%v", !config.InsecureSkipVerify))
	cmd = append(cmd, fmt.Sprintf("--dest-tls-verify=%v", !config.DestInsecure))

	// 重试次数
	if config.RetryTimes > 0 {
		cmd = append(cmd, fmt.Sprintf("--retry-times=%d", config.RetryTimes))
	} else {
		cmd = append(cmd, "--retry-times=3")
	}

	// 源和目标镜像
	cmd = append(cmd, "docker://"+config.SourceImage)
	cmd = append(cmd, "docker://"+config.DestImage)

	return cmd
}

// ExecuteSkopeo 执行skopeo命令
func ExecuteSkopeo(ctx context.Context, config *SkopeoConfig) (*SkopeoResult, error) {
	start := time.Now()

	args := BuildSkopeoCommand(config)
	log.Printf("Executing skopeo with args: %v", args)
	cmd := exec.CommandContext(ctx, "skopeo", args...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()

	result := &SkopeoResult{
		Stdout:   stdout.String(),
		Stderr:   stderr.String(),
		Duration: time.Since(start),
	}

	log.Printf("Skopeo stdout: %s", stdout.String())
	log.Printf("Skopeo stderr: %s", stderr.String())

	if err != nil {
		result.Success = false
		return result, fmt.Errorf("skopeo执行失败: %v, stderr: %s", err, stderr.String())
	}

	result.Success = true

	// 先尝试从 stderr 解析 digest（skopeo copy 输出到 stderr）
	result.Digest = parseDigestFromOutput(stderr.String())
	log.Printf("Parsed digest from stderr: %s", result.Digest)

	// 如果没有解析到，尝试从 stdout 解析
	if result.Digest == "" {
		result.Digest = parseDigestFromOutput(stdout.String())
		log.Printf("Parsed digest from stdout: %s", result.Digest)
	}

	// 如果没有解析到，使用 skopeo inspect 获取 digest（带重试）
	if result.Digest == "" {
		for retry := 0; retry < 3; retry++ {
			log.Printf("Trying skopeo inspect (retry %d) for image: %s", retry+1, config.DestImage)
			inspectDigest, inspectErr := getDigestFromInspect(ctx, config.DestImage, config.DestInsecure)
			if inspectErr == nil && inspectDigest != "" {
				result.Digest = inspectDigest
				log.Printf("Got digest from inspect: %s", result.Digest)
				break
			}
			log.Printf("Skopeo inspect failed: %v", inspectErr)
			// 等待一段时间后重试（镜像可能需要时间注册）
			time.Sleep(time.Duration(retry+1) * time.Second)
		}
	}

	result.BytesTransferred = parseBytesFromOutput(stderr.String())

	return result, nil
}

// getDigestFromInspect 使用 skopeo inspect 获取镜像 digest
func getDigestFromInspect(ctx context.Context, destImage string, destInsecure bool) (string, error) {
	args := []string{"inspect", "--format", "{{.Digest}}"}
	if destInsecure {
		args = append(args, "--tls-verify=false")
	}
	args = append(args, "docker://"+destImage)

	cmd := exec.CommandContext(ctx, "skopeo", args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("skopeo inspect 失败: %v", err)
	}

	digest := strings.TrimSpace(stdout.String())
	if strings.HasPrefix(digest, "sha256:") {
		return digest, nil
	}
	return "", nil
}

// parseDigestFromOutput 从skopeo输出解析镜像digest
func parseDigestFromOutput(output string) string {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)

		// 格式1: "Digest: sha256:xxx"
		if strings.Contains(line, "Digest:") {
			parts := strings.Split(line, "Digest:")
			if len(parts) > 1 {
				digest := strings.TrimSpace(parts[1])
				if strings.HasPrefix(digest, "sha256:") {
					// 只保留有效的 hash 部分（64字符）
					if len(digest) >= 71 {
						return digest[:71]
					}
					return digest
				}
			}
		}

		// 格式2: "manifest sha256:xxx"
		if strings.Contains(line, "manifest sha256:") {
			parts := strings.Split(line, "sha256:")
			if len(parts) > 1 {
				hashPart := strings.TrimSpace(parts[1])
				// 只保留有效的 hash 部分（64字符）
				if len(hashPart) >= 64 {
					return "sha256:" + hashPart[:64]
				}
				return "sha256:" + hashPart
			}
		}

		// 格式3: 单独的 sha256:xxx 行
		if strings.HasPrefix(line, "sha256:") {
			if len(line) >= 71 {
				return line[:71]
			}
			if len(line) == 70 { // sha256: + exactly 64 chars
				return line
			}
		}

		// 格式4: "Copying blob sha256:xxx done"
		if strings.Contains(line, "sha256:") && strings.Contains(line, "done") {
			parts := strings.Split(line, "sha256:")
			if len(parts) > 1 {
				hashPart := strings.Fields(parts[1])[0] // 取第一个空格前的部分
				if len(hashPart) >= 64 {
					return "sha256:" + hashPart[:64]
				}
				return "sha256:" + hashPart
			}
		}
	}
	return ""
}

// parseBytesFromOutput 从skopeo输出解析传输字节
func parseBytesFromOutput(output string) int64 {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		// skopeo输出格式: "Copying blob ..." 或 "Copying config ..."
		// 包含大小信息如 "30.7 MB"
		if strings.Contains(line, "Copying") {
			// 简化处理，不精确计算
			// 实际大小可以从manifest获取
		}
	}
	return 0
}

// TestSkopeo 测试skopeo是否可用
func TestSkopeo() error {
	cmd := exec.Command("skopeo", "--version")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("skopeo不可用: %v", err)
	}
	return nil
}