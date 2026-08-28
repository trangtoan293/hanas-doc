# Thông Tin Version — Langfuse

## Version Hiện Tại

| Thành phần | Version | Ghi chú |
|---|---|---|
| **Langfuse Server** | `<CẦN CHỐT>` | Image tag/digest phải pin trong release register |
| **Python SDK** | `<CẦN CHỐT>` | Version phải pin trong lock file |
| **Dify Integration** | Native (built-in) | Từ Dify 0.6.12+ |

## Version Matrix

| Langfuse Server | Python SDK | Dify Compatible | Key Features |
|---|---|---|---|
| **v3.x** (2025) | ≥ 2.x | Dify 1.0+ | Improved UI, async ingestion, webhooks |
| **v2.x** (2024) | ≥ 1.x | Dify 0.6.12+ | Datasets, evaluations, prompt management |
| **v1.x** (2023) | ≥ 0.x | Limited | Basic tracing, simple dashboard |

## SDK Compatibility

### Python SDK

```bash
pip install langfuse
```

| Python Version | SDK Support |
|---|---|
| **3.9+** | Full support |
| **3.8** | Limited |
| **< 3.8** | Không |

### Framework Integrations

| Framework | SDK Method | Ghi chú |
|---|---|---|
| **OpenAI SDK** | `from langfuse.openai import OpenAI` | Drop-in replacement |
| **LangChain** | `CallbackHandler` | Full chain tracing |
| **Dify** | Native (env vars) | No SDK needed |
| **Custom** | `@observe()` decorator | Manual instrumentation |

## Feature Availability

| Feature | v2.x | v3.x | Ghi chú |
|---|---|---|---|
| **Tracing** | Có | Có | Core feature |
| **Generations** | Có | Có | LLM call tracking |
| **Scores** | Có | Có | Automated + manual |
| **Prompts** | Có | Có | Version control |
| **Datasets** | Có | Có | Regression testing |
| **Sessions** | Có | Có | User session grouping |
| **Webhooks** | Không | Có | Event notifications |
| **RBAC** | Không | Có | Role-based access |
| **Async Ingestion** | Basic | Có | High-performance |

## Upgrade Notes

### Upgrade Server

```bash
# Pull image version đã được phê duyệt (không dùng latest)
docker compose pull langfuse

# Restart (migration chạy tự động)
docker compose up -d langfuse

# Check logs
docker compose logs -f langfuse
```

### Upgrade Python SDK

```bash
pip install --upgrade langfuse
```

> [!NOTE]
> Langfuse server tự động chạy database migration khi khởi động. Backup database trước khi upgrade.

## Tài Nguyên

| Tài Nguyên | Link |
|---|---|
| **GitHub** | [langfuse/langfuse](https://github.com/langfuse/langfuse) |
| **Documentation** | [langfuse.com/docs](https://langfuse.com/docs) |
| **Python SDK** | [langfuse/langfuse-python](https://github.com/langfuse/langfuse-python) |
| **Dify Integration** | [langfuse.com/docs/integrations/dify](https://langfuse.com/docs/integrations/dify) |
| **Roadmap** | [GitHub Discussions](https://github.com/langfuse/langfuse/discussions) |
