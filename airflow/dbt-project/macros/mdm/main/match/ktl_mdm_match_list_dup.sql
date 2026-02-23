{%- macro ktl_mdm_match_list_dup(general_conf,metadata_conf,rule_apply,validate_tbl_lastest,validate_tbl_incre) -%}
    {# General_config #}
    {%- set match_column_cnt = general_conf.get('general_config').get('match_column_cnt') -%}
    {%- set match_group_cnt = general_conf.get('general_config').get('match_group_cnt') -%}

    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}

    {# Main handler #}
    {%- set match_list_dup_element = [] -%}
    {%- for item in rule_apply.get('matched_by_rules') -%}
        {%- do match_list_dup_element.append(ktl_mdm_match_list_dup_element(item,match_column_cnt,match_group_cnt,validate_tbl_lastest,validate_tbl_incre,pk_key,ldt_col,cob_col)) -%}
    {%- endfor -%}
    {{match_list_dup_element|join("\n\nUNION ALL\n\n")}}
{%- endmacro -%}

{%- macro ktl_mdm_match_list_dup_element(rule_apply_item,match_column_cnt,match_group_cnt,validate_tbl_lastest,validate_tbl_incre,pk_key,ldt_col,cob_col) -%}
    
    {%- set select_element_lst = [] -%}

    {# SELECT statement #}
    {## RULE_CODE #}
    {%- do select_element_lst.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}  
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
        {## exist cross #}
        {%- set from_element_lst = [] -%}
        {%- for i in range(1,match_group_cnt+1) -%}
            {%- set match_group = rule_apply_item.get('cross').get('match_group_'~i) -%}
            {%- if match_group is not none -%}
                {%- for column in match_group -%}
                    {%- set mini_from_lst = ["\tSELECT "] -%}
                    {%- set mini_from_select_lst = ["\tT.*"] -%}

                    {%- for j in range(1,match_group_cnt+1) -%}
                        {%- if i == j -%}
                            {%- do mini_from_select_lst.append("T."~column~" AS MATCH_GROUP_"~j) -%}
                            {%- do mini_from_select_lst.append("'"~column~"' AS TYPE_"~j) -%}
                        {%- else -%}
                            {%- do mini_from_select_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS MATCH_GROUP_"~j) -%}
                            {%- do mini_from_select_lst.append("CAST(NULL AS "~ktl_mdm_utils_types_string(nbyte = 2000)~") AS TYPE_"~j) -%}
                        {%- endif -%}  
                    {%- endfor -%}

                    {%- do mini_from_lst.append(mini_from_select_lst|join(",\n\t")) -%}
                    {%- do mini_from_lst.append("\tFROM "~validate_tbl_lastest~" T") -%}
                    {%- do mini_from_lst.append("\tWHERE T."~column~" IS NOT NULL") -%}
                    {%- do mini_from_lst.append("\tAND EXISTS (SELECT 1 from "~validate_tbl_incre~" I_TBL WHERE T."~column~"=I_TBL."~column~")") -%}
                    {%- do from_element_lst.append(mini_from_lst|join("\n")) -%}
                {%- endfor -%}
            {%- endif -%}        
        {%- endfor -%}

        {%- set from_statement = from_element_lst|join("\n\n\tUNION ALL\n\n") -%}

    {%- else -%}
        {## straight only #}
        {%- set from_statement = '\tSELECT * FROM ' ~ validate_tbl_lastest -%}
    {%- endif -%}

    {# WHERE statement #}
    {%- set where_element_lst = ["1=1"] -%} {# Default WHERE item #}
    {%- if rule_apply_item.get('straight') is not none -%}
        {%- set where_mini_exists_element_lst = [] -%}
        {%- for i in range(1,match_column_cnt+1) -%}
            {%- set match_column = rule_apply_item.get('straight').get('match_column_'~i) -%}
            {%- if match_column is not none -%}
                {%- do where_element_lst.append("TBL."~match_column~" IS NOT NULL") -%}
                {%- do where_mini_exists_element_lst.append("TBL."~match_column~" = I_TBL."~match_column) -%}
            {%- endif -%}        
        {%- endfor -%}
        
        {## EXISTS INCREMENTAL statment #}
        {%- do where_element_lst.append("EXISTS (SELECT 1 from "~validate_tbl_incre~" I_TBL WHERE "~where_mini_exists_element_lst|join(" AND ")~")") -%}
    {%- endif -%}

    {# GROUP BY statement #}
    {%- set groupby_element_lst = [] -%}
    {## straingt MATCH_COLUMN #}
    {%- if rule_apply_item.get('straight') is not none -%}
        {%- for i in range(1,match_column_cnt+1) -%}
            {%- set match_column = rule_apply_item.get('straight').get('match_column_'~i) -%}
            {%- if match_column is not none -%}
                {%- do groupby_element_lst.append("TBL."~match_column) -%}
            {%- endif -%}        
        {%- endfor -%}
    {%- endif -%}
    {## cross MATCH_COLUMN #}
    {%- if rule_apply_item.get('cross') is not none -%}
        {%- for i in range(1,match_group_cnt+1) -%}
            {%- set match_group = rule_apply_item.get('cross').get('match_group_'~i) -%}
            {%- if match_group is not none -%}
                {%- do groupby_element_lst.append("TBL.MATCH_GROUP_"~i) -%}
            {%- endif -%}        
        {%- endfor -%}
    {%- endif -%}

    {# HAVING statement #}
    {%- set having_element_lst = ["COUNT(DISTINCT TBL."~pk_key~") > 1"] -%} {# Default HAVING item #}
    {## exist cross #}
    {%- if rule_apply_item.get('cross') is not none -%}
        {%- for i in range(1,match_group_cnt+1) -%}
            {%- set match_group = rule_apply_item.get('cross').get('match_group_'~i) -%}
            {%- if match_group is not none -%}
                {%- do having_element_lst.append("COUNT(DISTINCT TBL.TYPE_"~i~") > 1") -%}
            {%- endif -%}        
        {%- endfor -%}
    {%- endif -%}
    
    {# Generate SQL of match element #}
    {%- set result_lst = [] -%}
    {%- do result_lst.append("SELECT") -%}
    {%- do result_lst.append(select_element_lst|join(",\n")) -%}
    {%- do result_lst.append("FROM (\n"~from_statement~"\n) TBL ") -%}
    {%- do result_lst.append("WHERE "~where_element_lst|join("\nAND ")) -%}
    {%- do result_lst.append("GROUP BY "~groupby_element_lst|join(", ")) -%}
    {%- do result_lst.append("HAVING "~having_element_lst|join(" AND ")) -%}


    {{return (result_lst|join("\n"))}}

{%- endmacro -%}
