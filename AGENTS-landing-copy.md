# AGENTS-landing-copy.md

Hướng dẫn cho AI Agent viết **nội dung landing page** về tính năng của Hanas Data
& AI Platform.

> File này nói về **chữ**, không nói về code. Việc dựng component, CSS, build —
> xem [AGENTS.md](./AGENTS.md).

---

## 1. Người đọc là ai

Người vào landing page này **không phải** kỹ sư dữ liệu đang tìm tài liệu API.
Họ là ba nhóm, đọc cùng một trang với ba câu hỏi khác nhau:

| Nhóm | Câu hỏi trong đầu họ | Thứ họ tìm |
|---|---|---|
| CIO / CDO / Giám đốc CNTT | "Cái này giải quyết vấn đề gì của tôi?" | Kết quả kinh doanh, rủi ro, lock-in |
| Data lead / Kiến trúc sư | "Kiến trúc thế nào, có thật không?" | Tên công nghệ, luồng dữ liệu, khả năng tích hợp |
| Trưởng bộ phận nghiệp vụ | "Đội tôi dùng được không?" | Bài toán cụ thể, ai dùng, dùng ra sao |

**Hệ quả bắt buộc:** mỗi khối nội dung phải trả lời được cho nhóm 1 **trước**,
rồi mới đưa chi tiết cho nhóm 2. Nhóm 2 sẽ tự đọc tài liệu; nhóm 1 thì không —
họ chỉ có landing page.

Đây là trang **thương mại**, không phải bài blog. Người đọc đang cân nhắc bỏ tiền
và uy tín cá nhân ra để chọn nền tảng. Họ nghi ngờ mặc định. Viết cho người nghi
ngờ, đừng viết cho người đã tin.

---

## 2. Sáu nguyên tắc viết

### 2.1 Kết quả trước, cơ chế sau

Câu đầu tiên nói **doanh nghiệp được gì**. Câu thứ hai mới nói **làm bằng cách nào**.

```
❌ Hanas tích hợp Apache Iceberg table format với REST catalog Polaris,
   hỗ trợ ACID transaction và time travel trên object storage MinIO.

✅ Dữ liệu nằm ở định dạng mở và thuộc về doanh nghiệp — đổi công cụ xử lý
   mà không phải chuyển kho.
   → chip công nghệ bên dưới: MinIO · Iceberg · Polaris
```

Bản ✅ là copy thật đang chạy trong `PlatformGrid`. Tên công nghệ không biến mất
— nó xuống chip, đúng chỗ của nó. Nhóm 2 vẫn thấy đủ, nhóm 1 không bị chặn.

### 2.2 Định nghĩa trước khi đặt tên

Khi buộc phải dùng một khái niệm lạ, **mô tả nó trước, gọi tên sau**. Đừng ném
thuật ngữ ra rồi mới giải thích.

```
❌ Semantic layer giúp người dùng nghiệp vụ truy vấn dữ liệu dễ hơn.

✅ Người dùng nghiệp vụ đặt câu hỏi bằng ngôn ngữ tự nhiên, trên một lớp
   dữ liệu đã được định nghĩa sẵn ý nghĩa — semantic layer.
```

Người đọc gặp ý tưởng trước, cái tên sau. Đến lúc thấy chữ "semantic layer" thì
họ đã hiểu rồi, cái tên chỉ là nhãn dán.

### 2.3 Đối lập để làm rõ

Cách nhanh nhất để giải thích một thứ trừu tượng là đặt nó cạnh thứ nó **không
phải**. Cấu trúc "A làm X. B làm Y." rất mạnh vì nó vừa ngắn vừa tạo nhịp.

```
✅ Analytics giải thích chuyện đã xảy ra. AI mở ra chuyện có thể xảy ra.
✅ Governance không phải lớp dán thêm sau khi hệ thống chạy. Nó là một phần
   của kiến trúc ngay từ đầu.
```

### 2.4 Câu ngắn làm dấu nhấn

Nhịp mặc định là câu 15–25 từ. Cứ 3–4 câu, chèn **một câu rất ngắn** để đóng ý.
Câu ngắn đứng một mình có sức nặng mà câu dài không bao giờ có.

```
✅ Metadata, lineage, policy truy cập và audit được tích hợp xuyên suốt từ
   pipeline dữ liệu đến workflow AI. Không phải xử lý rời rạc về sau.
```

### 2.5 Xưng hô: "doanh nghiệp", không phải "bạn"

Tiếng Anh B2B dùng "you" rất thoải mái. Tiếng Việt B2B thì **không** — "bạn"
nghe như bán khóa học. Dùng chủ ngữ tổ chức:

