# Multi-stage build for Docusaurus
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Copy package files
COPY website/package.json website/package-lock.json* ./
RUN npm ci --only=production

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY website/ ./website/
COPY docs/ ./docs/

# Build the Docusaurus site
WORKDIR /app/website
RUN npm run build

# Stage 3: Production (Nginx)
FROM nginx:alpine AS production

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files from builder stage
COPY --from=builder /app/website/build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

# Stage 4: Development (optional)
FROM node:20-alpine AS development
WORKDIR /app/website

COPY website/package.json website/package-lock.json* ./
RUN npm install

COPY website/ .
COPY docs/ ../docs

EXPOSE 3000

CMD ["npm", "run", "start"]
