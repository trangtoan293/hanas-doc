{{ config(
    materialized = 'table',
    file_format='iceberg'
) }}

SELECT
    CAST(1 AS INT) AS PL_ID,
    CAST('7.1' AS string) AS PL_CODE,
    CAST('Thu nhập lãi thuần' AS string) AS PL_NAME,
    CAST(7 AS INT) AS PL_MAIN_CODE,
    CAST('Thu nhập thuần' AS string) AS PL_MAIN_NAME
UNION ALL
SELECT 2, '7.2', 'Thu nhập thuần dịch vụ', 7, 'Thu nhập thuần'
UNION ALL
SELECT 3, '7.3', 'Thu nhập thuần KDNT', 7, 'Thu nhập thuần'
UNION ALL
SELECT 4, '7.4', 'Thu nhập thuần chứng khoán', 7, 'Thu nhập thuần'
UNION ALL
SELECT 5, '7.5', 'Thu nhập thuần khác', 7, 'Thu nhập thuần'
UNION ALL
SELECT 6, '7.6', 'Thu nhập thuần góp vốn, mua cổ phần', 7, 'Thu nhập thuần'
UNION ALL
SELECT 7, '8.1', 'Chi nhân sự', 8, 'Chi phí hoạt động quản lý'
UNION ALL
SELECT 8, '8.2', 'Chi hỗ trợ phát triển KD', 8, 'Chi phí hoạt động quản lý'
UNION ALL
SELECT 9, '8.3', 'Chi ngoài nhân sự', 8, 'Chi phí hoạt động quản lý'
UNION ALL
SELECT 10, '8.4', 'Chi Bảo hiểm tiền gửi', 8, 'Chi phí hoạt động quản lý'
UNION ALL
SELECT 11, '9.1', 'Chi phí dự phòng', 9, 'Chi phí dự phòng'
UNION ALL
SELECT 12, '10.1', 'Lợi nhuận trước thuế', 10, 'Lợi nhuận trước thuế'