- ✅ `doanh nghiệp`, `đội ngũ`, `người dùng nghiệp vụ`, `tổ chức`
- ⚠️ `bạn` — chỉ dùng trong tài liệu hướng dẫn (`docs/guides/`), không dùng ở landing
- ❌ `chúng tôi cam kết`, `quý khách`, `mình`

Câu hỏi tu từ thì vẫn dùng tốt, và dùng ở CTA là hợp nhất:

```
✅ Sẵn sàng biến dữ liệu thành năng lực cạnh tranh?
```

### 2.6 Số liệu: thật, hoặc không có

Không bịa số. Không viết "giảm 40% chi phí", "99.9% uptime", "nhanh hơn 10 lần"
nếu không có phép đo kèm nguồn.

Khi chưa có số, dùng **danh từ mô tả năng lực** thay vì con số giả:

```
❌ Giảm 60% thời gian xử lý dữ liệu.
✅ Xử lý đồng thời batch và real-time trên cùng một lớp lưu trữ.
```

---

## 3. Quy tắc thuật ngữ

Chuẩn tiếng Việt kỹ thuật (theo cách Viblo và cộng đồng data VN vẫn viết):
**tên riêng và thuật ngữ hạ tầng giữ tiếng Anh, phần mô tả dịch sang tiếng Việt.**

### Giữ nguyên tiếng Anh — không dịch

Tên sản phẩm và thuật ngữ đã thành chuẩn ngành. Dịch ra sẽ khó hiểu hơn:

```
Lakehouse, data lake, data warehouse, table format, semantic layer,
pipeline, streaming, batch, real-time, CDC, metadata, lineage,
governance, observability, compute, storage, workflow, agent, RAG,
LLM, model, inference, prompt, dashboard, API, connector, schema,
on-premise, private cloud, hybrid, cloud-native, open-source,
BI, GenAI, Customer 360, data product
```

Tên công cụ luôn viết đúng chính tả gốc: `Kafka`, `Spark`, `Iceberg`, `Airflow`,
`dbt` (thường, không viết hoa), `Dremio`, `DataHub`, `MinIO`, `NiFi`, `vLLM`,
`Superset`, `Polaris`, `Debezium`, `Ranger`, `Vault`, `Dify`, `Langfuse`.

### Dịch sang tiếng Việt

Động từ và khái niệm nghiệp vụ — dịch giúp câu mềm hơn mà không mất nghĩa:

| English | Tiếng Việt dùng trên trang này |
|---|---|
| unify / consolidate | hợp nhất |
| ingest | thu thập, đưa dữ liệu vào |
| orchestrate | điều phối |
| scale | mở rộng |
| deploy | triển khai |
| access control | phân quyền |
| data quality | chất lượng dữ liệu |
| trusted / reliable | tin cậy |
| end-to-end | xuyên suốt |
| vendor lock-in | khóa chặt vào một nhà cung cấp |

### Không bao giờ dùng

Từ sáo rỗng, không mang thông tin. Nếu xóa đi mà câu không mất nghĩa thì đó là từ thừa:

```
❌ toàn diện, tối ưu hóa, nâng tầm, đột phá, cách mạng, vượt trội,
   hàng đầu, tiên phong, giải pháp trọn gói, chuyển đổi số 4.0,
   kỷ nguyên số, sức mạnh vượt trội, đẳng cấp quốc tế
```

Kiểm tra nhanh: xóa tính từ đi, câu có yếu đi không? Nếu không → xóa luôn.

---

## 4. Ô chữ và giới hạn ký tự

Landing page là **layout cố định**. Chữ dài quá sẽ tràn dòng, vỡ lưới, hoặc đẩy
nút CTA xuống dưới màn hình. Các con số dưới đây **đo từ copy thật đang chạy**,
không phải ước lượng — bám sát vào là an toàn.

