{%- macro ktl_mdm_auto_match(general_conf,metadata_conf,rule_apply,arrange_tbl) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {## Select statement #}
    {%- set auto_match_select_element = [] -%}
    {%- do auto_match_select_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do auto_match_select_element.append("R."~cob_col) -%}
    {%- do auto_match_select_element.append("R.L_"~cob_col) -%}
    {%- do auto_match_select_element.append("T."~pk_key) -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, with_total_err_cnt=false) -%}
        {%- set col_up = col|upper -%}
        {%- if col_up != pk_key and (col_up != pk_key ~ '_CDT') and (col_up != pk_key ~ '_ERR_CNT') -%}
            {%- do auto_match_select_element.append("T."~col) -%}
        {%- endif -%}
    {%- endfor -%}
    {%- set _err_cols = [] -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- do _err_cols.append("T."~col~"_ERR_CNT") -%}
        {%- endif -%}
    {%- endfor -%}
    {%- do auto_match_select_element.append(_err_cols|join("+")~ " AS TOTAL_ERR_CNT") -%}
    {%- do auto_match_select_element.append("CASE WHEN R.MANUAL_DUPLICATE_GROUP IS NULL THEN 0 ELSE 1 END HAS_MANUAL_MATCH") -%}
    {%- do auto_match_select_element.append("R.MANUAL_DUPLICATE_GROUP") -%}
    {%- do auto_match_select_element.append("1 AS HAS_AUTO_MATCH") -%}
    {%- do auto_match_select_element.append("R.AUTO_DUPLICATE_GROUP") -%}

    {## From mini select statement #}
    {%- set auto_match_from_mini_select_element = [] -%}
    {%- do auto_match_from_mini_select_element.append(pk_key) -%}
    {### Master key  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- do auto_match_from_mini_select_element.append("MAX(CASE WHEN "~col~"_RN = 1 THEN "~col~" ELSE NULL END) AS "~col~"") -%}
        {%- endif -%}
    {%- endfor -%}
    
    {### CDT of master key  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- if ktl_mdm_utils_metadata_does_column_have_cdt(metadata_conf,col) == true -%}
                {%- do auto_match_from_mini_select_element.append("MAX(CASE WHEN "~col~"_RN = 1 THEN "~col~"_CDT ELSE NULL END) AS "~col~"_CDT") -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}

    {### ERR_CNT  #}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- do auto_match_from_mini_select_element.append("MAX(CASE WHEN "~col~"_RN = 1 THEN "~col~"_ERR_CNT ELSE NULL END) AS "~col~"_ERR_CNT") -%}
        {%- endif -%}
    {%- endfor -%}


    {%- set auto_match_element = [] -%}
    {%- do auto_match_element.append("SELECT") -%}
    {%- do auto_match_element.append(auto_match_select_element|join(",\n")) -%}

    {%- do auto_match_element.append("FROM (") -%}
    {%- do auto_match_element.append("\tSELECT "~auto_match_from_mini_select_element|join(",\n\t")) -%}

    {%- do auto_match_element.append("\tFROM "~arrange_tbl~"") -%}
    {%- do auto_match_element.append("\tGROUP BY "~pk_key~"") -%}
    {%- do auto_match_element.append(") T") -%}
    {%- do auto_match_element.append("JOIN "~arrange_tbl~" R ON T."~pk_key~" = R."~pk_key~"_REF") -%}

    {{ return(auto_match_element|join("\n")) }} 


{%- endmacro -%}