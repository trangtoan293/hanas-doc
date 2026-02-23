{%- macro ktl_mdm_validate_validate(general_conf,metadata_conf,rule_apply,c_tbl_incre,i_tbl_incre) -%}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}

    WITH cte_table AS (
        SELECT {{pk_key}}, error_column FROM {{i_tbl_incre}}
    ),
    cte_err_table AS (
        SELECT *
        FROM cte_table
        PIVOT ( 
            count(*) for ERROR_COLUMN in (
                {{ ktl_mdm_validate_select_pivot_error_cnt_columns(metadata_conf) }}
            )
        )
    )
    SELECT
        {{ ktl_mdm_validate_select_target_statement(metadata_conf) }}
    FROM {{ c_tbl_incre }} C_TBL
    LEFT JOIN cte_err_table P_TBL ON C_TBL.{{pk_key}} = P_TBL.{{pk_key}}
{%- endmacro -%}

{%- macro ktl_mdm_validate_select_pivot_error_cnt_columns(metadata_conf) -%}
    {%- set result_lst = [] -%}

    {%- for column in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- do result_lst.append("'"~column~"' "~column~"_ERR_CNT") -%}
    {%- endfor -%}
    
    {%- set result_clause = result_lst|join(",\n\t\t") -%}
    {{ return(result_clause) }}
{%- endmacro -%}

{%- macro ktl_mdm_validate_select_target_statement(metadata_conf) -%}
    {%- set result_lst = [ktl_mdm_utils_metadata_get_ldt_statement(ktl_mdm_utils_metadata_get_ldt_col(metadata_conf))] -%}

    {# Metadata column #}
    {%- for column in ktl_mdm_utils_metadata_get_metadata_column_lst(metadata_conf) -%}
        {%- do result_lst.append("C_TBL."~column) -%}
    {%- endfor -%}

    {# CDT column #}
    {%- for column in ktl_mdm_utils_metadata_get_cdt_column_lst(metadata_conf) -%}
        {%- do result_lst.append("C_TBL."~column) -%}
    {%- endfor -%}

    {# ERR_CNT column #}
    {%- set total_err_cnt_element_lst =[] -%}
    {%- for column in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- set coalesce_err_cnt = "COALESCE(P_TBL."~column~"_ERR_CNT,0)" -%}
        {%- do result_lst.append(coalesce_err_cnt~" "~column~"_ERR_CNT") -%}
        {%- do total_err_cnt_element_lst.append(coalesce_err_cnt) -%}
    {%- endfor -%}
    {%- do result_lst.append(total_err_cnt_element_lst|join('+')~" TOTAL_ERR_CNT") -%}
    
    {%- set result_clause = result_lst|join(",\n\t") -%}
    {{ return(result_clause) }}
{%- endmacro -%}