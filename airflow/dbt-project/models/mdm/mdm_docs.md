## MDM Models

{% docs mdm_source_corecif %}
Bảng nguồn MDM kết hợp hub_customer và sat_snp_customer để cung cấp business key (CIF_NO) và tất cả các thuộc tính khách hàng phục vụ cho quá trình Master Data Management.
{% enddocs %}

{% docs mdm_corecif_cleansed %}
Lưu trữ thông tin khách hàng đã được áp dụng các rule MDM cleansing
{% enddocs %}

{% docs mdm_corecif_invalid %}
Lưu trữ chi tiết các record vi phạm validation rules trên bảng MDM_CORECIF_CLEANSED. Mỗi record trong bảng này đại diện cho một vi phạm cụ thể.
{% enddocs %}

{% docs mdm_corecif_validate %}
Lưu trữ kết quả tổng hợp số lượng lỗi validation cho mỗi CIF_NO và tính tổng số lỗi.
{% enddocs %}

{% docs mdm_corecif_match %}
Lưu trữ kết quả đánh dấu các CIF_NO có khả năng trùng lặp theo các match rules.
{% enddocs %}

{% docs mdm_corecif_merge %}
Lưu trữ tất cả các bản ghi khách hàng đã qua cleansing và loại bỏ các record trùng lặp theo rule matching.
{% enddocs %}

{% docs mdm_corecif_golden_records %}
Lưu trữ chỉ các golden records.
{% enddocs %}
