# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Configure Go proxy for China
ENV GOPROXY=https://goproxy.cn,direct

RUN apk add --no-cache git

# Copy shared module first (dependency)
COPY shared/ ./shared/

# Copy registry-core module
COPY registry-core/ ./registry-core/

# Download dependencies
RUN cd /app/registry-core && go mod tidy

# Build the binary
RUN cd /app/registry-core && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o registry ./cmd/registry

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/registry-core/registry .

EXPOSE 5000

CMD ["./registry"]