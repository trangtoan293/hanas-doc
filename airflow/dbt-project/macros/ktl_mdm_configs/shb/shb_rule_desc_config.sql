{%- macro shb_rule_desc_config_yml() -%}
{%- set yml -%}
name: shb
version: '1.0.0'

cleansing:
  - code: CL1
    description: 'Standardize QUOC_TICH via mdm_catalog_category: map to standard quoc_tich value; keep original if not mapped'
    rule_template: cleantp_replace_category
    catalog_condition: landing.mdm_catalog_category
    column_condition: 'QUOC_TICH:quoc_tich'

  - code: CL2
    description: 'Standardize LOAI_GTTT via mdm_catalog_category: map to standard loai_gttt value; keep original if not mapped'
    rule_template: cleantp_replace_category
    catalog_condition: landing.mdm_catalog_category
    column_condition: 'LOAI_GTTT:loai_gttt'

  - code: CL3
    description: 'Remove special characters from NOI_CAP_GTTT (keep letters and safe punctuation: _ -,.;)'
    rule_template: cleantp_remove_pattern
    character: '[^A-Za-z_.,;& -]'

  - code: CL4
    description: 'Convert PASS_E_DT, PASS_I_DT, D_O_B to date MM/dd/yyyy, set to null if invalid format'
    rule_template: cleantp_format_datetime
    from_str_format: 'MM/dd/yyyy'

  - code: CL5
    description: 'Remove non-digits from MOBILE, RES_PH_NO_1, RES_PH_NO_2'
    rule_template: cleantp_remove_pattern
    character: '[^0-9]'

validate:
  - code: V1
    description: 'PASS_E_DT must be convertible to date format MM/dd/yyyy (mark invalid if conversion results in NULL)'
    rule_template: check_date_conversion
    date_format: 'MM/dd/yyyy'
    warning_null: YES
    validate_original: YES
  - code: V2
    description: 'MOBILE must contain only digits (no special characters)'
    rule_template: validatetp_regex_not_like
    regex_pattern: '^[0-9]+$'
    warning_null: NO
    validate_original: YES
  - code: V3
    description: 'Phone length/format: if starts with 0 then 10 digits; if starts with [35789] then 9 digits (after cleansing)'
    rule_template: validatetp_regex_not_like
    regex_pattern: '^(0[0-9]{9}|[35789][0-9]{8})$'
    warning_null: NO
  - code: V4
    description: 'PASS_NO length depends on standardized LOAI_GTTT: CCCD = 12 digits; CMT = 9 or 12 digits; HO CHIEU no restriction'
    rule_template: validatetp_pass_no_by_loai_gttt
    warning_null: NO
  - code: V5
    description: 'LOAI_GTTT must belong to allowed set per mdm_catalog_category loai_gttt (values not in the catalog are invalid)'
    rule_template: check_invalid_category
    catalog_condition: landing.mdm_catalog_category
    column_condition: 'LOAI_GTTT:loai_gttt'
    warning_null: NO
  - code: V6
    description: 'For CCCD/THE CAN CUOC, PASS_E_DT must equal PASS_I_DT + 15 years'
    rule_template: check_active_datetime_legal_id
    condition: '15:0'
    column_condition: PASS_I_DT
  - code: V7
    description: 'PASS_I_DT must be after D_O_B and not after CIF open date from source table'
    rule_template: check_legal_id_range_datetime_with_open_date
    column_condition: "D_O_B"
  - code: V8
    description: 'QUOC_TICH must not be in special-control list per mdm_catalog_category where category_type = kiem_soat'
    rule_template: check_invalid_category
    catalog_condition: landing.mdm_catalog_category
    column_condition: 'QUOC_TICH:kiem_soat'
    warning_null: NO

match:
  - code: M1
    description: 'Mark matching CIF_NOs with duplicate LOAI_GTTT and PASS_NO'
    match_columns:
      - LOAI_GTTT
      - PASS_NO
  - code: M2
    description: 'Mark matching CIF_NOs with duplicate F_NAME, M_NAME, L_NAME, D_O_B, SEX_CD for individual customers'
    match_columns:
      - F_NAME
      - M_NAME
      - L_NAME
      - D_O_B
      - SEX_CD
    customer_type_filter: 'I'

{%- endset -%}
{%- set model = fromyaml(yml) -%}
{{ return(model) }}
{%- endmacro -%}
