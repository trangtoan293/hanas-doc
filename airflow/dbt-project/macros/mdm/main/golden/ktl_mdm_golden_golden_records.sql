{%- macro ktl_mdm_golden_golden_records(general_conf,metadata_conf,rule_apply,mr_tbl,mrlpivot_tbl,match_tbl_dict) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {%- set golden_table_statement_lst = [] -%}

    {## Merged table #}
    {%- set merged_table_element = [] -%}
    {%- do merged_table_element.append("SELECT") -%}
    {%- do merged_table_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)~",") -%}
    {%- do merged_table_element.append("MR_TBL."~cob_col~",") -%}
    {%- do merged_table_element.append('MR_TBL.SOURCE_SYSTEM,') -%}
    {%- do merged_table_element.append("MR_TBL."~pk_key~",") -%}
    {%- do merged_table_element.append(ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, alias = "MR_TBL.", with_total_err_cnt = true)|join(",\n")~",") -%}
	{%- do merged_table_element.append("MR_TBL.HAS_MANUAL_MATCH,") -%}
	{%- do merged_table_element.append("MR_TBL.HAS_AUTO_MATCH,") -%}
	{%- do merged_table_element.append("MR_TBL.HAS_MERGE,") -%}
	{%- do merged_table_element.append("CASE ") -%}
	{%- do merged_table_element.append("\tWHEN MR_TBL.TOTAL_ERR_CNT = 0 AND MR_TBL.HAS_MANUAL_MATCH = 0 THEN 1 ") -%}
	{%- do merged_table_element.append("\tWHEN MR_TBL.TOTAL_ERR_CNT = 0 AND MR_TBL.HAS_MANUAL_MATCH = 1 AND MR_TBL.HAS_AUTO_MATCH = 1 THEN 1 ") -%}
	{%- do merged_table_element.append("\tELSE 0 ") -%}
	{%- do merged_table_element.append("END GOLDEN_RECORD") -%}
    {%- do merged_table_element.append("FROM "~mr_tbl~" MR_TBL") -%}

    {%- do golden_table_statement_lst.append(merged_table_element|join("\n")) -%}
    
    {## Each non merge table #}
    {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
        {%- set non_merge_table_element = [] -%}    
        {%- do non_merge_table_element.append("SELECT") -%}
        {%- do non_merge_table_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)~",") -%}
        {%- do non_merge_table_element.append("M_TBL."~cob_col~",") -%}
        {%- do non_merge_table_element.append("'"~tbl_alias~"'AS SOURCE_SYSTEM,") -%}
        {%- do non_merge_table_element.append("M_TBL."~pk_key~",") -%}
        {%- do non_merge_table_element.append(ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, alias = "M_TBL.", with_total_err_cnt = true)|join(",\n")~",") -%}
        {%- do non_merge_table_element.append("M_TBL.HAS_MANUAL_MATCH,") -%}
        {%- do non_merge_table_element.append("M_TBL.HAS_AUTO_MATCH,") -%}
        {%- do non_merge_table_element.append("0 AS HAS_MERGE,") -%}
        {%- do non_merge_table_element.append("CASE ") -%}
        {%- do non_merge_table_element.append("\tWHEN M_TBL.TOTAL_ERR_CNT = 0 AND M_TBL.HAS_MANUAL_MATCH = 0 THEN 1 ") -%}
        {%- do non_merge_table_element.append("\tWHEN M_TBL.TOTAL_ERR_CNT = 0 AND M_TBL.HAS_MANUAL_MATCH = 1 AND M_TBL.HAS_AUTO_MATCH = 1 THEN 1 ") -%}
        {%- do non_merge_table_element.append("\tELSE 0 ") -%}
        {%- do non_merge_table_element.append("END GOLDEN_RECORD") -%}
        
        {%- do non_merge_table_element.append("FROM "~tbl~" M_TBL") -%}
        {%- do non_merge_table_element.append("LEFT JOIN "~mrlpivot_tbl~" MRLP_TBL") -%}
        {%- do non_merge_table_element.append("ON M_TBL."~pk_key~" = MRLP_TBL."~tbl_alias~"_"~pk_key) -%}
        {%- do non_merge_table_element.append("WHERE MRLP_TBL."~tbl_alias~"_"~pk_key~" IS NULL") -%}

        {%- do golden_table_statement_lst.append(non_merge_table_element|join("\n")) -%}
    {%- endfor -%}


    {{ golden_table_statement_lst|join("\n\nUNION ALL\n\n") }}
{%- endmacro -%}