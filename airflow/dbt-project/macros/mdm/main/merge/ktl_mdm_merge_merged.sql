{%- macro ktl_mdm_merge_merged(general_conf,metadata_conf,rule_apply,mrlpivot_tbl,mrtrack_tbl,match_tbl_dict) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Extract input tbl dictionary #}
    {%- set master_tbl = match_tbl_dict.values()|first -%}
    {%- set master_tbl_alias = match_tbl_dict.keys()|first -%}
    {# Main handler #}
    {## CASE WHEN TRACKING  #}
    {%- set merge_tracking_case_when_element = [] -%}
    
    {### Master value  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- set merge_tracking_case_when_mini_element = [] -%}
        {%- do merge_tracking_case_when_mini_element.append("\tCASE") -%}
        {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
            {%- do merge_tracking_case_when_mini_element.append("\t\tWHEN MRTK_TBL."~col~"_TRACK = '"~tbl_alias~"' THEN "~tbl_alias~"."~col) -%}
        {%- endfor -%}

        {%- do merge_tracking_case_when_mini_element.append("\t\tELSE NULL") -%}
        {%- do merge_tracking_case_when_mini_element.append("\tEND "~col) -%}

        {%- do merge_tracking_case_when_element.append(merge_tracking_case_when_mini_element|join("\n")) -%}
    {%- endfor -%}

    {### Master cdt  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if ktl_mdm_utils_metadata_does_column_have_cdt(metadata_conf,col) == true -%}
            {%- set merge_tracking_case_when_mini_element = [] -%}
            {%- do merge_tracking_case_when_mini_element.append("\tCASE") -%}
            {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
                {%- do merge_tracking_case_when_mini_element.append("\t\tWHEN MRTK_TBL."~col~"_TRACK = '"~tbl_alias~"' THEN "~tbl_alias~"."~col~"_CDT") -%}
            {%- endfor -%}

            {%- do merge_tracking_case_when_mini_element.append("\t\tELSE NULL") -%}
            {%- do merge_tracking_case_when_mini_element.append("\tEND "~col~"_CDT") -%}

            {%- do merge_tracking_case_when_element.append(merge_tracking_case_when_mini_element|join("\n")) -%}
        {%- endif -%}
    {%- endfor -%}

    {### Master err_cnt  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- set merge_tracking_case_when_mini_element = [] -%}
        {%- do merge_tracking_case_when_mini_element.append("\tCASE") -%}
        {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
            {%- do merge_tracking_case_when_mini_element.append("\t\tWHEN MRTK_TBL."~col~"_TRACK = '"~tbl_alias~"' THEN "~tbl_alias~"."~col~"_ERR_CNT") -%}
        {%- endfor -%}

        {%- do merge_tracking_case_when_mini_element.append("\t\tELSE NULL") -%}
        {%- do merge_tracking_case_when_mini_element.append("\tEND "~col~"_ERR_CNT") -%}

        {%- do merge_tracking_case_when_element.append(merge_tracking_case_when_mini_element|join("\n")) -%}
    {%- endfor -%}

    {%- set merged_element = [] -%}

    {%- do merged_element.append("SELECT") -%}
    {%- do merged_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)~",") -%}
    {%- do merged_element.append("T."~cob_col~",") -%}
    {%- do merged_element.append("T.SOURCE_SYSTEM,") -%}
    {%- do merged_element.append("T."~pk_key~",") -%}
    {%- do merged_element.append(ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf,alias = "T.", with_total_err_cnt = false)|join(",\n")~",") -%}
    {%- do merged_element.append(ktl_mdm_utils_metadata_get_errcnt_column_lst(metadata_conf,alias="T.",with_total_err_cnt=false)|join("+")~ " AS TOTAL_ERR_CNT,") -%}
    {%- do merged_element.append("T.HAS_MANUAL_MATCH,") -%}
    {%- do merged_element.append("T.HAS_AUTO_MATCH,") -%}
    {%- do merged_element.append("T.HAS_MERGE") -%}

    {%- do merged_element.append("FROM (") -%}
    {%- do merged_element.append("\tSELECT") -%}
    {%- do merged_element.append("\t"~master_tbl_alias~".COB_DATE,") -%}
    {%- do merged_element.append("\t'"~master_tbl_alias~"' AS SOURCE_SYSTEM,") -%}
    {%- do merged_element.append("\t"~master_tbl_alias~"."~pk_key~",") -%}
    {%- do merged_element.append("\t"~merge_tracking_case_when_element|join(",\n\t")~",") -%}
    {%- do merged_element.append("\t"~master_tbl_alias~".HAS_MANUAL_MATCH,") -%}
    {%- do merged_element.append("\t"~master_tbl_alias~".HAS_AUTO_MATCH,") -%}
    {%- do merged_element.append("\t1 AS HAS_MERGE") -%}
    {%- do merged_element.append("\tFROM "~mrlpivot_tbl~" MRLP_TBL") -%}
    {%- do merged_element.append("\tJOIN "~mrtrack_tbl~" MRTK_TBL ON MRLP_TBL."~master_tbl_alias~"_"~pk_key~" = MRTK_TBL."~pk_key) -%}
    {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
        {%- do merged_element.append("\tLEFT JOIN "~tbl~" "~tbl_alias~" ON MRLP_TBL."~tbl_alias~"_"~pk_key~" = "~tbl_alias~"."~pk_key) -%}
    {%- endfor -%}

    {%- do merged_element.append(") T") -%}

    {{ return(merged_element|join("\n")) }}

{%- endmacro -%}

{%- macro ktl_mdm_merge_merged_hash_statement(item_statement) -%}
    {{ return(adapter.dispatch('ktl_mdm_merge_merged_hash_statement')(item_statement)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_merge_merged_hash_statement(item_statement) -%}
    {{ return("STANDARD_HASH("~item_statement~", 'SHA256')") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_merge_merged_hash_statement(item_statement) -%}
    {{ return("SHA2("~item_statement~", 256)") }}
{%- endmacro -%}