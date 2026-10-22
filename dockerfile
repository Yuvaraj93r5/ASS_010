# ==========================================
# STAGE 1: Static Code Validation & Quality Audit
# ==========================================
FROM alpine:3.19 AS validator
WORKDIR /app

# Copy the application source code into the temporary container
COPY index.html .

# Perform strict structural sanity checks
# Enforces that the file contains required valid HTML structures
RUN grep -q "<html>" index.html && \
    grep -q "🏭 Industrial IoT" index.html

# ==========================================
# STAGE 2: Lightweight Production Execution Layer
# ==========================================
FROM nginx:1.25-alpine

LABEL maintainer="engineering-team@predictive-maintenance.internal"
LABEL system="industrial-iot-monitoring"
LABEL layer="production-frontend"

# Wipe default web files included out-of-the-box by Nginx
RUN rm -rf /usr/share/nginx/html/*

# Pull the validated dashboard code from the host filesystem
COPY index.html /usr/share/nginx/html/index.html

# Expose standard web traffic interface port
EXPOSE 80

# Automated Production Container Healthcheck
# Runs every 10 seconds to verify that the Nginx server is actively responding.
# If a bad deployment breaks the web server, this check fails, causing Kubernetes 
# to reject the deployment rollout and initiate a rollback.
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start Nginx in the foreground to keep the container running
CMD ["nginx", "-g", "daemon off;"]
