# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Configure Go proxy for China
ENV GOPROXY=https://goproxy.cn,direct

RUN apk add --no-cache git

# Copy shared module first (dependency)
COPY shared/ ./shared/

# Copy web-api module
COPY web-api/ ./web-api/

# Download dependencies
RUN cd /app/web-api && go mod tidy

# Build the binary
RUN cd /app/web-api && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api ./cmd/api

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/web-api/api .

EXPOSE 8081

CMD ["./api"]