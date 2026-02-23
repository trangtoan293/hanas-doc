# Raw Vault

## Tổng Quan

Raw Vault là lớp nền tảng, nơi dữ liệu từ các nguồn được chuyển đổi vào mô hình chuẩn Data Vault. Không áp logic nghiệp vụ — chỉ chuẩn hóa cấu trúc.

## Hub — Khóa Nghiệp Vụ

- Lưu trữ khóa nhận diện duy nhất (business key)
- Ổn định lâu dài, không chứa thuộc tính mô tả
- Không bị thay đổi khi nguồn thay đổi

## Link — Quan Hệ Nghiệp Vụ

- Mô tả quan hệ giữa các Hub
- Không có thuộc tính mô tả
- Không bị ảnh hưởng bởi thay đổi thuộc tính

## Satellite — Thuộc Tính & Lịch Sử

- Lưu thuộc tính mô tả (nội dung thực thể/quan hệ)
- Append-only: đầy đủ lịch sử thay đổi
- Tách theo nhóm thuộc tính hoặc nguồn
- Phù hợp với Iceberg/Parquet

## Đặc Trưng Kỹ Thuật

- Không áp logic nghiệp vụ, chỉ chuẩn hóa cấu trúc
- Dữ liệu nguyên gốc nhưng có tổ chức → ổn định
- Tối ưu cho xử lý phân tán (Spark)
- Đảm bảo truy vết toàn trình (source → vault → downstream)
