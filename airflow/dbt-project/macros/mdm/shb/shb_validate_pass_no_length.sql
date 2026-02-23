{# Validation macro for V4: PASS_NO length based on standardized LOAI_GTTT #}
{%- macro shb_validate_pass_no_length(pass_no_col, loai_gttt_col) -%}
    CASE 
        WHEN {{ loai_gttt_col }} = 'CCCD' AND LENGTH({{ pass_no_col }}) != 12 THEN 1
        WHEN {{ loai_gttt_col }} = 'CMT' AND LENGTH({{ pass_no_col }}) NOT IN (9, 12) THEN 1
        WHEN {{ pass_no_col }} IS NULL THEN 1
        ELSE 0
    END
{%- endmacro -%}
