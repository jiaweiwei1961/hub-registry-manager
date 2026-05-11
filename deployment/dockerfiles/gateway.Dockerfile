# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Configure Go proxy for China
ENV GOPROXY=https://goproxy.cn,direct

RUN apk add --no-cache git

# Copy shared module first (dependency)
COPY shared/ ./shared/

# Copy gateway module
COPY gateway/ ./gateway/

# Download dependencies
RUN cd /app/gateway && go mod tidy

# Build the binary
RUN cd /app/gateway && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gateway ./cmd/gateway

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/gateway/gateway .

EXPOSE 8080

CMD ["./gateway"]