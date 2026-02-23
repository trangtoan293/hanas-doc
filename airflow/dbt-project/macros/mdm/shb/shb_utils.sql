{%- macro shb_digits_only(expr) -%}
    CASE WHEN {{ expr }} IS NULL OR UPPER(CAST({{ expr }} AS {{ ktl_mdm_utils_types_string(255) }})) = 'NULL'
         THEN NULL
         ELSE REGEXP_REPLACE(CAST({{ expr }} AS {{ ktl_mdm_utils_types_string(255) }}), '[^0-9]', '')
    END
{%- endmacro -%}

{%- macro shb_to_date_mmddyyyy(expr) -%}
    CASE 
        WHEN {{ expr }} IS NULL THEN NULL
        WHEN REGEXP_LIKE(CAST({{ expr }} AS {{ ktl_mdm_utils_types_string(255) }}), '^[0-9]{2}/[0-9]{2}/[0-9]{4}')
            THEN TO_DATE(SUBSTR(CAST({{ expr }} AS {{ ktl_mdm_utils_types_string(255) }}),1,10), 'MM/dd/yyyy')
        ELSE NULL
    END
{%- endmacro -%}

{%- macro shb_letters_space_replace(expr) -%}
    REGEXP_REPLACE(COALESCE(CAST({{ expr }} AS {{ ktl_mdm_utils_types_string(255) }}), ''), '[^A-Za-z \-\.,;]', ' ')
{%- endmacro -%}
