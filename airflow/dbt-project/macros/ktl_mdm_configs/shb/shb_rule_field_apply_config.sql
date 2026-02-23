{%- macro shb_rule_field_apply_config_yml() -%}
{%- set yml -%}
name: shb
version: '1.0.0'

KTL_MDM:
  - product: CORECIF
    source_system:
      - name: SHB
        cleansing:
          - name: CL1
            list_column:
              - QUOC_TICH
          - name: CL2
            list_column:
              - LOAI_GTTT
          - name: CL3
            list_column:
              - NOI_CAP_GTTT
          - name: CL4
            list_column:
              - PASS_E_DT
              - PASS_I_DT
              - D_O_B
          - name: CL5
            list_column:
              - MOBILE
              - RES_PH_NO_1
              - RES_PH_NO_2

        validate:
          - name: V1
            list_column:
              - PASS_E_DT
          - name: V2
            list_column:
              - MOBILE
          - name: V3
            list_column:
              - MOBILE
          - name: V4
            list_column:
              - PASS_NO
          - name: V5
            list_column:
              - LOAI_GTTT
          - name: V6
            list_column:
              - PASS_E_DT
          - name: V7
            list_column:
              - PASS_I_DT
          - name: V8
            list_column:
              - QUOC_TICH

{%- endset -%}
{%- set model = fromyaml(yml) -%}
{{ return(model) }}
{%- endmacro -%}
