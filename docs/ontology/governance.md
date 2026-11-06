---
title: Quản trị ontology
sidebar_label: Quản trị
sidebar_position: 7
description: Quy trình draft, review, publish, deployment, release gate, audit, role và import/export ontology.
---

Trang này mô tả cách kiểm soát thay đổi ontology: ai được làm gì, thay đổi đi qua những cổng nào trước khi đến người dùng, và cách xuất hoặc nhập định nghĩa giữa các workspace. Đối tượng đọc là admin ontology và người phê duyệt. Trong Hanas Console, các thao tác này nằm ở menu **Ontology** > **Governance**.

## Role

| Role | Quyền |
|---|---|
| `ontology-viewer` | Đọc catalog, record và truy vấn; quản lý object set của mình. |
| `ontology-editor` | Như viewer, cộng soạn concept, relationship, mapping, trình bày, metric; validate và gửi draft. |
| `ontology-admin` | Như editor, cộng publish, rollback, deployment, quản lý workspace, template và cấu hình AI. |
| `ontology-action-worker` | Tài khoản máy xử lý action request; admin cũng có quyền này. |

Role đến từ danh tính của người dùng; xem [Quản lý người dùng, group và role](../operate/user-management.md). Tenant được xác định từ token, không từ nội dung request.

:::caution Giới hạn hiện tại

Workspace là phạm vi dự án, nhưng chưa có danh sách thành viên riêng cho từng workspace. Quyền truy cập dựa trên role và tenant. Cờ `hidden` và business group không phải cơ chế phân quyền; hãy dùng grant, row access và masking tại query engine, xem [Phân quyền dữ liệu](../govern/access-control.md).

:::

## Draft, review, publish

1. **Draft**: editor soạn bản canonical và manifest. Draft không thay đổi runtime đang phục vụ.
2. **Review**: editor xem tác động và gửi draft sang `pending_approval`. Draft bị khóa sửa. Người gửi hoặc admin có thể rút lại; admin có thể từ chối kèm lý do.
3. **Publish**: admin kiểm tra checksum và compile bản xem trước, phê duyệt revision rồi tạo và kích hoạt deployment.

Admin có thể publish trực tiếp một draft hợp lệ, nên submit không bắt buộc với admin.

## Revision và deployment

Revision, revision đã phê duyệt, deployment và runtime đang phục vụ là các đối tượng khác nhau. Một bản đã lưu chưa chắc đang phục vụ.

| Bước deployment | Ý nghĩa |
|---|---|
| Prepare | Chuẩn bị projection từ revision đã phê duyệt. |
| Health check | Kiểm tra trạng thái deployment. |
| Preview activate | Xem tác động của việc đổi runtime. |
| Activate | Kích hoạt với kiểm tra generation để tránh ghi đè do xung đột. |

Cache kết quả được làm mới khi runtime đổi. **Rollback** tạo draft từ một revision cũ rồi đi qua cùng cổng phát hành; cần xác nhận khi thao tác phá hủy tài nguyên phụ thuộc.

## Governance gate

Trước khi phát hành, hệ thống chạy các kiểm tra sau.

- Phân quyền: editor không thể tự đổi trạng thái phục vụ, quy tắc writeback hoặc action, interface thuộc phạm vi admin. Hệ thống so sánh phần privileged của manifest trước và sau.
- Checksum: nội dung đổi sau preview phải được xem lại.
- Compile và schema nguồn: dataset, cột và kiểu phải còn hợp lệ.
- Mapping: entity cần runtime phải có dataset và primary key.
- Agent: không có run AI đang hoạt động.
- Tác động: xem xét tài nguyên phụ thuộc trước thay đổi phá vỡ.

Gate này dựa trên role và kiểm tra phát hành. Nó không tự đồng bộ phân loại dữ liệu từ hệ thống quản trị ngoài để cấp quyền runtime.

## Audit

Audit log ghi tenant, người thực hiện, hành động, tài nguyên và chi tiết. Các thao tác quan trọng như gửi, từ chối, import, publish, kích hoạt và action request đều được ghi. Admin đọc audit log qua giao diện hoặc API.

Audit log lưu thay đổi của ontology, không lưu bản sao dữ liệu nghiệp vụ, vốn vẫn nằm ở query engine.

## Import và export

Bạn có thể xuất định nghĩa thành gói ZIP và nhập vào workspace khác. Có ba loại gói.

| Gói | Nội dung |
|---|---|
| `ossie` | Concept và relationship canonical, không có mapping. |
| `mapping` | Mapping và manifest, kèm tham chiếu tới ontology đã dùng. |
| `bundle` | Cả ontology và mapping. |

Export ưu tiên revision đã phê duyệt, rồi revision đang phục vụ, rồi draft. Gói không chứa record, phê duyệt action, trạng thái deployment hay thông tin xác thực; hệ thống quét và chặn các key giống secret, nhưng đây là kiểm tra theo tên key, không phải bảo đảm chống rò rỉ cho mọi chuỗi mô tả.

Quy trình import theo giai đoạn:

1. Tải gói lên một import session; chưa có gì thay đổi ở runtime.
2. Hệ thống đối chiếu tài nguyên theo identity canonical, không theo nhãn hiển thị.
3. Với mỗi tài nguyên, chọn `CREATE_NEW`, `MATCH_EXISTING` hoặc `SKIP`; có thể áp quyết định hàng loạt.
4. Xử lý blocker, rồi áp import vào draft. Thao tác ghi atomically vào draft.
5. Validate, review và publish theo quy trình thông thường.

Bạn cũng có thể import trực tiếp tài liệu YAML hoặc JSON canonical thành draft. Tệp phải là UTF-8, tối đa 5 MiB. Gói ZIP tối đa 20 MiB nén và 50 MiB sau giải nén.

:::caution Giới hạn hiện tại

Import và export dạng Excel chưa được hỗ trợ. Chỉ có YAML, JSON và gói ZIP.

:::

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Không publish được | Đọc issue trong release preview; kết thúc agent run đang hoạt động. |
| Checksum không khớp | Tải lại draft và xem lại preview. |
| Import bị chặn | Giải quyết các quyết định còn `UNRESOLVED` hoặc conflict. |
| Rollback bị yêu cầu xác nhận | Xem tài nguyên phụ thuộc bị ảnh hưởng. |

## Tiếp theo

- [Ontology Workspace](workspace.md) cho luồng authoring.
- [Mẫu ontology ngành ngân hàng](industry-templates.md).
- [Ontology API](../develop/ontology-api.md) cho deployment và portability.
