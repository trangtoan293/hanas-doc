{%- macro shb_metadata_config_yml() -%}
{%- set yml -%}
name: shb
version: '1.0.0'

KTL_MDM:
  - product: CORECIF
    source_system:
      - name: SHB
        columns:
          - name: CIF_NO
            is_pk: true
            is_master_key: true
          - name: CUSTOMER_TYPE
            is_pk: false
            is_master_key: false
          - name: F_NAME
            is_pk: false
            is_master_key: false
          - name: M_NAME
            is_pk: false
            is_master_key: false
          - name: L_NAME
            is_pk: false
            is_master_key: false
          - name: CO_NAME
            is_pk: false
            is_master_key: false
          - name: POS_CD
            is_pk: false
            is_master_key: false
          - name: SEX_CD
            is_pk: false
            is_master_key: false
          - name: D_O_B
            is_pk: false
            is_master_key: false
          - name: PASS_NO
            is_pk: false
            is_master_key: true
          - name: PASS_I_DT
            is_pk: false
            is_master_key: false
          - name: PASS_E_DT
            is_pk: false
            is_master_key: false
          - name: NOI_CAP_GTTT
            is_pk: false
            is_master_key: false
          - name: LOAI_GTTT
            is_pk: false
            is_master_key: true
          - name: SO_THI_THUC
            is_pk: false
            is_master_key: false
          - name: VISA_ISSUE_DT
            is_pk: false
            is_master_key: false
          - name: VISA_EXPIRY_DT
            is_pk: false
            is_master_key: false
          - name: NOI_CAP_THI_THUC
            is_pk: false
            is_master_key: false
          - name: QUOC_TICH
            is_pk: false
            is_master_key: false
          - name: LEG_ST
            is_pk: false
            is_master_key: false
          - name: RES_ADD_1
            is_pk: false
            is_master_key: false
          - name: RES_CNTRY_CD
            is_pk: false
            is_master_key: false
          - name: OFF_ADD_2
            is_pk: false
            is_master_key: false
          - name: OFF_CNTRY_CD
            is_pk: false
            is_master_key: false
          - name: QUOC_GIA_NUOC_NGOAI
            is_pk: false
            is_master_key: false
          - name: RES_PH_NO_1
            is_pk: false
            is_master_key: false
          - name: RES_PH_NO_2
            is_pk: false
            is_master_key: false
          - name: MOBILE
            is_pk: false
            is_master_key: true
          - name: EMAIL_ID1
            is_pk: false
            is_master_key: false
          - name: EMAIL_ID2
            is_pk: false
            is_master_key: false
          - name: dv_ldt
            is_pk: false
            is_master_key: false
            is_ldt: true
          - name: dv_src_ldt
            is_pk: false
            is_master_key: false
            is_cob_date: true
{%- endset -%}
{%- set model = fromyaml(yml) -%}
{{ return(model) }}
{%- endmacro -%}
