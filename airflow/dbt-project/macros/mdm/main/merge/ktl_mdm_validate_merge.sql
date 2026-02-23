{%- macro ktl_mdm_validate_merge(general_conf, metadata_conf, rule_apply, cleansing_tbl, invalid_tbl, match_tbl) -%}
SELECT *
FROM {{ match_tbl }}
{%- endmacro -%}
