# Từ Điển Thuật Ngữ

## Kiến Trúc & Hạ Tầng

| Thuật ngữ | Giải thích |
|---|---|
| **Data Lakehouse** | Kiến trúc hợp nhất Data Lake + Data Warehouse |
| **Data Lake** | Kho lưu trữ dữ liệu thô, đa định dạng |
| **Data Warehouse** | Kho dữ liệu có cấu trúc phục vụ phân tích |
| **Object Storage** | Lưu trữ dữ liệu dạng đối tượng (MinIO/S3) |
| **Kubernetes (K8s)** | Nền tảng container orchestration |
| **DC-DR** | Data Center - Disaster Recovery |

## Xử Lý Dữ Liệu

| Thuật ngữ | Giải thích |
|---|---|
| **ETL** | Extract - Transform - Load |
| **ELT** | Extract - Load - Transform |
| **DAG** | Directed Acyclic Graph - đồ thị có hướng không chu trình |
| **Pipeline** | Chuỗi xử lý dữ liệu tự động |
| **Batch Processing** | Xử lý dữ liệu theo lô, định kỳ |
| **Stream Processing** | Xử lý dữ liệu liên tục, thời gian thực |

## Mô Hình Dữ Liệu (Data Vault 2.0)

| Thuật ngữ | Giải thích |
|---|---|
| **Hub** | Bảng lưu khóa nghiệp vụ duy nhất |
| **Link** | Bảng mô tả quan hệ giữa các Hub |
| **Satellite** | Bảng lưu thuộc tính mô tả và lịch sử |
| **Raw Vault** | Lớp lưu trữ dữ liệu gốc đã chuẩn hóa |
| **Business Vault** | Lớp xử lý logic nghiệp vụ nâng cao |
| **Information Mart** | Lớp dữ liệu phục vụ báo cáo cuối cùng |
| **PIT** | Point-In-Time table |
| **Bridge** | Bảng cầu nối gom dữ liệu từ nhiều Satellite |

## Quản Trị Dữ Liệu

| Thuật ngữ | Giải thích |
|---|---|
| **Metadata** | Dữ liệu mô tả dữ liệu (kỹ thuật & nghiệp vụ) |
| **Data Catalog** | Danh mục dữ liệu tập trung |
| **Data Lineage** | Truy vết luồng dữ liệu từ nguồn đến đích |
| **Business Glossary** | Từ điển thuật ngữ nghiệp vụ |
| **Data Quality** | Chất lượng dữ liệu |
| **Data Steward** | Người quản lý nghiệp vụ dữ liệu |
| **Data Owner** | Chủ sở hữu dữ liệu |

## Truy Vấn & Khai Thác

| Thuật ngữ | Giải thích |
|---|---|
| **Semantic Layer** | Lớp ngữ nghĩa chuẩn hóa logic nghiệp vụ |
| **Virtual Dataset** | Bảng logic không tạo bản sao vật lý |
| **Query Optimizer** | Bộ tối ưu hóa truy vấn |
| **Predicate Pushdown** | Đẩy điều kiện lọc xuống gần nơi lưu trữ |
| **JDBC/ODBC** | Chuẩn kết nối cơ sở dữ liệu |

## Bảo Mật

| Thuật ngữ | Giải thích |
|---|---|
| **RBAC** | Role-Based Access Control |
| **ATTT** | An Toàn Thông Tin |
| **TLS** | Transport Layer Security - mã hóa đường truyền |
| **SASL** | Simple Authentication and Security Layer |

## AI Service

| Thuật ngữ | Giải thích |
|---|---|
| **LLM** | Large Language Model — mô hình ngôn ngữ lớn (e.g. Qwen3, GPT) |
| **Inference** | Quá trình chạy model để sinh kết quả từ input |
| **RAG** | Retrieval-Augmented Generation — kết hợp truy vấn tài liệu + LLM |
| **Embedding** | Biểu diễn văn bản thành vector số học để tìm kiếm ngữ nghĩa |
| **Reranking** | Sắp xếp lại kết quả tìm kiếm theo mức độ liên quan |
| **Chatflow** | Luồng hội thoại AI dạng đồ thị (graph-based) |
| **Agent** | AI có khả năng sử dụng tools và thực hiện actions |
| **Tool Calling** | LLM gọi hàm/API bên ngoài để thực hiện tác vụ |
| **Knowledge Base** | Kho tài liệu được index cho RAG retrieval |
| **Prompt** | Đoạn text hướng dẫn LLM cách xử lý và trả lời |
| **Token** | Đơn vị nhỏ nhất của text mà LLM xử lý |
| **Quantization** | Kỹ thuật nén model (AWQ, GPTQ) để giảm VRAM |
| **VRAM** | Video RAM — bộ nhớ GPU dùng cho inference |
| **Trace** | Bản ghi chi tiết một lần gọi AI (input/output/latency/cost) |
| **Observability** | Khả năng giám sát và phân tích hệ thống AI |

