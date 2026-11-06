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

Docker (image chỉ chứa site đã build, nên chạy `npm run build` trước):

```bash
npm run build
docker build -t hanas-docs .
docker run -p 8080:80 hanas-docs
```

## CI/CD

`.gitlab-ci.yml` build site trên mọi nhánh và MR. Trên `main` và tag được bảo vệ, CI đóng image nginx và push lên Harbor `192.168.1.41/k8s-image/hanas-docs` với tag `<commit-sha>` và `<YYYYMMDD>-<short-sha>`; nhánh khác chạy bước này bằng tay. Nếu có biến `DOCKERHUB_TOKEN`, image cũng được push lên `katalysthub/hanas-docs`. Pipeline chưa có bước deploy.

## Cấu trúc

```
docs/                                              bản tiếng Việt (nguồn chính)
i18n/en/docusaurus-plugin-content-docs/current/    bản tiếng Anh, cùng đường dẫn file với docs/
i18n/en/*.json                                     nhãn navbar, footer, sidebar tiếng Anh
sidebars.ts                                        4 sidebar: product, operate, develop, reference
```

Mỗi mục là một thư mục; `index.md` là trang giới thiệu mục, các trang con sắp theo `sidebar_position`.

## Sơ đồ

Sơ đồ kiến trúc được sinh bằng archify (skill nội bộ) từ file JSON trong `diagrams/vi/` và `diagrams/en/`. Kết quả gồm HTML tương tác ở `static/diagrams/<locale>/` và ảnh xem trước sáng/tối ở `static/img/diagrams/<locale>/`; trang docs nhúng bằng component `<Diagram name="..." alt="..." />`. Khi sửa sơ đồ: sửa JSON, chạy `archify deliver <type> <file.json> <out.html> --quality showcase`, rồi `archify visual-check <out.html>` và chuyển ảnh `*.2048x1320.{light,dark}.png` sang WebP.

## Quy ước viết

Xem [.claude/agents/hanas-doc-writer.md](.claude/agents/hanas-doc-writer.md): quy tắc tên gọi (không dùng tên sản phẩm upstream, chỉ gọi "query engine", "Kapas", "Hanas Catalog"), văn phong, nhãn mức hoàn thiện tính năng (`Điều kiện`, `Giới hạn hiện tại`, `Preview`) và cấu trúc trang.

Khi sửa một trang tiếng Việt, cập nhật trang tương ứng trong `i18n/en/...` trong cùng thay đổi.
