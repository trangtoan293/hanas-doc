# Hanas Docs

Tài liệu chính thức của **Hanas Data Platform**, xây dựng bằng Docusaurus 3, song ngữ Việt (mặc định) và Anh.

## Chạy local

Cần Node.js ≥ 20.

```bash
npm install
npm start          # tiếng Việt, http://localhost:3000
npm run start:en   # tiếng Anh
npm run build      # build cả hai ngôn ngữ vào build/ (link hỏng sẽ làm build lỗi)
```

Docker:

```bash
docker build -t hanas-docs .
docker run -p 8080:80 hanas-docs
```

## Cấu trúc

```
docs/                                              bản tiếng Việt (nguồn chính)
i18n/en/docusaurus-plugin-content-docs/current/    bản tiếng Anh, cùng đường dẫn file với docs/
i18n/en/*.json                                     nhãn navbar, footer, sidebar tiếng Anh
sidebars.ts                                        4 sidebar: product, operate, develop, reference
```

Mỗi mục là một thư mục; `index.md` là trang giới thiệu mục, các trang con sắp theo `sidebar_position`.

## Quy ước viết

Xem [.claude/agents/hanas-doc-writer.md](.claude/agents/hanas-doc-writer.md): quy tắc tên gọi (không dùng tên sản phẩm upstream, chỉ gọi "query engine", "Kapas", "Hanas Catalog"), văn phong, nhãn mức hoàn thiện tính năng (`Điều kiện`, `Giới hạn hiện tại`, `Preview`) và cấu trúc trang.

Khi sửa một trang tiếng Việt, cập nhật trang tương ứng trong `i18n/en/...` trong cùng thay đổi.
