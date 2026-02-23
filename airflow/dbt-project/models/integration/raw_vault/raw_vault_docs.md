## Tables

### Hub
{% docs hub_customer %}
Thông tin CIF_NO của khách hàng được lưu trữ tập trung tại bảng hub_customer.
Bảng hub_customer được load bởi apache spark.
{% enddocs %}

{% docs hub_gl %}
Thông tin BANK_AC của sổ cái (general ledger) được lưu trữ tập trung tại bảng hub_gl.
Bảng hub_gl được load bởi apache spark.
{% enddocs %}

{% docs hub_branch %}
Thông tin POS_CD của chi nhánh được lưu trữ tập trung tại bảng hub_branch.
Bảng hub_branch được load bởi apache spark.
{% enddocs %}

{% docs hub_card %}
Thông tin id của thẻ được lưu trữ tập trung tại bảng hub_card.
Bảng hub_card được load bởi apache spark.
{% enddocs %}

### Link
{% docs lnk_branch_gl %}
Lưu trữ thông tin relationship giữa hub_branch và hub_gl.
{% enddocs %}

{% docs lnk_branch_parent %}
Lưu trữ thông tin relationship phân cấp giữa các chi nhánh (parent-child).
{% enddocs %}

### Sat
{% docs sat_customer %}
Lưu trữ thông tin mô tả của khách hàng.
{% enddocs %}

{% docs sat_branch %}
Lưu trữ thông tin mô tả của chi nhánh.
{% enddocs %}

{% docs sat_card %}
Lưu trữ thông tin mô tả của thẻ.
{% enddocs %}

{% docs sat_gl %}
Lưu trữ thông tin mô tả của sổ cái (general ledger).
{% enddocs %}

{% docs sat_gl_sbv %}
Lưu trữ thông tin mô tả của sổ cái (general ledger) từ nguồn SBV.
{% enddocs %}

{% docs sat_snp_customer %}
Lưu trữ thông tin mô tả gần nhất của khách hàng.
{% enddocs %}

{% docs sat_snp_branch %}
Lưu trữ thông tin mô tả gần nhất của chi nhánh.
{% enddocs %}

{% docs sat_snp_card %}
Lưu trữ thông tin mô tả gần nhất của thẻ.
{% enddocs %}

{% docs sat_snp_gl %}
Lưu trữ thông tin mô tả gần nhất của sổ cái (general ledger).
{% enddocs %}

{% docs sat_snp_gl_sbv %}
Lưu trữ thông tin mô tả gần nhất của sổ cái (general ledger) từ nguồn SBV.
{% enddocs %}

{% docs sat_der_customer %}
Lưu trữ thông tin mô tả của khách hàng tại ngày T-1.
{% enddocs %}

{% docs sat_der_branch %}
Lưu trữ thông tin mô tả của chi nhánh tại ngày T-1.
{% enddocs %}

{% docs sat_der_card %}
Lưu trữ thông tin mô tả của thẻ tại ngày T-1.
{% enddocs %}

{% docs sat_der_gl %}
Lưu trữ thông tin mô tả của sổ cái (general ledger) tại ngày T-1.
{% enddocs %}

{% docs sat_der_gl_sbv %}
Lưu trữ thông tin mô tả của sổ cái (general ledger) từ nguồn SBV tại ngày T-1.
{% enddocs %}

### MDM

{% docs sat_customer_cleaned %}
Lưu trữ thông tin mô tả của khách hàng đã được áp dụng các rule MDM clean.
{% enddocs %}

{% docs sat_customer_cleaned_mdm %}
Lưu trữ thông tin kết quả áp dụng rule MDM validate trên bảng sat_customer_cleaned.
{% enddocs %}

{% docs mdm_core_cif_results %}
Lưu trữ thông tin kết quả MDM và đánh dấu golden record.
{% enddocs %}

## Columns

{% docs dv_hsh_dif %}
Hash key của các trường mô tả của bảng satellite.
{% enddocs %}

{% docs dv_ldt %}
Thời điểm dữ liệu được load từ vùng raw vault.
{% enddocs %}

{% docs dv_src_ldt %}
Thời điểm dữ liệu được insert từ source.
{% enddocs %}

{% docs dv_src_rec %}
Tên bảng source của dữ liệu.
{% enddocs %}

{% docs dv_kaf_ldt %}
Thời điểm dữ liệu được load từ kafka.
{% enddocs %}

{% docs dv_kaf_ofs %}
Số offset của kafka.
{% enddocs %}

{% docs dv_cdc_ops %}
Loại CDC (change data capture) bao gồm :"R"="read", "I"="insert", "U"="update" và "D"="delete".
{% enddocs %}

{% docs dv_ccd %}
Collision code của bảng nguồn.
{% enddocs %}

{% docs ADDR %}
Địa chỉ thẻ.
{% enddocs %}

{% docs CUSTOMER_TYPE %}
Loại khách hàng: I = cá nhân, C = tổ chức.
{% enddocs %}

{% docs F_NAME %}
Họ của khách hàng cá nhân.
{% enddocs %}

{% docs M_NAME %}
Tên đệm của khách hàng cá nhân.
{% enddocs %}

