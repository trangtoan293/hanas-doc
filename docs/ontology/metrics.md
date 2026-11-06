---
title: Metric
sidebar_label: Metric
sidebar_position: 4
description: Định nghĩa metric simple, ratio và derived, hiểu additivity, time semantics và nơi metric hiển thị trong Explore.
---

Metric là chỉ số nghiệp vụ có tên, mô tả, đơn vị và cấu hình thực thi, ví dụ tổng dư nợ hay tỷ lệ nợ xấu. Trang này dành cho tác giả ontology cần định nghĩa chỉ số chuẩn và cho người dùng muốn hiểu số liệu hiển thị.

Metric là bước tùy chọn trong [Ontology Workspace](workspace.md). Object type vẫn phát hành được khi chưa có metric.

## Các loại metric

| Loại | Cấu trúc | Ví dụ |
|---|---|---|
| `simple` | Một `formula` aggregate trên nguồn, không có tham chiếu. | Tổng số dư của các tài khoản tiền gửi. |
| `ratio` | Tử số và mẫu số, mỗi bên tham chiếu một metric của một object type. | Dư nợ nhóm 3 trở lên chia tổng dư nợ. |
| `derived` | Biểu thức số học trên các input là metric khác. | Chênh lệch giữa thu nhập lãi và chi phí lãi. |

Biểu thức `derived` chỉ cho phép số, tên input và các phép `+ - * /` kèm dấu đơn ngôi. Lời gọi hàm, truy cập thuộc tính hoặc tên ngoài danh sách input bị từ chối.

Ratio phải tính từ các thành phần cùng scope hợp lệ. Hệ thống không cộng các tỷ lệ của từng record để ra tỷ lệ tổng.

## Additivity

Additivity cho biết có thể cộng metric theo một chiều phân nhóm hay không.

| Giá trị | Ý nghĩa |
|---|---|
| `additive` | Cộng được theo các chiều nghiệp vụ, ví dụ tổng số dư theo chi nhánh. |
| `semi_additive` | Cộng được theo chiều nghiệp vụ nhưng không cộng theo thời gian; lấy giá trị cuối kỳ, đầu kỳ hoặc trung bình. |
| `non_additive` | Không cộng được, ví dụ trung bình, đếm duy nhất và tỷ lệ. |

Khi compile, hệ thống suy ra additivity từ kế hoạch thực thi và time policy thay vì tin vào khai báo thủ công. Count, sum, min, max thường và aggregate có điều kiện được xếp là additive theo chiều nghiệp vụ. Average, distinct count, phép tính số học, ratio và so sánh kỳ được xếp là non-additive. Nếu time policy chốt một mốc thời gian, nhóm additive trở thành semi-additive với cách gộp thời gian là `last`.

Đừng cộng các cửa sổ chồng lấn như MTD và YTD, và đừng coi min hoặc max là phép cộng.

## Time semantics

Metric có cấu hình thời gian riêng, ngoài date policy của object type.

| `as_of_policy` | Cách chọn dữ liệu |
|---|---|
| `latest` | Snapshot mới nhất. |
| `selected_date` | Snapshot của ngày người dùng chọn; cần có ngày. |
| `period_end` | Snapshot không sau ngày yêu cầu, hoặc mới nhất nếu không chọn ngày. |
| `wtd`, `mtd`, `qtd`, `ytd`, `itd` | Khoảng từ đầu tuần, tháng, quý, năm hoặc từ đầu đến ngày chọn. |

Khi không có ngày, các policy tích lũy không tự thêm khoảng lọc. Metric cũng có thể cấu hình so sánh `growth_rate` với `previous_snapshot` và `partition_by`.

## Cấu hình thực thi

Execution của metric gồm các lựa chọn sau.

1. Chọn dataset nguồn và relationship path nếu metric đi qua nhiều object type.
2. Chọn chế độ `direct` hoặc `aggregate_then_join`.
3. Khai báo trường được phép kế thừa filter từ ngữ cảnh. Metric không tự nhận mọi filter của danh sách.
4. Chọn time dimension và `as_of_policy`.

## Các bước tạo metric

1. Mở **Open Build** của project (hoặc **Ontology** > **Workbench**), rồi mở **Metrics**.
2. Nhập tên, mô tả, đơn vị và công thức hoặc tham chiếu.
3. Cấu hình execution, context và placement.
4. Chọn **Validate**, sau đó xem **compile preview**.
5. Lưu vào draft và đi tiếp tới **Release**.

## Trạng thái và nơi hiển thị

Metric không biên dịch được thành kế hoạch thực thi có trạng thái `catalog_only`: nó xuất hiện trong catalog nhưng không tính ra giá trị. Chỉ metric `executable` mới tính được.

**Placement** quyết định metric xuất hiện ở đâu: danh sách record hoặc trang chi tiết record, component, thứ tự, hiển thị, định dạng, phạm vi filter và ngữ cảnh ngày. Người dùng thấy metric trong [Khám phá đối tượng](explore.md). Ứng dụng tích hợp gọi aggregate metric hoặc metric của một record qua [Ontology API](../develop/ontology-api.md), hoặc dùng metric đã đặt tên trong [Query DSL](../develop/ontology-query-dsl.md).

## Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Metric có trong catalog nhưng không có giá trị | Kiểm tra trạng thái `catalog_only`; sửa lỗi trong compile preview. |
| Tổng theo thời gian sai | Kiểm tra additivity suy ra và `as_of_policy`; không cộng snapshot nhiều ngày. |
| Filter của danh sách không ảnh hưởng metric | Khai báo trường được kế thừa filter trong context. |
| Ratio ra giá trị lạ | Kiểm tra tử số và mẫu số có cùng scope và cùng ngày. |

## Tiếp theo

- [Ánh xạ dữ liệu](mapping.md) cho dataset và khóa.
- [Khám phá đối tượng](explore.md) để xem metric trên record.
- [Quản trị ontology](governance.md) để phát hành.
