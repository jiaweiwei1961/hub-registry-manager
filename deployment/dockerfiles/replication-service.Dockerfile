# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Configure Go proxy for China
ENV GOPROXY=https://goproxy.cn,direct

RUN apk add --no-cache git

# Copy shared module first (dependency)
COPY shared/ ./shared/

# Copy replication-service module
COPY replication-service/ ./replication-service/

# Download dependencies
RUN cd /app/replication-service && go mod tidy

# Build the binary
RUN cd /app/replication-service && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o replication ./cmd/replication

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates skopeo

WORKDIR /root/

COPY --from=builder /app/replication-service/replication .

EXPOSE 8082

CMD ["./replication"]