| Ô | Component | Ký tự | Ghi chú |
|---|---|---|---|
| `h1` hero | HeroSection | **≤ 48** | Render 56px trong cột 606px. Phải vừa **2 dòng**, và mỗi vế phải gọn 1 dòng — xem 4.1 |
| `h2` section | tất cả | **34–55** | Render 40–64px. Đây là lý do phải ngắn |
| `eyebrow` | tất cả | 15–31 | VIẾT HOA, mono. Nhãn phân loại, không phải câu |
| `title` (card) | PlatformGrid, UseCases | 13–29 | Danh từ, không phải câu. Không chấm cuối |
| `description` (card) | PlatformGrid, UseCases | **90–105** | Đúng 1 câu. Hai câu là tràn card |
| `description` (tab) | TabNavigation | 127–150 | Được 2 câu vì panel rộng hơn |
| `title` (tab) | TabNavigation | 50–55 | Câu hoàn chỉnh, có chấm |
| `bullet` | TabNavigation | ≤ 50 | Cụm danh từ. Không chấm cuối |
| `question` | FAQSection | 36–61 | Câu hỏi thật khách hàng hay hỏi |
| `answer` | FAQSection | 158–185 | 2–3 câu. Câu đầu trả lời thẳng Có/Không |
| `category` | UseCasesSection | 13–18 | Tên ngành, giữ tiếng Anh |
| `detail` (lớp KT) | CaseStudySection | 18–25 | Tên công cụ ngăn bằng ` · ` |
| `title` (roadmap) | CTABanner | 18–19 | Cụm động từ ngắn |
| chip công nghệ | PlatformGrid | ≤ 10 | Tên công cụ trần |

**Cách kiểm tra sau khi viết:**

```bash
cd website && npm start
# Mở http://localhost:3000, xem ở 3 khổ: 1512px, 1024px, 390px
```

Chữ tiếng Việt có dấu **cao hơn** chữ Latin không dấu — dấu mũ và dấu thanh ăn
thêm chiều cao dòng. Một tiêu đề vừa khít trong bản tiếng Anh có thể vỡ khi dịch.
Luôn xem thật, đừng đếm ký tự rồi tin.

### 4.1 `h1` hero — đếm ký tự là chưa đủ

`h1` được tách làm hai `<span>`, vế sau đổ gradient. Ràng buộc thật **không phải**
tổng số ký tự, mà là: **mỗi vế phải gọn đúng một dòng.**

Nếu một vế tràn sang dòng thứ hai, chỗ ngắt do trình duyệt tự chọn — và nó hay
cắt giữa một cụm từ. Ví dụ có thật:

```
❌ Nền tảng hợp          ← "hợp nhất" bị xé đôi
   nhất cho
   dữ liệu, phân tích
   và AI.                ← "và AI." trơ một dòng

✅ Nền tảng hợp nhất cho
   dữ liệu, phân tích và AI.
```

Cột chữ hero rộng **606px**. Ở cỡ 56px, mỗi vế chứa được **≈ 21–25 ký tự**.
Viết xong phải đo:

```js
// dán vào console trình duyệt, thay text cần thử
const h = document.querySelector('h1');
const probe = (txt) => {
  const s = document.createElement('span');
  s.style.cssText = `position:absolute;visibility:hidden;white-space:nowrap;
    font:600 ${getComputedStyle(h).fontSize} ${getComputedStyle(h).fontFamily};
    letter-spacing:-0.055em`;
  s.textContent = txt; document.body.appendChild(s);
  const w = s.getBoundingClientRect().width; s.remove();
  return `${Math.round(w)}px / cột ${Math.round(h.parentElement.getBoundingClientRect().width)}px`;
};
probe('Nền tảng hợp nhất cho');       // phải nhỏ hơn chiều rộng cột
probe('dữ liệu, phân tích và AI.');
```

Nếu vế nào vượt cột: rút ngắn chữ trước. Chỉ hạ `font-size` khi chữ đã không rút
được nữa — hero mất cỡ chữ là mất sức nặng.

---

## 5. Cấm — những lỗi đã từng xảy ra trên chính trang này

### 5.1 Chỉ báo giả

**Không tạo huy hiệu trạng thái, chỉ số, hay telemetry giả** khi không có dữ liệu
thật đằng sau.

Trang này từng có `Enterprise context: Connected` và `Live context` gắn trên cả 4
card use-case — hardcode, giống hệt nhau, không lấy từ đâu cả. Đã gỡ bỏ. Chúng
trông như số liệu nhưng không mang một bit thông tin nào, và người mua doanh
nghiệp nhận ra ngay.

Ngoại lệ duy nhất: bên **trong khung mô phỏng màn hình sản phẩm** có nhãn rõ
ràng (như `HANAS CONTROL PLANE` ở hero). Ở đó người xem đọc nó như ảnh chụp giao
diện, không phải như tuyên bố về hệ thống thật của họ.

### 5.2 Chữ lặp giống hệt nhau

Nếu cùng một chuỗi xuất hiện trên nhiều card, nó **không mang thông tin**. Hoặc
làm cho nó khác nhau theo từng card, hoặc bỏ đi.

