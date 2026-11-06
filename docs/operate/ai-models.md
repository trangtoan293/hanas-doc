---
title: Cấu hình mô hình AI cho Kapas
sidebar_label: Mô hình AI
sidebar_position: 8
description: Khai báo provider và model cho Kapas, dùng endpoint OpenAI-compatible hoặc mô hình on-prem, các biến môi trường chính và khuyến nghị.
---

Trang này hướng dẫn quản trị viên cấu hình mô hình ngôn ngữ (LLM) cho Kapas, gồm dịch vụ đám mây và mô hình chạy trong mạng nội bộ.

## Khái niệm

- **Provider**: nơi cung cấp mô hình (endpoint, khóa API).
- **Model**: mô hình cụ thể của provider.
- **Active model**: model Kapas đang dùng để trả lời.

Kapas hỗ trợ nhiều provider tích hợp sẵn (OpenAI và API tương thích, Azure OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter...) và **endpoint OpenAI-compatible tùy chỉnh**. Với mô hình tự vận hành, dùng vLLM, Ollama, LM Studio hoặc bất kỳ máy chủ nào nói giao thức OpenAI-compatible.

Khi trả lời, Kapas chọn model theo thứ tự: model chỉ định trong request, model của agent, rồi model mặc định toàn cục.

## Điều kiện cần

- Quyền quản trị Kapas khi đổi model mặc định toàn cục.
- Endpoint LLM truy cập được từ Pod Kapas. Địa chỉ `127.0.0.1` trong Pod là chính Pod, không phải máy chủ model của bạn.
- Khóa API (nếu provider yêu cầu) được lưu trong Secret, không đặt trong values.

## Cấu hình qua giao diện

Trong Hanas Console, phần cấu hình AI nằm ở **Settings** > **Integrations** > **AI Config**.

1. Đăng nhập Kapas Console bằng tài khoản quản trị.
2. Mở **Models**.
3. Chọn provider hoặc thêm provider **OpenAI-compatible** tùy chỉnh. Nhập base URL, khóa API nếu có.
4. Dùng chức năng khám phá và kiểm tra để lấy danh sách model và thử kết nối.
5. Đặt model làm **active model** toàn cục, hoặc chọn model riêng cho từng agent.

Người dùng thường chọn được model cho agent của riêng họ; đổi mặc định toàn cục cần quyền admin.

## Cấu hình ban đầu bằng biến môi trường

Khi chưa có active model, Kapas khởi tạo provider và model mặc định từ biến môi trường. Giá trị đã lưu trong giao diện không bị ghi đè ở lần khởi động sau.

```yaml
# ví dụ: endpoint OpenAI-compatible nằm trong mạng nội bộ
env:
  QWENPAW_DEFAULT_PROVIDER: "<provider-id>"
  QWENPAW_DEFAULT_MODEL: "<model-name>"
  QWENPAW_DEFAULT_BASE_URL: "http://llm.internal.example:8000/v1"
  # khóa API đặt trong Secret, không ghi vào values
  QWENPAW_DEFAULT_API_KEY: "<từ Secret>"
```

| Biến | Ý nghĩa |
|---|---|
| `QWENPAW_DEFAULT_PROVIDER` | Provider mặc định. |
| `QWENPAW_DEFAULT_MODEL` | Tên model mặc định. |
| `QWENPAW_DEFAULT_BASE_URL` | Base URL của endpoint (với OpenAI-compatible thường kết thúc bằng `/v1`). |
| `QWENPAW_DEFAULT_API_KEY` | Khóa API, nếu provider yêu cầu. |
| `QWENPAW_DEFAULT_PROVIDER_NAME` | Tên hiển thị của provider tùy chỉnh. |
| `EMBEDDING_MODEL_NAME`, `EMBEDDING_BASE_URL`, `EMBEDDING_API_KEY` | Endpoint embedding cho tính năng bộ nhớ và tìm kiếm. |

Cấu hình này nằm trong release Kapas của Helm; truyền biến bổ sung qua Secret `extraEnv`. Xem [Tham chiếu cấu hình](configuration.md).

## Biến môi trường tích hợp liên quan

| Nhóm | Biến |
|---|---|
| Query engine | `DREMIO_URL`, `DREMIO_KEYCLOAK_AUDIENCE` |
| Ontology, dbt | `ONTOLOGY_API_URL`, `DBT_RUNNER_URL` |
| Superset | `SUPERSET_URL`, `SUPERSET_KEYCLOAK_AUDIENCE`, `SUPERSET_DATABASE_NAME` |
| Giới hạn | `QWENPAW_USER_REQUESTS_PER_MINUTE`, `QWENPAW_GLOBAL_REQUESTS_PER_MINUTE`, `QWENPAW_DAILY_TOKEN_BUDGET`, `QWENPAW_TENANT_DAILY_TOKEN_BUDGET` |
| Truy vết | `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_BASE_URL` (đủ ba biến thì bật) |

Tên biến giữ nguyên để bạn tra cứu chính xác. Ngân sách token mặc định trong Helm hiện là 5.000.000 mỗi ngày; đây là giá trị cấu hình, bạn nên điều chỉnh theo nhu cầu.

## Mô hình on-prem

1. Chạy máy chủ mô hình trong mạng nội bộ (ví dụ vLLM, Ollama).
2. Bảo đảm Pod Kapas phân giải và kết nối được tới máy chủ đó.
3. Thêm provider OpenAI-compatible với base URL nội bộ.
4. Kiểm tra bằng chức năng thử kết nối rồi đặt làm active model.

:::caution Giới hạn hiện tại

- Dùng mô hình cục bộ không tự bảo đảm không có lưu lượng ra ngoài. Để chạy hoàn toàn trong mạng nội bộ, cũng cần cấu hình nội bộ cho embedding, truy vết và mọi URL tích hợp.
- Kapas có cấu hình định tuyến giữa mô hình cục bộ và đám mây, nhưng tính năng này chưa được hỗ trợ chính thức trên luồng chat chính. Đừng dựa vào định tuyến tự động theo độ nhạy dữ liệu.
- Hanas không kèm máy chủ mô hình trong gói triển khai; bạn tự cung cấp.

:::

## Khuyến nghị

- Chọn model hỗ trợ tool calling ổn định; agent dữ liệu gọi nhiều tool liên tiếp.
- Với dữ liệu nhạy cảm, ưu tiên mô hình on-prem hoặc provider đã được pháp chế phê duyệt.
- Đặt ngân sách token và giới hạn request phù hợp số người dùng; các giới hạn này là giới hạn mềm theo tiến trình.
- Ghi lại model đang dùng khi báo cáo số liệu, vì cùng một câu hỏi có thể cho kết quả khác giữa các model.
- Kiểm thử các câu hỏi nghiệp vụ quan trọng sau mỗi lần đổi model.

## Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Kiểm tra kết nối thất bại | Pod không tới được base URL | Dùng địa chỉ phân giải được từ Pod, kiểm tra NetworkPolicy. |
| Danh sách model rỗng | Endpoint không hỗ trợ liệt kê model | Nhập tên model thủ công. |
| Agent không gọi tool | Model không hỗ trợ tool calling | Đổi sang model hỗ trợ. |
| Đổi biến môi trường nhưng không có tác dụng | Active model đã được lưu | Đổi trong **Models**; biến chỉ dùng khi chưa có active model. |

## Tiếp theo

- [Tham chiếu cấu hình](configuration.md)
- [Xác thực và SSO với Keycloak](identity.md)
- [An toàn trong Kapas](../kapas/safety.md)
