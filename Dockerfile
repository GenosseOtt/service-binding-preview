# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Production stage
FROM node:20-alpine

# Add labels for better container metadata and Kyma compatibility
LABEL org.opencontainers.image.source="https://github.com/OWNER/service-binding-preview"
LABEL org.opencontainers.image.description="Service Binding Preview Application"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="your-email@example.com"

# Create app directory
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /app/node_modules ./node_modules

# Copy application code
COPY server.js .
COPY package*.json ./

# Create a non-root user (important for Kyma security policies)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of the app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port 3000 (can be remapped by Kyma)
EXPOSE 3000

# Health check endpoint - Kyma uses /healthz by default but we keep both
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Set environment variables for production
ENV NODE_ENV=production

# Start the application
CMD ["node", "server.js"]
