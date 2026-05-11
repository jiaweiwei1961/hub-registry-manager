package worker

import (
	"context"
	"sync"

	"gorm.io/gorm"
)

// WorkerPool 工作池
type WorkerPool struct {
	DB         *gorm.DB
	Registry   string
	MaxWorkers int
	tasks      chan *ReplicateRequest
	stopChan   chan struct{}
	wg         sync.WaitGroup
	executors  []*TaskExecutor
}

// NewWorkerPool 创建工作池
func NewWorkerPool(db *gorm.DB, registry string, maxWorkers int) *WorkerPool {
	return &WorkerPool{
		DB:         db,
		Registry:   registry,
		MaxWorkers: maxWorkers,
		tasks:      make(chan *ReplicateRequest, 100),
		stopChan:   make(chan struct{}),
		executors:  make([]*TaskExecutor, maxWorkers),
	}
}

// Start 启动工作池
func (p *WorkerPool) Start() {
	for i := 0; i < p.MaxWorkers; i++ {
		p.executors[i] = NewTaskExecutor(p.DB, p.Registry)
		p.wg.Add(1)
		go p.worker(i)
	}
}

// Stop 停止工作池
func (p *WorkerPool) Stop() {
	close(p.stopChan)
	p.wg.Wait()
}

// Submit 提交任务
func (p *WorkerPool) Submit(req *ReplicateRequest) error {
	select {
	case p.tasks <- req:
		return nil
	default:
		return ErrPoolFull
	}
}

// worker 工作线程
func (p *WorkerPool) worker(id int) {
	defer p.wg.Done()

	executor := p.executors[id]
	ctx := context.Background()

	for {
		select {
		case <-p.stopChan:
			return
		case req := <-p.tasks:
			executor.Execute(ctx, req)
		}
	}
}

// ErrPoolFull 池满错误
var ErrPoolFull = &PoolError{Message: "worker pool is full"}

// PoolError 池错误
type PoolError struct {
	Message string
}

func (e *PoolError) Error() string {
	return e.Message
}