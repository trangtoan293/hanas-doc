# Thông Tin Version — Dify

## Version Hiện Tại

| Thành phần | Version | Ghi chú |
|---|---|---|
| **Dify Platform** | 1.0.0+ (Dify 2.0 architecture) | Plugin system, Knowledge Pipeline |
| **Workflow Format** | DSL v0.4.0 | `Demo GLPI Chatflow.yml` |
| **Plugin: vLLM** | `yangyaofei/vllm:0.1.3` | Direct vLLM integration |
| **Plugin: OpenAI-compatible** | `langgenius/openai_api_compatible:0.0.16` | Generic OpenAI API |

## Version Matrix

| Dify Version | Key Features | Langfuse | vLLM Compatible |
|---|---|---|---|
| **2.0+** | Plugin ecosystem, Knowledge Pipeline | ✅ Native | ✅ |
| **1.0** | Graph-based workflow engine | ✅ Native | ✅ |
| **0.6.12+** | Langfuse integration | ✅ Native | ✅ |
| **0.6.x** | Visual workflow builder | ❌ | ✅ |

## Breaking Changes

### Dify 2.0 (2025)

- **Plugin Architecture**: Model providers chuyển sang plugin system
- **Knowledge Pipeline**: Thay thế cách indexing cũ bằng pipeline mới
- **Queue-based Graph Engine**: Cải thiện workflow execution
- **Migration**: Cần re-configure model providers sau upgrade

### Dify 1.0

- **Workflow engine**: Chuyển từ linear sang graph-based
- **Agent framework**: Hỗ trợ multi-agent strategy
- **DSL format**: Cập nhật format cho workflow export/import

## Upgrade Notes

### Từ 0.x lên 1.0

```bash
# 1. Backup database
pg_dump -h db-host -U dify -d dify > dify_backup.sql

# 2. Pull image mới
docker compose pull

# 3. Restart services
docker compose up -d

# 4. Migration sẽ chạy tự động
# Kiểm tra logs: docker compose logs -f api
```

### Từ 1.0 lên 2.0

```bash
# 1. Backup toàn bộ
pg_dump -h db-host -U dify -d dify > dify_backup_before_v2.sql

# 2. Đọc changelog: https://github.com/langgenius/dify/releases

# 3. Update env vars (nếu có thay đổi)
# Kiểm tra .env.example mới

# 4. Pull và restart
docker compose pull
docker compose up -d

# 5. Re-configure model providers nếu cần
```

## Tài Nguyên

| Tài Nguyên | Link |
|---|---|
| **GitHub** | [langgenius/dify](https://github.com/langgenius/dify) |
| **Documentation** | [docs.dify.ai](https://docs.dify.ai) |
| **Plugin Marketplace** | Truy cập qua Dify Console |
| **Community** | [Discord](https://discord.gg/dify) |
