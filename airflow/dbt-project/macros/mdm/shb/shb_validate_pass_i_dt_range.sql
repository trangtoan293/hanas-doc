{# Validation macro for V7: PASS_I_DT range validation with open_date from source table #}
{# This macro validates that PASS_I_DT is after D_O_B and not after the CIF open date #}
{%- macro shb_validate_pass_i_dt_range(pass_i_dt_col, d_o_b_col, cif_no_col, source_table) -%}
    {%- set open_date_column = 'OPEN_DATE' -%}
    
    LEFT JOIN (
        SELECT 
            CIF_NO,
            {{ open_date_column }} as CIF_OPEN_DATE
        FROM {{ source_table }}
    ) src_open
    ON {{ cif_no_col }} = src_open.CIF_NO
    WHERE 
        {{ pass_i_dt_col }} IS NOT NULL 
        AND (
            {{ pass_i_dt_col }} < {{ d_o_b_col }}
            OR {{ pass_i_dt_col }} > COALESCE(src_open.CIF_OPEN_DATE, CURRENT_DATE)
        )
{%- endmacro -%}
