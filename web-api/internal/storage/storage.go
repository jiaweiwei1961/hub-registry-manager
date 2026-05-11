package storage

import (
	"context"
	"log"
	"strings"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"hub-registry/web-api/internal/config"
)

// StorageClient 存储客户端
type StorageClient struct {
	client *minio.Client
	bucket string
	useS3  bool
}

// NewStorageClient 创建存储客户端
func NewStorageClient(cfg *config.S3Config) *StorageClient {
	if cfg.Endpoint == "" {
		log.Println("S3 storage disabled, no cleanup will be performed")
		return &StorageClient{useS3: false}
	}

	// Parse endpoint to get host (remove http:// prefix)
	host := strings.TrimPrefix(cfg.Endpoint, "http://")
	host = strings.TrimPrefix(host, "https://")

	client, err := minio.New(host, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
	})
	if err != nil {
		log.Printf("Failed to connect to S3: %v", err)
		return &StorageClient{useS3: false}
	}

	log.Printf("S3 storage client initialized: endpoint=%s, bucket=%s", cfg.Endpoint, cfg.Bucket)
	return &StorageClient{
		client: client,
		bucket: cfg.Bucket,
		useS3:  true,
	}
}

// DeleteBlob 删除指定的 blob
// objectPath 格式: {namespace}/{repository}/{digest}.blob
func (s *StorageClient) DeleteBlob(objectPath string) error {
	if !s.useS3 {
		log.Printf("S3 not enabled, skipping blob deletion: %s", objectPath)
		return nil
	}

	ctx := context.Background()
	err := s.client.RemoveObject(ctx, s.bucket, objectPath, minio.RemoveObjectOptions{})
	if err != nil {
		log.Printf("Failed to delete blob from S3: %s, error: %v", objectPath, err)
		return err
	}

	log.Printf("Successfully deleted blob from S3: %s", objectPath)
	return nil
}

// DeleteManifest 删除 manifest blob
func (s *StorageClient) DeleteManifest(namespace, repository, digest string) error {
	objectPath := formatObjectPath(namespace, repository, digest)
	return s.DeleteBlob(objectPath)
}

// DeleteAllRepositoryBlobs 删除仓库下的所有 blobs
// 使用前缀删除
func (s *StorageClient) DeleteAllRepositoryBlobs(namespace, repository string) error {
	if !s.useS3 {
		log.Printf("S3 not enabled, skipping repository blobs deletion: %s/%s", namespace, repository)
		return nil
	}

	ctx := context.Background()
	prefix := namespace + "/" + repository + "/"

	// 列出所有对象
	objectsCh := s.client.ListObjects(ctx, s.bucket, minio.ListObjectsOptions{
		Prefix:    prefix,
		Recursive: true,
	})

	// 删除所有对象
	for obj := range objectsCh {
		if obj.Err != nil {
			log.Printf("Error listing object: %v", obj.Err)
			continue
		}

		err := s.client.RemoveObject(ctx, s.bucket, obj.Key, minio.RemoveObjectOptions{})
		if err != nil {
			log.Printf("Failed to delete object %s: %v", obj.Key, err)
		} else {
			log.Printf("Deleted object: %s", obj.Key)
		}
	}

	log.Printf("Completed deleting all blobs under prefix: %s", prefix)
	return nil
}

// DeleteNamespaceBlobs 删除命名空间下的所有 blobs
func (s *StorageClient) DeleteNamespaceBlobs(namespace string) error {
	if !s.useS3 {
		log.Printf("S3 not enabled, skipping namespace blobs deletion: %s", namespace)
		return nil
	}

	ctx := context.Background()
	prefix := namespace + "/"

	// 列出所有对象
	objectsCh := s.client.ListObjects(ctx, s.bucket, minio.ListObjectsOptions{
		Prefix:    prefix,
		Recursive: true,
	})

	// 删除所有对象
	for obj := range objectsCh {
		if obj.Err != nil {
			log.Printf("Error listing object: %v", obj.Err)
			continue
		}

		err := s.client.RemoveObject(ctx, s.bucket, obj.Key, minio.RemoveObjectOptions{})
		if err != nil {
			log.Printf("Failed to delete object %s: %v", obj.Key, err)
		} else {
			log.Printf("Deleted object: %s", obj.Key)
		}
	}

	log.Printf("Completed deleting all blobs under namespace: %s", namespace)
	return nil
}

// formatObjectPath 格式化对象路径
func formatObjectPath(namespace, repository, digest string) string {
	digestShort := strings.TrimPrefix(digest, "sha256:")
	return namespace + "/" + repository + "/" + digestShort + ".blob"
}