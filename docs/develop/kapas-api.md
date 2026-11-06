---
title: Kapas API và SSE
sidebar_label: Kapas API
sidebar_position: 5
description: Xác thực, các endpoint chính của Kapas và hợp đồng sự kiện SSE (contract v1) để tích hợp chat Kapas vào ứng dụng của bạn.
---

Trang này dành cho nhà phát triển tích hợp Kapas qua HTTP. Bạn sẽ biết cách xác thực, tạo agent cho một ngữ cảnh, gửi tin nhắn và đọc luồng sự kiện SSE.

## Khái niệm

- **agent_id**: định danh agent của người dùng đang gọi. Bạn nhận từ API, không tự đặt.
- **session_id**: phiên hội thoại. Với template có binding, Kapas tạo từ ngữ cảnh ứng dụng bạn gửi trong `meta.app`.
- **meta.app**: ngữ cảnh ứng dụng (ví dụ project hiện tại). Đây không phải quyền truy cập; ứng dụng của bạn và dịch vụ đích vẫn phải kiểm tra quyền.
- Mọi đường dẫn nằm dưới tiền tố `/api` của máy chủ Kapas. Truy cập qua gateway tại tên miền Kapas, xem [API gateway và tên miền](../operate/gateway.md).

## Xác thực

Mọi request gửi `Authorization: Bearer <token>`. Kapas chấp nhận:

| Loại | Dùng cho |
|---|---|
| JWT Keycloak của người dùng | Tích hợp chuẩn, giữ danh tính người dùng cuối. |
| API key (tiền tố `qpaw_`) | Tích hợp dịch vụ. Key thuộc một tài khoản dịch vụ do admin tạo và không đóng vai người dùng cụ thể. |

Backend của ứng dụng host xác thực người dùng trước rồi mới gọi Kapas; không để trình duyệt giữ khóa dịch vụ. Về PAT và các cách xác thực khác của nền tảng, xem [Tổng quan tích hợp](index.md).

:::caution Giới hạn hiện tại

Kapas không tự chuyển token query engine cho request nhúng. Gửi token của người dùng cuối trong `meta.user_token` để các tool phía sau chạy bằng quyền của người đó, và giữ nó nhất quán với Bearer. Xem [An toàn trong Kapas](../kapas/safety.md).

:::

## Endpoint chính

| Mục đích | Phương thức và đường dẫn |
|---|---|
| Liệt kê template agent | `GET /api/agents/templates` |
| Tạo agent theo ngữ cảnh (idempotent) | `POST /api/agents/ensure` |
| Tính ID, không tạo gì | `POST /api/agents/resolve` |
| Chat có streaming (SSE) | `POST /api/agents/{agentId}/embed/chat` |
| Dừng lượt chat | `POST /api/agents/{agentId}/embed/chat/stop?chat_id=...` |
| Lịch sử phiên | `GET /api/agents/{agentId}/embed/sessions/{sessionId}/messages` |
| Mức thực thi của phiên | `GET`/`PUT /api/agents/{agentId}/embed/session/{sessionId}/execution-level` |
| Duyệt hoặc từ chối tool | `POST /api/approval/approve`, `POST /api/approval/deny`, `GET /api/approval/pending` |
| Gọi đồng bộ, trả JSON | `POST /api/agent/sync` |
| Kiểm tra sống | `GET /api/healthz` |

Tài liệu OpenAPI (`/docs`) thường bị tắt trong production; điều đó không có nghĩa API không tồn tại. Endpoint `healthz` chỉ phản ánh Kapas đã khởi động, không xác nhận query engine hay Superset đang chạy.

### Tạo agent

```bash
curl -s -X POST "https://<kapas-host>/api/agents/ensure" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "project-copilot",
    "meta": {"app": {"project_id": "project-123"}}
  }'
```

```json
{
  "agent_id": "project-copilot",
  "session_id": "project-project-123",
  "chat_id": null,
  "agent_created": true,
  "session_created": true
}
```

`ensure` chỉ tạo agent. Chat được tạo ở tin nhắn đầu tiên nên `chat_id` có thể là `null`. Dùng đúng `agent_id` và `session_id` được trả về, không tự ghép.

### Gửi tin nhắn

```bash
curl -N -X POST "https://<kapas-host>/api/agents/project-copilot/embed/chat" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Giải thích model đang mở",
    "session_id": "<session_id-từ-ensure>",
    "stream": true,
    "meta": {
      "user_token": "<end-user-token>",
      "app": {"project_id": "project-123"}
    }
  }'
```

Template có thể quy định tham số `meta.app` bắt buộc, ví dụ Project Copilot cần `project_id`. Template nào cũng nhận `meta.app` đã kiểm tra kiểu và ký tự.

:::note Điều kiện

Kênh nhúng chỉ có ở các agent khai báo kênh `embed`: tất cả agent hệ thống trừ Hanas Analyst. Hanas Analyst chỉ dùng trong Kapas Console.

:::

## Hợp đồng SSE v1