{% docs L_NAME %}
Tên của khách hàng cá nhân.
{% enddocs %}

{% docs CO_NAME %}
Tên công ty tổ chức.
{% enddocs %}

{% docs SEX_CD %}
Giới tính: M = Nam, F = Nữ.
{% enddocs %}

{% docs D_O_B %}
Ngày sinh.
{% enddocs %}

{% docs PASS_NO %}
Số giấy tờ tùy thân.
{% enddocs %}

{% docs PASS_I_DT %}
Ngày cấp giấy tờ.
{% enddocs %}

{% docs PASS_E_DT %}
Ngày hết hạn giấy tờ.
{% enddocs %}

{% docs NOI_CAP_GTTT %}
Nơi cấp giấy tờ tùy thân.
{% enddocs %}

{% docs LOAI_GTTT %}
Loại giấy tờ tùy thân.
{% enddocs %}

{% docs SO_THI_THUC %}
Số thị thực (không dùng).
{% enddocs %}

{% docs VISA_ISSUE_DT %}
Ngày cấp thị thực (không dùng).
{% enddocs %}

{% docs VISA_EXPIRY_DT %}
Ngày hết hạn thị thực (không dùng).
{% enddocs %}

{% docs NOI_CAP_THI_THUC %}
Nơi cấp thị thực (không dùng).
{% enddocs %}

{% docs QUOC_TICH %}
Quốc tịch.
{% enddocs %}

{% docs LEG_ST %}
Trạng thái pháp lý giả lập.
{% enddocs %}

{% docs RES_ADD_1 %}
Địa chỉ cụ thể.
{% enddocs %}

{% docs RES_CNTRY_CD %}
Mã quốc gia của địa chỉ thường trú.
{% enddocs %}

{% docs OFF_ADD_2 %}
Thành phố.
{% enddocs %}

{% docs OFF_CNTRY_CD %}
Mã quốc gia của địa chỉ cơ quan.
{% enddocs %}

{% docs QUOC_GIA_NUOC_NGOAI %}
Quốc gia nước ngoài (nếu có).
{% enddocs %}

{% docs RES_PH_NO_1 %}
Điện thoại nhà riêng 1.
{% enddocs %}

{% docs RES_PH_NO_2 %}
Điện thoại nhà riêng 2.
{% enddocs %}

{% docs MOBILE %}
Điện thoại di động.
{% enddocs %}

{% docs EMAIL_ID1 %}
Email 1.
{% enddocs %}

{% docs EMAIL_ID2 %}
Email 2.
{% enddocs %}

{% docs EOD_DATE %}
Ngày dữ liệu.
{% enddocs %}

{% docs DR_CR_FLG %}
Flag: C = CREDIT, D = DEBIT.
{% enddocs %}

{% docs LCY_AMT %}
Số tiền đã quy đổi.
{% enddocs %}

{% docs FCY_AMT %}
Số tiền nguyên tệ.
{% enddocs %}

{% docs NUM_DUPLICATES %}
Số lượng dòng trùng lặp.
{% enddocs %}

{% docs GL_SL %}
Mã GL_SL.
{% enddocs %}

{% docs CCY_CD %}
Mã loại tiền.
{% enddocs %}

{% docs SBV_GL_SL %}
Mã SBV.
{% enddocs %}

{% docs dv_hkey_hub_customer %}
Hash key của hub customer được sinh ra bởi CIF_NO bằng hàm SHA256.
{% enddocs %}

{% docs CIF_NO %}
Business key của hub customer: mã CIF của khách hàng.
{% enddocs %}

{% docs dv_hkey_hub_gl %}
Hash key của hub gl được sinh ra bởi BANK_AC hoặc AC_NO bằng hàm SHA256.
{% enddocs %}

{% docs BANK_AC %}
Business key của hub gl: mã GL.
{% enddocs %}

{% docs dv_hkey_hub_branch %}
Hash key của hub branch được sinh ra bởi POS_CD bằng hàm SHA256.
{% enddocs %}

{% docs POS_CD %}
Business key của hub branch: Mã chi nhánh/ phòng giao dịch.
{% enddocs %}

{% docs dv_hkey_hub_card %}
Hash key của hub card được sinh ra bởi id bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_lnk_branch_gl %}
Hash key của link branch_gl, được sinh ra bởi concat(POS_CD, AC_NO) bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_lnk_branch_parent %}
Hash key của link branch_parent-branch, được sinh ra bởi concat(POS_CD, MAIN_POS) bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_hub_branch_parent %}
Hash key của hub branch (parent) được sinh ra bởi MAIN_POS bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_sat_customer %}
Hash key được sinh ra bởi CIF_NO bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_sat_branch %}
Hash key được sinh ra bởi POS_CD bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_sat_card %}
Hash key được sinh ra bởi id bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_sat_gl %}
Hash key được sinh ra bởi BANK_AC bằng hàm SHA256.
{% enddocs %}

{% docs dv_hkey_sat_gl_sbv %}
Hash key được sinh ra bởi BANK_AC bằng hàm SHA256.
{% enddocs %}

{% docs STAFF_NUM %}
Số lượng nhận sự tại chi nhánh.
{% enddocs %}

{% docs AC_NO %}
Tài khoản GL.
{% enddocs %}

