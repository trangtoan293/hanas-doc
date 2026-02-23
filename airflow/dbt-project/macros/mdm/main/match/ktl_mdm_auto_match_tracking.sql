{%- macro ktl_mdm_auto_match_tracking(general_conf,metadata_conf,rule_apply,arrange_tbl) -%}
    {# Metadata_config #}
    {%- set pk_key =  ktl_mdm_utils_metadata_get_pk_col(metadata_conf) -%}
    {%- set ldt_col =  ktl_mdm_utils_metadata_get_ldt_col(metadata_conf) -%}
    {%- set cob_col =  ktl_mdm_utils_metadata_get_cob_col(metadata_conf) -%}
    {%- set cob_value = ktl_mdm_utils_get_cob_value(general_conf) -%}

    {# Main handler #}
    {## Select statement #}
    {%- set match_tracking_select_element = [] -%}
    {%- do match_tracking_select_element.append(ktl_mdm_utils_metadata_get_ldt_statement(ldt_col)) -%}
    {%- do match_tracking_select_element.append("R."~cob_col) -%}
    {%- do match_tracking_select_element.append("R.L_"~cob_col) -%}
    {%- do match_tracking_select_element.append("T."~pk_key) -%}
    {%- do match_tracking_select_element.append("T."~pk_key~"_REF") -%}
    {%- do match_tracking_select_element.append("R.MANUAL_DUPLICATE_GROUP") -%}
    {%- do match_tracking_select_element.append("R.AUTO_DUPLICATE_GROUP") -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- do match_tracking_select_element.append("T."~col~"_TRACK") -%}
    {%- endfor -%}

    {## From mini select statement #}
    {%- set match_tracking_from_mini_select_element = [] -%}
    {%- do match_tracking_from_mini_select_element.append(pk_key) -%}
    {%- do match_tracking_from_mini_select_element.append(ktl_mdm_auto_match_tracking_list_aggregate_pk_ref_statement(pk_key)~" AS "~pk_key~"_REF") -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- do match_tracking_from_mini_select_element.append("MAX(CASE WHEN "~col~"_RN = 1 THEN "~pk_key~"_REF ELSE NULL END) AS "~col~"_TRACK") -%}
    {%- endfor -%}


    {%- set match_tracking_element = [] -%}
    {%- do match_tracking_element.append("SELECT") -%}
    {%- do match_tracking_element.append(match_tracking_select_element|join(",\n")) -%}

    {%- do match_tracking_element.append("FROM (") -%}
    {%- do match_tracking_element.append("\tSELECT "~match_tracking_from_mini_select_element|join(",\n\t")) -%}

    {%- do match_tracking_element.append("\tFROM "~arrange_tbl~"") -%}
    {%- do match_tracking_element.append("\tGROUP BY "~pk_key~"") -%}
    {%- do match_tracking_element.append(") T") -%}
    {%- do match_tracking_element.append("JOIN "~arrange_tbl~" R ON T."~pk_key~" = R."~pk_key~"_REF") -%}

    {{ match_tracking_element|join("\n") }} 

{%- endmacro -%}


{%- macro ktl_mdm_auto_match_tracking_list_aggregate_pk_ref_statement(p_pk_key) -%}
    {{ return(adapter.dispatch('ktl_mdm_auto_match_tracking_list_aggregate_pk_ref_statement')(p_pk_key)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_auto_match_tracking_list_aggregate_pk_ref_statement(p_pk_key) -%}
    {{ return("LISTAGG("~p_pk_key~"_REF, '|') WITHIN GROUP (ORDER BY "~p_pk_key~"_REF)") }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_auto_match_tracking_list_aggregate_pk_ref_statement(p_pk_key) -%}
    {{ return("ARRAY_JOIN(collect_list("~p_pk_key~"_REF),'|')") }}
{%- endmacro -%}