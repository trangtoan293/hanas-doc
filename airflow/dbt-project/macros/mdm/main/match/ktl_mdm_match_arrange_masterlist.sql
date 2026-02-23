{%- macro ktl_mdm_match_arrange_masterlist(general_conf,metadata_conf,rule_apply,validate_tbl_lastest,dup_tbl) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {## CTE_VALIDATE_TBL_OF_AUTO_MATCH #}
    {%- set match_select_cte_vtbl_element = ["V_TBL."~pk_key] -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- do match_select_cte_vtbl_element.append("V_TBL."~col) -%}
        {%- endif -%}
    {%- endfor %}


    {%- set match_arrange_masterlist_element = [] -%}
    {%- do match_arrange_masterlist_element.append("WITH CTE_VALIDATE_TBL_OF_AUTO_MATCH AS (") -%}
    {%- do match_arrange_masterlist_element.append("\tSELECT "~match_select_cte_vtbl_element|join(",\n\t")~",") -%}
    {%- do match_arrange_masterlist_element.append("\tD_TBL."~cob_col~",") -%}
    {%- do match_arrange_masterlist_element.append("\tD_TBL.L_"~cob_col~",") -%}
    {%- do match_arrange_masterlist_element.append("\tD_TBL.HAS_AUTO_MATCH,") -%}
    {%- do match_arrange_masterlist_element.append("\tD_TBL.MANUAL_DUPLICATE_GROUP,") -%}
    {%- do match_arrange_masterlist_element.append("\tD_TBL.AUTO_DUPLICATE_GROUP") -%}
    {%- do match_arrange_masterlist_element.append("\tFROM "~dup_tbl~" D_TBL") -%}
    {%- do match_arrange_masterlist_element.append("\tJOIN "~validate_tbl_lastest~" V_TBL ON V_TBL."~pk_key~" = D_TBL."~pk_key~"") -%}
    {%- do match_arrange_masterlist_element.append("\tWHERE D_TBL.HAS_AUTO_MATCH = 1") -%}
    {%- do match_arrange_masterlist_element.append("),\n") -%}

    {## CTE_CHOOSE_KEY #}
    {### Choose key priority by  #}
    {%- set choose_key_priority_by_lst = [] -%}
    {%- for column, ord_type in rule_apply.get("auto_match_pkkey_priority_by").items() -%}
        {%- do choose_key_priority_by_lst.append(column~" "~ord_type|upper) -%}
    {%- endfor -%}
    {%- do choose_key_priority_by_lst.append(pk_key~" ASC") -%}


    {%- do match_arrange_masterlist_element.append("CTE_CHOOSE_KEY AS (") -%}
    {%- do match_arrange_masterlist_element.append("\tSELECT * FROM (") -%}
    {%- do match_arrange_masterlist_element.append("\t\tSELECT "~pk_key~",") -%}
    {%- do match_arrange_masterlist_element.append("\t\tMANUAL_DUPLICATE_GROUP,") -%}
    {%- do match_arrange_masterlist_element.append("\t\tAUTO_DUPLICATE_GROUP,") -%}
    {%- do match_arrange_masterlist_element.append("\t\t"~cob_col~",") -%}
    {%- do match_arrange_masterlist_element.append("\t\tL_"~cob_col~",") -%}
    {%- do match_arrange_masterlist_element.append("\t\tROW_NUMBER() OVER(PARTITION BY AUTO_DUPLICATE_GROUP ORDER BY "~choose_key_priority_by_lst|join(", ")~" ) "~pk_key~"_RN") -%} {# TODO #}
    {%- do match_arrange_masterlist_element.append("\t\tFROM CTE_VALIDATE_TBL_OF_AUTO_MATCH") -%}
    {%- do match_arrange_masterlist_element.append("\t) WHERE "~pk_key~"_RN = 1") -%}
    {%- do match_arrange_masterlist_element.append(")\n") -%}

    {## MAIN SELECT #}
    {%- set match_arrange_masterlist_select_element = ["\t"~ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)] -%}
    {%- do match_arrange_masterlist_select_element.append("K_TBL."~cob_col) -%}
    {%- do match_arrange_masterlist_select_element.append("V_TBL.L_"~cob_col) -%}
    {%- do match_arrange_masterlist_select_element.append("K_TBL."~pk_key) -%}
    {%- do match_arrange_masterlist_select_element.append("V_TBL."~pk_key~" AS "~pk_key~"_REF") -%}
    {%- do match_arrange_masterlist_select_element.append("K_TBL.MANUAL_DUPLICATE_GROUP") -%}
    {%- do match_arrange_masterlist_select_element.append("K_TBL.AUTO_DUPLICATE_GROUP") -%}

    {%- for col in ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf) -%}
        {%- if col|upper != pk_key -%}
            {%- do match_arrange_masterlist_select_element.append("V_TBL."~col) -%}
        {%- endif -%}
    {%- endfor -%}

    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- if ktl_mdm_utils_metadata_does_column_have_cdt(metadata_conf,col) == true -%}
            {%- do match_arrange_masterlist_select_element.append("ROW_NUMBER() OVER (PARTITION BY V_TBL.AUTO_DUPLICATE_GROUP ORDER BY SIGN(V_TBL."~col~"_ERR_CNT) ASC, V_TBL."~col~"_CDT DESC, (CASE WHEN V_TBL."~pk_key~" = K_TBL."~pk_key~" THEN 1 ELSE 0 END) DESC) AS "~col~"_RN") -%}
        {%- else -%}
            {%- do match_arrange_masterlist_select_element.append("ROW_NUMBER() OVER (PARTITION BY V_TBL.AUTO_DUPLICATE_GROUP ORDER BY SIGN(V_TBL."~col~"_ERR_CNT) ASC, (CASE WHEN V_TBL."~pk_key~" = K_TBL."~pk_key~" THEN 1 ELSE 0 END) DESC) AS "~col~"_RN") -%}
        {%- endif -%}
    {%- endfor -%}

    {%- do match_arrange_masterlist_element.append("SELECT") -%}
    {%- do match_arrange_masterlist_element.append(match_arrange_masterlist_select_element|join(",\n\t")) -%}
    {%- do match_arrange_masterlist_element.append("FROM CTE_CHOOSE_KEY K_TBL") -%}
    {%- do match_arrange_masterlist_element.append("JOIN CTE_VALIDATE_TBL_OF_AUTO_MATCH V_TBL") -%}
    {%- do match_arrange_masterlist_element.append("ON K_TBL.AUTO_DUPLICATE_GROUP = V_TBL.AUTO_DUPLICATE_GROUP") -%}

    {{ return(match_arrange_masterlist_element|join("\n")) }} 
{%- endmacro -%}





