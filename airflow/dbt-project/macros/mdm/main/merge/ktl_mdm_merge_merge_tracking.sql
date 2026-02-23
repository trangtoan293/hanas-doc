{%- macro ktl_mdm_merge_merge_tracking(general_conf,metadata_conf,rule_apply,mrlpivot_tbl,match_tbl_dict) -%}
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
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- set merge_tracking_case_when_mini_element = [] -%}
        {%- do merge_tracking_case_when_mini_element.append("CASE") -%}
        {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
            {%- do merge_tracking_case_when_mini_element.append("\tWHEN "~tbl_alias~"."~col~"_ERR_CNT = 0 THEN '"~tbl_alias~"'") -%}
        {%- endfor -%}

        {%- do merge_tracking_case_when_mini_element.append("\tELSE '"~master_tbl_alias~"'") -%}
        {%- do merge_tracking_case_when_mini_element.append("END "~col~"_TRACK") -%}

        {%- do merge_tracking_case_when_element.append(merge_tracking_case_when_mini_element|join("\n")) -%}
    {%- endfor -%}

    {%- set merge_tracking_element = [] -%}

    {%- do merge_tracking_element.append("SELECT") -%}
    {%- do merge_tracking_element.append(ktl_mdm_merge_merge_tracking_hash_statement("MRLP_TBL.RULE_CODE || NVL(MRLP_TBL.MERGE_COLUMN,'000000000')")~" AS MERGE_GROUP,") -%}
    {%- do merge_tracking_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)~",") -%}
    {%- do merge_tracking_element.append(master_tbl_alias~".COB_DATE,") -%}
    {%- do merge_tracking_element.append("'"~master_tbl_alias~"' AS SOURCE_SYSTEM,") -%}
    {%- do merge_tracking_element.append(master_tbl_alias~"."~pk_key~",") -%}
    {%- do merge_tracking_element.append(merge_tracking_case_when_element|join(",\n")) -%}
    {%- do merge_tracking_element.append("FROM "~mrlpivot_tbl~" MRLP_TBL") -%}
    {%- for tbl_alias, tbl in match_tbl_dict.items() -%}
        {%- do merge_tracking_element.append("LEFT JOIN "~tbl~" "~tbl_alias~" ON MRLP_TBL."~tbl_alias~"_"~pk_key~" = "~tbl_alias~"."~pk_key) -%}
    {%- endfor -%}
    {{ return(merge_tracking_element|join("\n")) }}

{%- endmacro -%}

{%- macro ktl_mdm_merge_merge_tracking_hash_statement(item_statement) -%}
    {{ return(adapter.dispatch('ktl_mdm_merge_merge_tracking_hash_statement')(item_statement)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_merge_merge_tracking_hash_statement(item_statement) -%}
    {{ return("STANDARD_HASH("~item_statement~", 'SHA256')") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_merge_merge_tracking_hash_statement(item_statement) -%}
    {{ return("SHA2("~item_statement~", 256)") }}
{%- endmacro -%}