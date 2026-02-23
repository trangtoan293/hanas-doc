# Hanas Documentation - Docker Setup

## Cấu trúc Docker

### Dockerfile (Multi-stage build)

| Stage | Mục đích | Image Base |
|-------|----------|------------|
| `deps` | Cài đặt dependencies | `node:20-alpine` |
| `builder` | Build Docusaurus site | `node:20-alpine` |
| `production` | Serve static files qua Nginx | `nginx:alpine` |
| `development` | Hot reload cho development | `node:20-alpine` |

## Sử dụng

### Development (Hot Reload)

```bash
# Chạy với profile dev
docker-compose --profile dev up docs-dev

# Truy cập: http://localhost:3000
```

### Production

```bash
# Build và chạy production
docker-compose --profile prod up -d docs-prod

# Truy cập: http://localhost:80
```

### Build thủ công

```bash
# Build production image
docker build --target production -t hanas-docs:latest .

# Build development image
docker build --target development -t hanas-docs:dev .

# Run container
docker run -p 80:80 hanas-docs:latest
```

## CI/CD Pipeline

### Các job:

1. **lint-and-typecheck**: Kiểm tra TypeScript và build
2. **build-and-push**: Build Docker image và push lên GitHub Container Registry
3. **deploy-staging**: Auto deploy khi push lên `develop` branch
4. **deploy-production**: Deploy khi tạo tag `v*`

### Tagging strategy:

- `main` branch: `main`, `sha-<short-sha>`
- `develop` branch: `develop`, `sha-<short-sha>`
- Tags: `v1.0.0`, `v1.0`

## Cấu hình Deploy

### Staging

Chỉnh sửa job `deploy-staging` trong `.github/workflows/ci-cd.yml`:

```yaml
- name: Deploy to staging
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.STAGING_HOST }}
    username: ${{ secrets.STAGING_USER }}
    key: ${{ secrets.STAGING_SSH_KEY }}
    script: |
      cd /opt/hanas-docs
      docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:develop
      docker-compose up -d
```

### Production

Chỉnh sửa job `deploy-production` trong `.github/workflows/ci-cd.yml`:

```yaml
- name: Deploy to production
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.PROD_HOST }}
    username: ${{ secrets.PROD_USER }}
    key: ${{ secrets.PROD_SSH_KEY }}
    script: |
      cd /opt/hanas-docs
      docker pull ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}
      docker-compose up -d
```

## Secrets cần thiết

Thêm vào GitHub Repository Settings → Secrets and variables → Actions:

| Secret | Mô tả |
|--------|-------|
| `STAGING_HOST` | IP/Hostname staging server |
| `STAGING_USER` | SSH username staging |
| `STAGING_SSH_KEY` | Private key SSH staging |
| `PROD_HOST` | IP/Hostname production server |
| `PROD_USER` | SSH username production |
| `PROD_SSH_KEY` | Private key SSH production |

## Clean up

```bash
# Dừng và xóa containers
docker-compose --profile dev down
docker-compose --profile prod down

# Xóa images
docker rmi hanas-docs:latest
docker rmi hanas-docs:dev

# Clean build cache
docker builder prune
```
