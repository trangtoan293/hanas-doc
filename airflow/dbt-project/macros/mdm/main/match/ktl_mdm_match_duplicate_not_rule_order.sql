{%- macro ktl_mdm_match_duplicate_not_rule_order(general_conf,metadata_conf,rule_apply,validate_tbl_lastest,ldup_tbl) -%}
    {# General_config #}
    {%- set match_column_cnt = general_conf.get('general_config').get('match_column_cnt') -%}
    {%- set match_group_cnt = general_conf.get('general_config').get('match_group_cnt') -%}

    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}

    {# Main handler #}
    {%- set match_duplicate_not_order_element = [] -%}
    {%- for item in rule_apply.get('matched_by_rules') -%}
        {%- do match_duplicate_not_order_element.append(ktl_mdm_match_duplicate_not_order_element(item,match_column_cnt,match_group_cnt,validate_tbl_lastest,ldup_tbl,pk_key,ldt_col,cob_col)) -%}
    {%- endfor -%}
    {{ return(match_duplicate_not_order_element|join("\n\nUNION ALL\n\n")) }}
{%- endmacro -%}

{%- macro ktl_mdm_match_duplicate_not_order_element(rule_apply_item,match_column_cnt,match_group_cnt,validate_tbl_lastest,ldup_tbl,pk_key,ldt_col,cob_col) -%}
    {%- set select_element_lst = [] -%}

    {# SELECT statement #}
    {## RULE_CODE #}
    {%- do select_element_lst.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do select_element_lst.append(pk_key) -%}
    {%- do select_element_lst.append(cob_col~" AS L_"~cob_col) -%}
    {%- do select_element_lst.append("'"~rule_apply_item.get('name')~"' AS RULE_CODE") -%}    
    
    {## straight MATCH_COLUMN #}
    {%- if rule_apply_item.get('straight') is not none -%}
        {%- for i in range(1,match_column_cnt+1) -%}
            {%- set match_column = rule_apply_item.get('straight').get('match_column_'~i) -%}
            {%- if match_column is not none -%}
                {%- do select_element_lst.append("TBL."~match_column~" AS MATCH_COLUMN_"~i) -%}
            {%- else -%}
                {%- do select_element_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS MATCH_COLUMN_"~i) -%}
            {%- endif -%}        
        {%- endfor -%}
    {%- else -%}
        {%- for i in range(1,match_column_cnt+1) -%}
            {%- do select_element_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS MATCH_COLUMN_"~i) -%}
        {%- endfor -%}
    {%- endif -%}

    {## cross MATCH_COLUMN #}
    {%- if rule_apply_item.get('cross') is not none -%}
        {%- for i in range(1,match_group_cnt+1) -%}
            {%- set match_group = rule_apply_item.get('cross').get('match_group_'~i) -%}
            {%- if match_group is not none -%}
                {%- do select_element_lst.append("MATCH_GROUP_"~i~" AS MATCH_GROUP_"~i) -%}
            {%- else -%}
                {%- do select_element_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS MATCH_GROUP_"~i) -%}
            {%- endif -%}        
        {%- endfor -%}
    {%- else -%}
        {%- for i in range(1,match_group_cnt+1) -%}
            {%- do select_element_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS MATCH_GROUP_"~i) -%}
        {%- endfor -%}
    {%- endif -%}

    
    {# FROM statement #}
    {%- if rule_apply_item.get('cross') is not none -%}
        {## exists cross #}
        {%- set from_element_lst = [] -%}
        {%- set all_match_group = ktl_mdm_match_duplicate_not_order_get_all_cross_group(rule_apply_item,match_group_cnt) -%}
        {%- set combination_lst = ktl_mdm_match_duplicate_not_order_combination_cross_group(all_match_group) -%}
        {%- for combination in combination_lst -%}

            {%- set mini_from_where_exists_lst = [] -%}
            {%- set mini_from_select_lst = [] -%}
            {%- do mini_from_select_lst.append("T."~pk_key) -%}
            {%- do mini_from_select_lst.append("T."~cob_col) -%}

            {%- for i in range(combination|length) -%}
                {%- do mini_from_select_lst.append("T."~combination[i] ~" AS MATCH_GROUP_"~(i+1)) -%}
                {%- do mini_from_where_exists_lst.append("T."~combination[i] ~" = FLDUP_TBL.MATCH_GROUP_"~(i+1)) -%}
            {%- endfor -%}
            
            {%- set mini_from_lst = [] -%}
            {%- do mini_from_lst.append("\tSELECT "~mini_from_select_lst|join(",\n\t")) -%}
            {%- do mini_from_lst.append("\tFROM "~validate_tbl_lastest~" T") -%}
            {%- do mini_from_lst.append("\tWHERE EXISTS (") -%}
            {%- do mini_from_lst.append("\t\tSELECT 1 from "~ldup_tbl~" FLDUP_TBL") -%}
            {%- do mini_from_lst.append("\t\tWHERE "~mini_from_where_exists_lst|join("\n\t\tAND ")) -%}
            {%- do mini_from_lst.append("\t)") -%}
            {%- do from_element_lst.append(mini_from_lst|join("\n")) -%}        
        {%- endfor -%}

        {%- set from_statement = from_element_lst|join("\n\n\tUNION ALL\n\n") -%}

    {%- else -%}
        {## straight only #}
        {%- set from_statement = '\tSELECT * FROM ' ~ validate_tbl_lastest -%}
    {%- endif -%}

    {# WHERE statement #}
    {%- set where_statement = "1=1" -%} 
    {%- if rule_apply_item.get('straight') is not none -%}
        {%- set where_exists_lst = [""] -%}
        {%- do where_exists_lst.append("AND EXISTS (") -%}
        {%- do where_exists_lst.append("\tSELECT 1 FROM "~ldup_tbl~" LD_TBL") -%}

        {## WHERE exists statement #}
        {%- set mini_where_exists_where_element = [] -%}
        {%- for i in range(1,match_column_cnt+1) -%}
            {%- set match_column = rule_apply_item.get('straight').get('match_column_'~i) -%}
            {%- if match_column is not none -%}
                {%- do mini_where_exists_where_element.append("TBL."~match_column~" = LD_TBL.MATCH_COLUMN_"~i) -%}
            {%- endif -%}        
        {%- endfor -%}
        {%- do where_exists_lst.append("\tWHERE "~mini_where_exists_where_element|join("\n\tAND ")) -%}
        {%- do where_exists_lst.append(")") -%}
        {%- set where_statement = where_statement~where_exists_lst|join('\n') -%}
    {%- endif -%}

    {# Generate SQL of match element #}
    {%- set result_lst = [] -%}
    {%- do result_lst.append("SELECT DISTINCT") -%}
    {%- do result_lst.append(select_element_lst|join(",\n")) -%}
    {%- do result_lst.append("FROM (\n"~from_statement~"\n) TBL ") -%}
    {%- do result_lst.append("WHERE "~where_statement) -%}


    {{return (result_lst|join("\n"))}}

{%- endmacro -%}

{%- macro ktl_mdm_match_duplicate_not_order_combination_cross_group(match_group) -%}
    {%- if not match_group -%}
        {{ return([()]) }}
    {%- endif -%}

    {%- set combinations = [] -%}
    {%- set first_group = match_group[0] -%}
    {%- set rest_groups = match_group[1:] -%}
    {%- for item in first_group -%}
        {%- for combo in ktl_mdm_match_duplicate_not_order_combination_cross_group(rest_groups) -%}
            {%- do combinations.append((item,) + combo) -%}
        {%- endfor -%}
    {%- endfor -%}
    {{ return(combinations) }}
{%- endmacro -%}

{%- macro ktl_mdm_match_duplicate_not_order_get_all_cross_group(rule_apply_item,match_group_cnt) -%}
    {%- set group_lst = [] -%}

    {%- for i in range(1,match_group_cnt+1) -%}
        {%- if rule_apply_item.get('cross') is not none -%}
            {%- set match_group = rule_apply_item.get('cross').get('match_group_'~i) -%}
            {%- if match_group is not none -%}
                {%- if match_group|length != 0 -%}
                    {%- do group_lst.append(match_group) -%}
                {%- endif -%}   
            {%- endif -%}  
        {%- endif -%}      
    {%- endfor -%}
    {{ return(group_lst) }}
{%- endmacro -%}