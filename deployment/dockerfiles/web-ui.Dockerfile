# Production stage - use pre-built dist folder
FROM nginx:alpine

# Copy built files directly (pre-built locally)
COPY dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]