Mỗi dòng sự kiện có dạng `data: <json>` và kết thúc bằng một dòng trống. JSON là một envelope:

```json
{
  "contract_version": 1,
  "type": "token",
  "seq": 0,
  "session_id": "<session_id>",
  "data": {"text": "Đoạn văn bản"}
}
```

`seq` tăng dần từ 0, không bỏ số trong một luồng. Dùng nó để phát hiện mất sự kiện và loại trùng. Client phải bỏ qua `type` và trường chưa biết.

| `type` | `data` | Ý nghĩa |
|---|---|---|
| `token` | `{text}` | Đoạn văn bản tăng dần; nối theo thứ tự để hiển thị câu trả lời. |
| `tool_call` | `{call_id, tool, args}` | Agent sắp chạy một tool. |
| `tool_result` | `{call_id, ok, detail}` | Tool xong. `ok: false` là tool lỗi nhưng agent vẫn tiếp tục. |
| `effect` | `{name, value}` | Tác động đã khai báo, ví dụ yêu cầu ứng dụng làm mới danh sách file. |
| `approval_request` | `{request_id, tool, severity, params, timeout_seconds, ...}` | Luồng tạm dừng chờ duyệt. |
| `ping` | `{}` | Giữ kết nối; bỏ qua. |
| `error` | `{code, message}` | Lỗi mức luồng, kết thúc; luôn kèm `done`. |
| `done` | `{status, usage}` | Kết thúc, luôn là sự kiện cuối. |

Trạng thái `done.status`: `completed`, `error`, `cancelled`, `incomplete`. Hai giá trị cuối cũng do SDK TypeScript tự tạo khi bạn hủy luồng hoặc kết nối đứt.

Ví dụ một lượt có gọi tool:

```text
data: {"contract_version":1,"type":"tool_call","seq":0,"session_id":"s1","data":{"call_id":"c1","tool":"list_boards","args":{}}}

data: {"contract_version":1,"type":"tool_result","seq":1,"session_id":"s1","data":{"call_id":"c1","ok":true,"detail":{}}}

data: {"contract_version":1,"type":"token","seq":2,"session_id":"s1","data":{"text":"Project có 2 board."}}

data: {"contract_version":1,"type":"done","seq":3,"session_id":"s1","data":{"status":"completed","usage":{"total_tokens":0}}}
```

Thứ tự: `tool_call` đứng trước `tool_result` cùng `call_id`; `effect` (nếu có) đứng sau `tool_result`. Chỉ có một `done` cuối mỗi luồng.

### Phê duyệt tool

Khi nhận `approval_request`, luồng chờ cho tới khi bạn gọi duyệt hoặc từ chối:

```bash
curl -X POST "https://<kapas-host>/api/approval/approve" \
  -H "Authorization: Bearer <end-user-token>" \
  -H "Content-Type: application/json" \
  -d '{"request_id": "<request_id>", "session_id": "<session_id>"}'
```

Dùng `/api/approval/deny` với thêm `reason` (tùy chọn) để từ chối. Hiển thị yêu cầu duyệt cho người dùng thật; đừng tự động duyệt.

### Lịch sử

Lịch sử khác luồng trực tiếp: mỗi tin nhắn có `role` là `user`, `assistant` hoặc `tool`. Đọc lại khi người dùng mở phiên.

## Lưu ý khi triển khai client

:::caution Giới hạn hiện tại

- `tool_result.ok` có thể là `true` ngay cả khi tool nhúng trả lỗi trong nội dung. Với thao tác ghi, kiểm tra `detail` thay vì chỉ dựa vào cờ này.
- Kapas không tự kết nối lại. Client phải tự kết nối lại và loại trùng bằng `seq` khi luồng đứt, rồi đọc lịch sử để lấy phần còn thiếu.
- Thông điệp `error.message` nhằm an toàn cho người dùng, nhưng có thể chứa nội dung lỗi từ nhà cung cấp mô hình; đừng hiển thị nguyên văn nếu không muốn lộ chi tiết.
- API key đại diện tài khoản dịch vụ. Không dùng chung cho chat của nhiều người dùng.

:::

## Xử lý sự cố

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| `401` | Token hết hạn hoặc sai audience | Lấy token mới từ Keycloak. |
| `ensure` lỗi thiếu tham số | Template cần `meta.app` bắt buộc | Gửi đủ `meta.app` theo template. |
| Luồng đứng, nhận `ping` | Đang chờ `approval_request` | Gọi duyệt hoặc từ chối. |
| Tool báo thiếu token | Không gửi `meta.user_token` | Gửi token người dùng cuối. |
| Luồng bị cắt giữa chừng | Gateway hoặc proxy giới hạn timeout hay buffering | Tắt buffering SSE và tăng timeout, xem [API gateway](../operate/gateway.md). |

## Tiếp theo

- [Nhúng Kapas vào ứng dụng](kapas-embed.md)
- [An toàn trong Kapas](../kapas/safety.md)
- [Tổng quan tích hợp](index.md)
