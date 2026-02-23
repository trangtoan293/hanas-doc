{%- macro ktl_mdm_match_duplicate(general_conf,metadata_conf,rule_apply,source_system,dupno_tbl) -%}
    {# General_config #}
    {%- set match_column_cnt = general_conf.get('general_config').get('match_column_cnt') -%}
    {%- set match_group_cnt = general_conf.get('general_config').get('match_group_cnt') -%}

    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {%- set auto_rule_apply = ktl_mdm_match_utils_get_auto_match(rule_apply) -%}
    {%- set manual_rule_apply = ktl_mdm_match_utils_get_manual_match(rule_apply) -%}

    {# Select  #}
    {%- set match_duplicate_cte_select_count_over_element = [] -%}
    {%- set match_column_lst = [] -%}

    {%- for i in range(1,match_column_cnt+1) -%}
        {%- do match_column_lst.append('MATCH_COLUMN_'~i) -%}
        {%- do match_duplicate_cte_select_count_over_element.append("NVL(MATCH_COLUMN_"~i~",'')") -%}
    {%- endfor -%}
    
    {%- for i in range(1,match_group_cnt+1) -%}
        {%- do match_column_lst.append('MATCH_GROUP_'~i) -%}
        {%- do match_duplicate_cte_select_count_over_element.append("NVL(MATCH_GROUP_"~i~",'')") -%}
    {%- endfor -%}

    {%- set match_duplicate_summary_select_element = [pk_key,"L_"~cob_col,'RULE_CODE'] + match_column_lst -%}

    
    {%- set match_duplicate_cte_table_lst = [] -%}
    {# Each cte_tbl order rule auto #}
    {%- for i in range(auto_rule_apply|length)-%}
        {%- set match_duplicate_cte_where_element = ["RULE_CODE = '"~auto_rule_apply[i].get('name')~"'"] -%}
        {%- for j in range(i)-%}
            {%- do match_duplicate_cte_where_element.append("NOT EXISTS (SELECT 1 FROM CTE_AUTO_"~auto_rule_apply[j].get('name')~" T WHERE T.RULE_CODE ='"~auto_rule_apply[j].get('name')~"' AND T."~pk_key~" = dupno_tbl."~pk_key~")") -%}
        {%- endfor -%}

        {%- set match_duplicate_cte_table_element = [] -%}
        {%- do match_duplicate_cte_table_element.append("CTE_AUTO_"~auto_rule_apply[i].get('name')~" AS (") -%}
        {%- do match_duplicate_cte_table_element.append("\tSELECT * FROM (") -%}

        {%- do match_duplicate_cte_table_element.append("\t\tSELECT dupno_tbl.* , COUNT(1) OVER(PARTITION BY "~match_duplicate_cte_select_count_over_element|join(", ")~") CNT") -%}
        {%- do match_duplicate_cte_table_element.append("\t\tFROM "~dupno_tbl~" dupno_tbl") -%}
        {%- do match_duplicate_cte_table_element.append("\t\tWHERE "~match_duplicate_cte_where_element|join("\n\t\tAND ")) -%}
        {%- do match_duplicate_cte_table_element.append("\t) WHERE CNT > 1") -%}
        {%- do match_duplicate_cte_table_element.append(")") -%}

        {%- do match_duplicate_cte_table_lst.append(match_duplicate_cte_table_element|join("\n")) -%}
    {%- endfor -%}

    {# Each cte_tbl order rule manual #}
    {%- for i in range(manual_rule_apply|length)-%}
        {%- set match_duplicate_cte_where_element = ["RULE_CODE = '"~manual_rule_apply[i].get('name')~"'"] -%}
        {%- for j in range(i)-%}
            {%- do match_duplicate_cte_where_element.append("NOT EXISTS (SELECT 1 FROM CTE_MANUAL_"~manual_rule_apply[j].get('name')~" T WHERE T.RULE_CODE ='"~manual_rule_apply[j].get('name')~"' AND T."~pk_key~" = dupno_tbl."~pk_key~")") -%}
        {%- endfor -%}

        {%- set match_duplicate_cte_table_element = [] -%}
        {%- do match_duplicate_cte_table_element.append("CTE_MANUAL_"~manual_rule_apply[i].get('name')~" AS (") -%}
        {%- do match_duplicate_cte_table_element.append("\tSELECT * FROM (") -%}

        {%- do match_duplicate_cte_table_element.append("\t\tSELECT dupno_tbl.* , COUNT(1) OVER(PARTITION BY "~match_duplicate_cte_select_count_over_element|join(", ")~") CNT") -%}
        {%- do match_duplicate_cte_table_element.append("\t\tFROM "~dupno_tbl~" dupno_tbl") -%}
        {%- do match_duplicate_cte_table_element.append("\t\tWHERE "~match_duplicate_cte_where_element|join("\n\t\tAND ")) -%}
        {%- do match_duplicate_cte_table_element.append("\t) WHERE CNT > 1") -%}
        {%- do match_duplicate_cte_table_element.append(")") -%}

        {%- do match_duplicate_cte_table_lst.append(match_duplicate_cte_table_element|join("\n")) -%}
    {%- endfor -%}

    {# Summary auto rule #}
    {%- set match_duplicate_summary_select_statement = match_duplicate_summary_select_element|join(", ")%}

    {%- set match_summary_auto_table_element = [] -%}
    {%- set match_summary_mini_select_table_element = ["\tSELECT "~match_duplicate_summary_select_statement~"\n\tFROM "~dupno_tbl~" WHERE 1=0"] -%}

    {%- for i in range(auto_rule_apply|length)-%}
        {%- do match_summary_mini_select_table_element.append("\tSELECT "~match_duplicate_summary_select_statement~"\n\tFROM CTE_AUTO_"~auto_rule_apply[i].get('name')) -%}
    {%- endfor -%}

    {%- do match_summary_auto_table_element.append("CTE_AUTO_SUM AS (") -%}
    {%- do match_summary_auto_table_element.append(match_summary_mini_select_table_element|join("\n\tUNION ALL\n")) -%}
    {%- do match_summary_auto_table_element.append(")") -%}
    
    {%- do match_duplicate_cte_table_lst.append(match_summary_auto_table_element|join("\n")) -%}

    {# Summary manual rule #}
    {%- set match_duplicate_summary_select_statement = match_duplicate_summary_select_element|join(", ")%}

    {%- set match_summary_manual_table_element = [] -%}
    {%- set match_summary_mini_select_table_element = ["\tSELECT "~match_duplicate_summary_select_statement~"\n\tFROM "~dupno_tbl~" WHERE 1=0"] -%}

    {%- for i in range(manual_rule_apply|length)-%}
        {%- do match_summary_mini_select_table_element.append("\tSELECT "~match_duplicate_summary_select_statement~"\n\tFROM CTE_MANUAL_"~manual_rule_apply[i].get('name')) -%}
    {%- endfor -%}

    {%- do match_summary_manual_table_element.append("CTE_MANUAL_SUM AS (") -%}
    {%- do match_summary_manual_table_element.append(match_summary_mini_select_table_element|join("\n\tUNION ALL\n")) -%}
    {%- do match_summary_manual_table_element.append(")") -%}
    
    {%- do match_duplicate_cte_table_lst.append(match_summary_manual_table_element|join("\n")) -%}

    {# Duplicate auto rule #}
    {%- set match_auto_duplicate_table_element = [] -%}
    {%- set match_auto_duplicate_select_element = [pk_key,"L_"~cob_col,'RULE_CODE'] + match_column_lst %}


    {%- do match_auto_duplicate_select_element.append("COUNT("~pk_key~") OVER(PARTITION BY RULE_CODE, "~match_column_lst|join(", ")~") AS ELEMENT_CNT") -%}
    
    {%- set match_duplicate_hash_element = ["RULE_CODE"] %}
    {%- for i in match_column_lst -%}
        {%- do match_duplicate_hash_element.append("NVL("~i~",'000000000')") -%}
    {%- endfor -%} 
    
    {%- do match_auto_duplicate_select_element.append(ktl_mdm_match_duplicate_hash_statement(match_duplicate_hash_element|join(" || "))~" AS DUPLICATE_GROUP") -%}
    
    {%- do match_auto_duplicate_table_element.append("CTE_AUTO_DUPLICATE AS (") -%}

    {%- do match_auto_duplicate_table_element.append("\tSELECT") -%}
    {%- do match_auto_duplicate_table_element.append("\t"~match_auto_duplicate_select_element|join(",\n\t")) -%}
    {%- do match_auto_duplicate_table_element.append("\tFROM CTE_AUTO_SUM") -%}
    {%- do match_auto_duplicate_table_element.append(")") -%}

    {%- do match_duplicate_cte_table_lst.append(match_auto_duplicate_table_element|join("\n")) -%}


    {# Duplicate manual rule #}
    {%- set match_manual_duplicate_table_element = [] -%}
    {%- set match_manual_duplicate_select_element = [pk_key,"L_"~cob_col,'RULE_CODE'] + match_column_lst %}


    {%- do match_manual_duplicate_select_element.append("COUNT("~pk_key~") OVER(PARTITION BY RULE_CODE, "~match_column_lst|join(", ")~") AS ELEMENT_CNT") -%}
    
    {%- set match_duplicate_hash_element = ["RULE_CODE"] %}
    {%- for i in match_column_lst -%}
        {%- do match_duplicate_hash_element.append("NVL("~i~",'000000000')") -%}
    {%- endfor -%} 
    
    {%- do match_manual_duplicate_select_element.append(ktl_mdm_match_duplicate_hash_statement(match_duplicate_hash_element|join(" || "))~" AS DUPLICATE_GROUP") -%}
    
    {%- do match_manual_duplicate_table_element.append("CTE_MANUAL_DUPLICATE AS (") -%}

    {%- do match_manual_duplicate_table_element.append("\tSELECT") -%}
    {%- do match_manual_duplicate_table_element.append("\t"~match_manual_duplicate_select_element|join(",\n\t")) -%}
    {%- do match_manual_duplicate_table_element.append("\tFROM CTE_MANUAL_SUM") -%}
    {%- do match_manual_duplicate_table_element.append(")") -%}

    {%- do match_duplicate_cte_table_lst.append(match_manual_duplicate_table_element|join("\n")) -%}


    {# Main select #}
    {## General info  #}
    {%- set match_duplicate_main_select_element = [] -%}
    {%- do match_duplicate_main_select_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do match_duplicate_main_select_element.append("'"~source_system~"'"~" AS SOURCE_SYSTEM") -%}
    {%- do match_duplicate_main_select_element.append(cob_value~" AS "~cob_col) -%}

    {%- do match_duplicate_main_select_element.append("CASE WHEN MANUAL_TBL."~pk_key~" IS NOT NULL THEN MANUAL_TBL.L_"~cob_col~" ELSE AUTO_TBL.L_"~cob_col~" END AS L_"~cob_col) -%}
    {%- do match_duplicate_main_select_element.append("CASE WHEN MANUAL_TBL."~pk_key~" IS NOT NULL THEN MANUAL_TBL."~pk_key~" ELSE AUTO_TBL."~pk_key~" END AS "~pk_key) -%}
    
    {%- do match_duplicate_main_select_element.append("CASE WHEN MANUAL_TBL."~pk_key~" IS NOT NULL THEN 1 ELSE 0 END HAS_MANUAL_MATCH") -%}
    {%- do match_duplicate_main_select_element.append("MANUAL_TBL.RULE_CODE AS MANUAL_RULE_CODE") -%}

    {%- do match_duplicate_main_select_element.append("CASE WHEN AUTO_TBL."~pk_key~" IS NOT NULL THEN 1 ELSE 0 END HAS_AUTO_MATCH") -%}
    {%- do match_duplicate_main_select_element.append("AUTO_TBL.RULE_CODE AS AUTO_RULE_CODE") -%}
    
    {## Manual_tbl info  #}
    {%- for i in match_column_lst -%}
        {%- do match_duplicate_main_select_element.append("MANUAL_TBL."~i~" AS MANUAL_"~i) -%}
    {%- endfor -%}

    {%- do match_duplicate_main_select_element.append("MANUAL_TBL.ELEMENT_CNT AS MANUAL_ELEMENT_CNT") -%}
    {%- do match_duplicate_main_select_element.append("MANUAL_TBL.DUPLICATE_GROUP AS MANUAL_DUPLICATE_GROUP") -%}

    {## Auto_tbl info  #}
    {%- for i in match_column_lst -%}
        {%- do match_duplicate_main_select_element.append("AUTO_TBL."~i~" AS AUTO_"~i) -%}
    {%- endfor -%}

    {%- do match_duplicate_main_select_element.append("AUTO_TBL.ELEMENT_CNT AS AUTO_ELEMENT_CNT") -%}
    {%- do match_duplicate_main_select_element.append("AUTO_TBL.DUPLICATE_GROUP AS AUTO_DUPLICATE_GROUP") -%}
    

    {%- set match_duplicate_main_element = [] -%}
    {%- do match_duplicate_main_element.append("SELECT") -%}
    {%- do match_duplicate_main_element.append(match_duplicate_main_select_element|join(",\n")) -%}
    {%- do match_duplicate_main_element.append("FROM CTE_MANUAL_DUPLICATE MANUAL_TBL") -%}
    {%- do match_duplicate_main_element.append("FULL OUTER JOIN CTE_AUTO_DUPLICATE AUTO_TBL") -%}
    {%- do match_duplicate_main_element.append("ON MANUAL_TBL."~pk_key~" = AUTO_TBL."~pk_key~"") -%}
    
    {{ return("WITH "~match_duplicate_cte_table_lst|join(",\n\n") ~ "\n\n" ~ match_duplicate_main_element|join("\n")) }}
{%- endmacro -%}


{%- macro ktl_mdm_match_duplicate_hash_statement(item_statement) -%}
    {{ return(adapter.dispatch('ktl_mdm_match_duplicate_hash_statement')(item_statement)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_match_duplicate_hash_statement(item_statement) -%}
    {{ return("STANDARD_HASH("~item_statement~", 'SHA256')") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_match_duplicate_hash_statement(item_statement) -%}
    {{ return("SHA2("~item_statement~", 256)") }}
{%- endmacro -%}