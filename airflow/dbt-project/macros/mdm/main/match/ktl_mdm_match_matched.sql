{%- macro ktl_mdm_match_matched(general_conf,metadata_conf,rule_apply,validate_tbl_incre,dup_tbl,auto_match_tbl) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {%- set matched_element = [] -%}
    
    {## Auto match #}
    {%- set matched_auto_match_select_element = [] -%}
    {%- do matched_auto_match_select_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL."~cob_col) -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL.L_"~cob_col) -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL."~pk_key) -%}
    {%- set _auto_cols = [] -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, alias ="AUTO_TBL.", with_total_err_cnt=true) -%}
        {%- set col_up = col|upper -%}
        {%- if (col_up != 'AUTO_TBL.' ~ pk_key) and (col_up != 'AUTO_TBL.' ~ pk_key ~ '_CDT') and (col_up != 'AUTO_TBL.' ~ pk_key ~ '_ERR_CNT') -%}
            {%- do _auto_cols.append(col) -%}
        {%- endif -%}
    {%- endfor -%}
    {%- set matched_auto_match_select_element = matched_auto_match_select_element + _auto_cols -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL.HAS_MANUAL_MATCH") -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL.MANUAL_DUPLICATE_GROUP") -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL.HAS_AUTO_MATCH") -%}
    {%- do matched_auto_match_select_element.append("AUTO_TBL.AUTO_DUPLICATE_GROUP") -%}

    {%- do matched_element.append("SELECT") -%}
    {%- do matched_element.append(matched_auto_match_select_element|join(",\n")) -%}
    {%- do matched_element.append("FROM "~auto_match_tbl~" AUTO_TBL") -%}

    {## No auto match  #}
    {%- set matched_no_auto_match_select_element = [] -%}
    {%- do matched_no_auto_match_select_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do matched_no_auto_match_select_element.append("D_TBL."~cob_col) -%}
    {%- do matched_no_auto_match_select_element.append("D_TBL.L_"~cob_col) -%}
    {%- do matched_no_auto_match_select_element.append("V_TBL."~pk_key) -%}
    {%- set _v_cols = [] -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, alias ="V_TBL.", with_total_err_cnt=true) -%}
        {%- set col_up = col|upper -%}
        {%- if (col_up != 'V_TBL.' ~ pk_key) and (col_up != 'V_TBL.' ~ pk_key ~ '_CDT') and (col_up != 'V_TBL.' ~ pk_key ~ '_ERR_CNT') -%}
            {%- do _v_cols.append(col) -%}
        {%- endif -%}
    {%- endfor -%}
    {%- set matched_no_auto_match_select_element = matched_no_auto_match_select_element + _v_cols -%}
    {%- do matched_no_auto_match_select_element.append("CASE WHEN D_TBL."~pk_key~" IS NULL THEN 0 ELSE D_TBL.HAS_MANUAL_MATCH END HAS_MANUAL_MATCH") -%}
    {%- do matched_no_auto_match_select_element.append("D_TBL.MANUAL_DUPLICATE_GROUP") -%}
    {%- do matched_no_auto_match_select_element.append("CASE WHEN D_TBL."~pk_key~" IS NULL THEN 0 ELSE D_TBL.HAS_AUTO_MATCH END HAS_AUTO_MATCH") -%}
    {%- do matched_no_auto_match_select_element.append("D_TBL.AUTO_DUPLICATE_GROUP") -%}


    {%- do matched_element.append("\nUNION ALL\n") -%}
    
    {%- do matched_element.append("SELECT") -%}
    {%- do matched_element.append(matched_no_auto_match_select_element|join(",\n")) -%}
    {%- do matched_element.append("FROM "~validate_tbl_incre~" V_TBL") -%}
    {%- do matched_element.append("LEFT JOIN "~dup_tbl~" D_TBL") -%}
    {%- do matched_element.append("ON V_TBL."~pk_key~" = D_TBL."~pk_key~"") -%}
    {%- do matched_element.append("WHERE NOT EXISTS (") -%}
    {%- do matched_element.append("\tSELECT 1") -%}
    {%- do matched_element.append("\tFROM "~dup_tbl~" T") -%}
    {%- do matched_element.append("\tWHERE V_TBL."~pk_key~" = T."~pk_key~" AND T.HAS_AUTO_MATCH = 1") -%}
    {%- do matched_element.append(")") -%}




    {{ return(matched_element|join("\n")) }} 

{%- endmacro -%}