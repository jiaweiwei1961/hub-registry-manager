package main

import (
	"log"

	"hub-registry/gateway/internal/config"
	"hub-registry/gateway/internal/router"
)

func main() {
	cfg := config.Load()

	r := router.New(cfg)

	log.Printf("Starting gateway on port %d...", cfg.Server.Port)
	if err := r.Run(); err != nil {
		log.Fatalf("Failed to start gateway: %v", err)
	}
}