```
❌ 4 card, cả 4 đều ghi "Enterprise context / Connected"
✅ 4 card, mỗi card một signal riêng:
   STREAM / PROFILE / DECIDE      (Customer 360)
   ASK / QUERY / EXPLAIN          (Conversational Analytics)
   RETRIEVE / REASON / RESPOND    (Knowledge Assistant)
   OBSERVE / DETECT / ACT         (Data Operations)
```

### 5.3 Dump tính năng

Không liệt kê tính năng thành chuỗi dấu phẩy. Mỗi card chỉ có **một ý**.

```
❌ Hỗ trợ ACID transaction, time travel, schema evolution, partition
   evolution, hidden partitioning và branching.
✅ Dữ liệu nằm ở định dạng mở và thuộc về doanh nghiệp — đổi công cụ xử lý
   mà không phải chuyển kho.
```

### 5.4 Hứa hẹn không kiểm chứng được

```
❌ Đảm bảo dữ liệu luôn chính xác 100%.
❌ Triển khai chỉ trong 2 tuần.
✅ Chất lượng dữ liệu được theo dõi và cảnh báo xuyên suốt pipeline.
```

---

## 6. Quy trình viết một section mới

1. **Đọc trước khi viết.** Mở `website/src/components/` và đọc 2–3 section đang
   có. Nhịp câu, độ dài, cách dùng thuật ngữ phải khớp với chúng. Nội dung mới
   không được đọc như của người khác viết.

2. **Viết câu kết quả trước.** Một câu, trả lời "doanh nghiệp được gì". Nếu chưa
   viết được câu này thì chưa hiểu tính năng đủ để viết về nó — quay lại đọc
   `website/docs/` phần tương ứng.

3. **Thêm cơ chế.** Tên công nghệ, luồng dữ liệu. Đẩy xuống chip hoặc bullet nếu
   được, đừng nhét vào câu mô tả.

4. **Cắt.** Đọc lại, xóa mọi tính từ không đổi nghĩa. Thường cắt được 20–30%.

5. **Đếm ký tự**, đối chiếu bảng mục 4.

6. **Xem thật** ở 3 khổ màn hình.

### Checklist trước khi giao

- [ ] Câu đầu nói kết quả, không nói công nghệ
- [ ] Không có từ trong danh sách cấm (mục 3)
- [ ] Mọi con số đều có nguồn thật
- [ ] Không có chỉ báo/trạng thái giả
- [ ] Không có chuỗi nào lặp giống hệt qua nhiều card
- [ ] Trong giới hạn ký tự (mục 4)
- [ ] Đã xem ở 1512 / 1024 / 390px, không vỡ layout
- [ ] Thuật ngữ khớp glossary mục 3
- [ ] Đọc to lên nghe được — không vấp, không sáo

---

## 7. Mẫu tham chiếu

Đây là copy thật đang chạy. Dùng làm chuẩn nhịp điệu:

**Hero** — 47 ký tự, 2 dòng, một câu hoàn chỉnh:
> Nền tảng hợp nhất cho / dữ liệu, phân tích và AI.

**Section h2** — 39 ký tự, cấu trúc "một / toàn bộ":
> Một nền tảng. Toàn bộ vòng đời dữ liệu.

**Card description** — 98 ký tự, một câu, kết quả trước:
> Đưa dữ liệu từ mọi hệ thống về một nơi, theo lô hoặc ngay khi phát sinh — không còn chờ batch đêm.

**Đoạn dẫn section** — 110 ký tự, câu hai ngắn làm dấu nhấn:
> Cùng một nền tảng, nhiều bài toán khác nhau. Dù là báo cáo hay ứng dụng AI, cách quản trị và bảo mật vẫn là một.

**FAQ answer** — 170 ký tự, trả lời thẳng rồi mới giải thích:
> Không. Hanas ưu tiên open-source, open table format và lớp giao tiếp tiêu chuẩn để doanh nghiệp có thể thay đổi compute, storage hoặc AI model mà không phải di chuyển toàn bộ dữ liệu.

---

## 8. Nguồn tham khảo văn phong

- **[Modern Data 101](https://moderndata101.substack.com/)** — cách giải thích
  khái niệm data platform cho người không chuyên. Học ở đây: mở bài bằng câu hỏi
  nền tảng thay vì thuật ngữ, dùng phép đối lập, xen câu ngắn làm dấu nhấn,
  định nghĩa trước khi đặt tên.

- **[Viblo](https://viblo.asia/)** — chuẩn trộn thuật ngữ Anh–Việt của cộng đồng
  kỹ thuật Việt Nam. Học ở đây: tên hạ tầng giữ tiếng Anh, phần mô tả dịch sang
  tiếng Việt, giọng vừa phải không suồng sã.
