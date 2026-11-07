# Hướng dẫn copywriting cho landing page Hanas Data Platform

Áp dụng cho trang chủ marketing và các trang giới thiệu sản phẩm. Docs kỹ thuật theo `.claude/agents/hanas-doc-writer.md`.

Nguồn tham khảo (đọc ngày 06/11/2026): databricks.com (trang chủ, Data Intelligence Platform, Artificial Intelligence) và snowflake.com (trang chủ, The Snowflake Platform, Cortex AI). Ta học cấu trúc và nhịp câu của họ. Ta không chép câu chữ, và không chép các thủ pháp cần bằng chứng mà Hanas chưa có (logo khách hàng, số liệu, xếp hạng Gartner).

## 1. Hai đối thủ viết thế nào

| | Databricks | Snowflake | Hanas chọn |
|---|---|---|---|
| Hero | 4–8 từ, không chấm cuối, không có tên thương hiệu. Tên thương hiệu nằm ở eyebrow | Thường có tên thương hiệu trong H1 | Tên thương hiệu ở eyebrow, H1 nói lời hứa |
| Subhead | 1 câu, 8–15 từ: sản phẩm là gì hoặc kết quả gì | 20–35 từ, liệt kê giá trị, nhắc lại "kiểm soát" | 1 câu, tối đa khoảng 30 từ |
| H2 | Eyebrow viết hoa + H2 4–9 từ, sentence case, mở bằng động từ hoặc dạng "Sản phẩm: lợi ích" | 3–8 từ, mở bằng động từ ("Reduce risk") | Eyebrow ngắn + H2 4–9 từ, sentence case |
| Card | 1 câu 10–16 từ, mở bằng động từ, dùng "you/your" | 1 câu 10–25 từ, mở bằng động từ | 1 câu, mở bằng động từ, có "bạn" hoặc "your" khi tự nhiên |
| Nối tính năng với lợi ích | "..., so you can ..." | "Turn X into Y" | "..., nên ..." / "..., so ..." |
| AI | Luôn gắn với "grounded in your data", "governed" | Luôn đi kèm "perimeter", "control" | AI luôn đi kèm quyền của người hỏi và Ontology |
| CTA | "Explore [sản phẩm]", "See demo", "Try for free" | "Start for free", "Watch a demo" | Động từ + tân ngữ: "Đặt lịch demo", "Book a demo" |
| Bằng chứng | "Over 60% of the Fortune 500...", "Company: con số + bối cảnh" | Số in đậm + cụm danh từ, case study kiểu tin tức | Chưa có. Thay bằng cơ chế cụ thể (xem mục 4) |
| Dấu câu | Em dash chỉ trong thân bài; headline không chấm; không dùng serial comma | Giống vậy; dấu chấm than gần như không có | Không dùng gạch ngang dài; headline không chấm; tiếng Anh không serial comma |

Điểm chung của cả hai: headline gần như không có từ cường điệu. Từ kiểu "supercharge" hay "seamlessly" chỉ xuất hiện ở các ô quảng cáo phụ. Phần khẳng định nằm ở cơ chế cụ thể (Postgres, Iceberg, role-based access), không nằm ở tính từ.

## 2. Khung cho từng khối trên trang

**Eyebrow.** 1–4 từ, viết hoa bằng CSS. Nêu chủ đề của section, không lặp lại H2. Riêng hero, eyebrow là tên nền tảng ("Hanas Data Platform") để tên thương hiệu luôn xuất hiện ở màn hình đầu.

**H1 (hero).** Một lời hứa cho người mua, không chấm cuối. Tiếng Anh: 6–10 từ. Tiếng Việt: 8–14 từ, vì tiếng Việt cần nhiều âm tiết hơn cho cùng ý.

**Subhead.** Một câu nói sản phẩm làm gì và người đọc được gì. Có thể kết bằng vế "kiểm soát" (quyền, hạ tầng của bạn).

**H2 của section.** 4–9 từ. Ưu tiên mở bằng động từ ("Kết nối, mô hình hoá và hỏi đáp...") hoặc dạng kết quả ("Một con số chung cho cả công ty"). Không chấm cuối, trừ khi H2 là hai câu ngắn đặt cạnh nhau.

**Mô tả card.** Một câu, tối đa khoảng 20 từ, mở bằng động từ. Mỗi card chỉ nói một ý. Muốn nối tính năng với lợi ích thì dùng "nên" / "so".

**Bullet.** 3–6 từ, không chấm cuối, mở bằng danh từ hoặc động từ nhưng thống nhất trong cùng một danh sách.

**CTA.** Động từ + tân ngữ, 2–3 từ. Mỗi trang có một CTA chính duy nhất.

**FAQ.** Câu hỏi viết đúng như khách sẽ hỏi. Câu trả lời mở bằng "Có." / "Không." / "Được." khi trả lời được như vậy, rồi một hoặc hai câu cơ chế.

## 3. Viết tiếng Việt cho tự nhiên

Đọc to lên. Câu nghe như một kỹ sư giải pháp đang nói với khách là đạt.

