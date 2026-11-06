---
title: Nâng cấp và rollback
sidebar_label: Nâng cấp
sidebar_position: 9
description: Quy trình nâng cấp image qua file images.yaml, migration theo từng thành phần và cách quay về phiên bản trước.
---

Image của Hanas Data Platform được ghim tập trung trong `environments/images.yaml`. Trang này mô tả quy trình đổi phiên bản, migration cần lưu ý theo thành phần và các phương án rollback.

## Quy trình nâng cấp

1. Ghi lại phiên bản đang chạy (revision, digest) và feature flag. Tạo backup phù hợp theo [Sao lưu và khôi phục](backup-recovery.md).
2. Đọc CHANGELOG của bộ cài và cảnh báo từ pipeline phát hành. Nếu phiên bản mới có migration, thay đổi biến môi trường, cổng hoặc nginx, xử lý trước khi đổi image.
3. Sửa `repository`, toàn bộ `tag` kèm digest, và `source.revision` (nếu entry có) trong `environments/images.yaml`. Image API và graph-worker của Ontology nên cùng một bản phát hành tương thích.
4. Với Hanas Console, đồng bộ template nginx của chart với đúng image, rồi cập nhật khoá `ui.nginx.dynamicDns.templateForTag` trong values. Chart chặn nâng cấp nếu tag không khớp. Đây là ngoại lệ so với quy tắc chỉ sửa một file.
5. Xử lý migration và prerequisite theo bảng bên dưới, xem diff, rồi apply.
6. Chạy smoke test và kiểm tra chức năng ([Kiểm tra sức khỏe và giám sát](health-checks.md)); theo dõi trạng thái Ready, số lần restart và log.

```bash
helmfile diff
helmfile apply

# Hoặc chỉ một release, khi các release phụ thuộc đã sẵn sàng
helmfile -l name=ontology diff
helmfile -l name=ontology apply
```

Đừng giả định bộ chọn `-l` tự kéo theo mọi prerequisite. Bật hoặc tắt feature, đổi namespace hoặc đổi tên release là thay đổi dữ liệu và vòng đời, không chỉ là nâng image.

## Migration theo thành phần

| Thành phần | Cơ chế | Lưu ý khi nâng |
|---|---|---|
| Ontology | Job migration chạy trước khi nâng (hook `pre-upgrade`); ứng dụng kiểm schema ở chế độ verify. | Job không chạy khi rollback. Database cũ có thể gặp `MigrationIntegrityError` nếu lịch sử migration đã gộp; backup và thống nhất cách xử lý với đội ứng dụng, không tự sửa checksum. |
| Ontology, cờ destructive | `allowDestructiveMigrations` mặc định `false`. | Cờ này không đảm bảo chặn mọi lệnh xoá dữ liệu; đọc ghi chú phát hành. |
| dbt, database mới | Script khởi tạo chạy khi thư mục dữ liệu PostgreSQL còn trống. | Đổi ConfigMap không tạo lại database đã có. |
| dbt, database cũ | InitContainer `db-upgrade` bổ sung schema trước khi ứng dụng chạy (khi PostgreSQL đi kèm được bật). | Với database ngoài hoặc khi tắt bước này, bạn phải chạy SQL nâng cấp thủ công và đối chiếu schema với ứng dụng. |
| dbt, Flyway | Image mới tự migrate khi khởi động. | Migration tự động không có nghĩa là hỗ trợ downgrade. |
| Kapas | Entrypoint chạy migration trước khi phục vụ. | Lỗi DDL hoặc pgvector làm ứng dụng không khởi động. Một số migration xoá bảng; downgrade không khôi phục dữ liệu đã mất. Backup PVC và cấu hình agent trước khi nâng. |
| Superset | Job init chạy `superset db upgrade`; Secret gate điều phối thứ tự. | Giữ cấu hình không chờ Ready ở cấp release. PostgreSQL major version của PVC phải khớp binary. |
| Hanas Catalog | API và runner tự migrate, dùng advisory lock. | Cần role database có quyền DDL; giữ lịch sử migration và khoá mã hoá. |
| Ingestion | Flyway tự migrate khi pod khởi động. | User database cần quyền schema; lịch sử Flyway và khoá mã hoá thuộc phạm vi backup. |
| Spark Operator | Helm chỉ cài CRD lần đầu. | Khi nâng chart, cập nhật CRD trước bằng server-side apply. |

Ví dụ cập nhật CRD của Spark Operator, sau khi đã đánh giá tương thích với SparkApplication hiện có:

```bash
kubectl apply --server-side -f charts/spark-operator/crds/
```

:::caution Giới hạn hiện tại

Superset dùng PostgreSQL 14 trong cấu hình hiện tại. Nếu PVC cũ chứa dữ liệu của major version khác, PostgreSQL sẽ không mở được thư mục dữ liệu. Helm rollback không giải quyết trường hợp này; bạn cần chuyển đổi hoặc khôi phục theo major version.

:::

## Rollback

Chưa có runbook rollback toàn nền tảng đã được kiểm chứng. Các hướng dưới đây là khung tham khảo để bạn xây quy trình và thử trên môi trường tách biệt.

**Schema vẫn tương thích.** Đưa image trong `images.yaml` về bản đã ghi nhận, xem diff rồi apply. Hoặc dùng lịch sử Helm của một release:

```bash
helm history ontology -n ontology
helm rollback ontology <REVISION_DA_XAC_NHAN> -n ontology --wait
```

Sau khi rollback bằng Helm, cập nhật lại cấu hình nguồn. Nếu không, lần `helmfile apply` kế tiếp sẽ nâng release trở lại.

**Migration đã đổi schema hoặc xoá dữ liệu.** Helm rollback không hoàn tác SQL và không khôi phục object đã mất. Bạn cần khôi phục database, PVC và object storage về một mốc nhất quán, rồi triển khai phiên bản ứng dụng tương thích.

Khi khôi phục, giữ khoá mã hoá, credential nguồn, PAT và realm đúng với bản database. Tạm dừng schedule và worker trước khi restore để tránh ghi kép.

Khả năng downgrade của Keycloak, Superset, dbt, Hanas Catalog, Ingestion và query engine theo từng cặp phiên bản không được hỗ trợ chính thức; luôn sao lưu trước khi nâng cấp.

## Tiếp theo

- [Sao lưu và khôi phục](backup-recovery.md).
- [Kiểm tra sức khỏe và giám sát](health-checks.md).
- [Xử lý sự cố](troubleshooting.md).
