# Business Vault

## Tổng Quan

Business Vault là nơi áp dụng các quy tắc nghiệp vụ nâng cao mà Raw Vault không xử lý.

## Thành Phần

### Business Satellite
- Satellite mở rộng chứa logic nghiệp vụ đã tính toán

### Bridge Table
- Bảng cầu nối gom dữ liệu từ nhiều Hub/Link/Satellite
- Tối ưu truy vấn nhiều bảng

### PIT (Point-In-Time) Table
- Bảng thời điểm, snapshot theo thời gian
- Tối ưu truy vấn lấy trạng thái tại thời điểm cụ thể

## Vai Trò Kỹ Thuật

- Gom logic nghiệp vụ phức tạp (tính SLA, phân nhóm, phân loại)
- Chuẩn hóa dữ liệu cho Information Mart
- Tối ưu truy vấn nhiều bảng và snapshot theo thời gian