- Động từ đứng đầu: "Truy vấn ngay tại nguồn", thay vì "Việc truy vấn được thực hiện tại nguồn".
- Hạn chế "được" và "bởi", vì chúng làm câu nghe như dịch máy. Chỉ giữ "được" khi người đọc là người nhận ("quyền được kiểm tra theo từng người").
- Xưng "bạn" nhất quán. Không dùng "quý khách" hay "chúng tôi".
- Thuật ngữ sản phẩm giữ tiếng Anh: lakehouse, Ontology, AI agent, dashboard, pipeline, metric. Phần lợi ích viết bằng tiếng Việt.
- Tên section viết tiếng Việt ("Quản trị & bảo mật", không phải "Governance & Security"). Tên sản phẩm và tên công nghệ giữ nguyên.
- Cặp vế đối kiểu Việt ("Dữ liệu rải rác, báo cáo chậm") rất hợp cho headline. Không xếp ba vế chỉ để cho đủ nhịp.
- Số viết kiểu Việt: 41,2 tỷ; 184.920; 6,4%.
- Từ cấm: giải pháp toàn diện, hàng đầu, vượt trội, đột phá, mạnh mẽ, tối ưu hoá (dùng như tính từ), nâng tầm, chuyển đổi số (dùng như khẩu hiệu), dễ dàng, nhanh chóng, hiệu quả (khi không có số đi kèm).

## 4. Viết tiếng Anh cho tự nhiên

- Viết lại từ ý, không dịch câu tiếng Việt. Ví dụ "quyền đi theo người dùng" thành "permissions that follow the user".
- Dùng "you/your". Hanas tự nói về mình ở ngôi thứ ba ("Hanas reads..."). Không dùng "we/our".
- Mở câu bằng động từ: Query, Define, Build, Ask, Connect.
- Thuật ngữ ngành người mua đã quen: "query data where it lives", "grounded in your data", "plain language", "conversational analytics", "Customer 360", "self-service BI".
- Không dùng serial comma: "customers, accounts and transactions".
- Sentence case cho mọi heading.
- Từ cấm: seamless, empower, leverage, unlock, supercharge, revolutionize, cutting-edge, world-class, next-generation, best-in-class.
- Số viết kiểu Anh: VND 41.2B, 184,920, 6.4%.

## 4b. Xuống hàng và dấu câu

- Tiêu đề hai dòng (`titleLines`): mỗi dòng là một cụm trọn nghĩa. Dòng sau thường mở bằng giới từ ("trên", "về", "đến", "on", "about"). Không để dấu phẩy treo ở cuối dòng.
- Tiếng Việt không được ngắt giữa từ ghép. Trong tiêu đề, nối từ ghép bằng `\u00a0` (dữ\u00a0liệu, nền\u00a0tảng, khái\u00a0niệm). Không làm vậy trong meta title.
- Mobile giữ nguyên điểm ngắt dòng của desktop; cỡ H2 trên mobile đủ nhỏ để mỗi cụm nằm trên một dòng.
- Thân bài không nối hai mệnh đề độc lập bằng dấu phẩy. Tách thành hai câu, hoặc nối bằng "và", "nên", "mà".
- Một ý chỉ xuất hiện một lần trong cụm eyebrow, H2 và intro. Ví dụ không lặp "Bắt đầu" ở cả ba.
- Câu chữ khách hàng tự viết thì giữ nguyên, kể cả dấu câu và cách ngắt dòng.

## 5. Nội dung: được nói gì, không được nói gì

Hanas chưa có logo khách hàng, case study công khai, benchmark hay xếp hạng của bên thứ ba. Không bịa những thứ đó. Thay vào đó, bằng chứng là cơ chế có thể kiểm chứng trong docs:

- Mỗi truy vấn chạy dưới danh tính của người hỏi (token exchange qua Keycloak).
- Ontology có phiên bản, phải publish rồi mới dùng.
- Dữ liệu lưu bằng Apache Iceberg trên hạ tầng của khách hàng.
- Kapas dùng được model qua API hoặc model tự host qua endpoint OpenAI-compatible.

Mọi con số trong khung minh họa phải gắn nhãn "dữ liệu minh họa" / "sample data".

Không hứa những gì sales kit liệt kê là chưa có: lineage mức cột, streaming thời gian thực, chất lượng dữ liệu trong Catalog, thông báo email/Slack, Helm chart trọn bộ.

Thông điệp ưu tiên (theo hướng hiện tại): AI agent + Ontology trước, sau đó đến nền tảng dữ liệu và quản trị. AI luôn đi kèm vế kiểm soát (quyền của người hỏi, hạ tầng của bạn), giống cách Databricks và Snowflake ghép AI với governance.

## 6. SEO

- `<title>`: từ khoá chính + tên thương hiệu, khoảng 55–65 ký tự. Docusaurus tự thêm "| Hanas Data Platform".
- Meta description: 140–160 ký tự, có "nền tảng dữ liệu doanh nghiệp" / "enterprise data platform", "Ontology", "AI agent".
- Chỉ một H1. Từ khoá chính nằm trong H1 hoặc eyebrow ngay trên H1.
- FAQ được xuất JSON-LD `FAQPage`, nên câu hỏi phải là câu người dùng thật sự gõ.
- Link nội bộ dùng `<Link>` để tự đúng ngôn ngữ (`/docs/...` và `/en/docs/...`).

## 7. Checklist trước khi publish

- [ ] Headline không chấm cuối, không có từ cấm.
- [ ] Mỗi card một câu, mở bằng động từ.
- [ ] Không có gạch ngang dài (— hoặc –) trong văn bản.
- [ ] Không có con số nào ngoài khung minh họa.
- [ ] Bản tiếng Anh đọc như viết mới, không như bản dịch.
- [ ] Đọc to bản tiếng Việt: không còn chuỗi "được... bởi", không còn "của" lặp ba lần trong một câu.
- [ ] Đã kiểm tra cách xuống hàng của mọi H1/H2 ở 1440px và 390px, cả hai ngôn ngữ.
- [ ] Copy nằm trong `src/components/landingCopy.ts`, sửa cả `vi` và `en` cùng lúc.
