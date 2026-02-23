{# Additional validation logic for SHB-specific rules #}

{# logic invalid rule for V4: PASS_NO length based on LOAI_GTTT (after standardization) #}
{%- macro invalid_logic_check_pass_no_by_loai_gttt(pass_no_col, loai_gttt_col) -%}
    CASE 
        WHEN {{ loai_gttt_col }} IS NULL OR {{ pass_no_col }} IS NULL THEN 1
        WHEN {{ loai_gttt_col }} = 'CCCD' AND LENGTH({{ pass_no_col }}) != 12 THEN 1
        WHEN {{ loai_gttt_col }} = 'CMT' AND LENGTH({{ pass_no_col }}) NOT IN (9, 12) THEN 1
        ELSE 0
    END
{%- endmacro -%}

{# logic invalid rule for V7: PASS_I_DT between D_O_B and open_date #}
{%- macro invalid_logic_check_pass_i_dt_with_open_date(pass_i_dt_col, d_o_b_col) -%}
    CASE 
        WHEN {{ pass_i_dt_col }} IS NULL THEN 1
        WHEN {{ d_o_b_col }} IS NULL THEN 1
        WHEN {{ pass_i_dt_col }} < {{ d_o_b_col }} THEN 1
        ELSE 0
    END
{%- endmacro -%}
