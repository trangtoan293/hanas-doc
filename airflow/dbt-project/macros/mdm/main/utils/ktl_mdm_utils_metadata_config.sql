
{%- macro ktl_mdm_utils_metadata_get_all_metadata_config(project_name) -%}
    {{ return(context[project_name|lower+'_metadata_config_yml']()) }}
{%- endmacro -%}

{%- macro ktl_mdm_utils_metadata_get_metadata_config(project_name, product_name, source, default = 'KTL_MDM') -%}
    {%- for item in ktl_mdm_utils_metadata_get_all_metadata_config(project_name)[default] -%}
        {%- if item['product']|lower == product_name|lower -%}
            {%- for element_src in item['source_system'] -%}
                {%- if element_src['name']|lower == source|lower -%}
                    {{ return(element_src) }}
                {%- endif -%}
            {%- endfor -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_metadata_column_lst(metadata_conf, alias = "") -%}
    {%- set result_lst = [] -%}

    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('is_ldt') is not none -%}
            {%- if col.get('is_ldt') == false -%}
                {%-  do result_lst.append(alias~col['name']|upper) -%}
            {%- endif -%}
        {%- else -%}
            {%-  do result_lst.append(alias~col['name']|upper) -%}
        {%- endif -%}
    {%- endfor -%}

    {{ return(result_lst) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf, alias = "") -%}
    {%- set result_lst = [] -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('is_master_key') is not none -%}
            {%- if col.get('is_master_key') == true -%}
                {%- do result_lst.append(alias~col.get('name')|upper) -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(result_lst) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_does_column_have_cdt(metadata_conf,p_col) -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('name')|upper == p_col|upper -%}
            {%- if col.get('has_cdt') is not none -%}
                {%- if col.get('has_cdt') == true -%}
                    {{ return(true) }}
                {%- endif -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(false) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_cdt_column_lst(metadata_conf, alias = "") -%}
    {%- set result_lst = [] -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('has_cdt') is not none -%}
            {%- if col.get('has_cdt') == true -%}
                {%- do result_lst.append(alias~col.get('name')|upper + '_CDT') -%}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
    {{ return(result_lst) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_errcnt_column_lst(metadata_conf, alias = "", with_total_err_cnt = true) -%}
    {%- set result_lst = [] -%}
    {%- for col in ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf) -%}
        {%- do result_lst.append(alias~col|upper + '_ERR_CNT') -%}
    {%- endfor -%}

    {%- if with_total_err_cnt == true -%}
        {%- do result_lst.append(alias~'TOTAL_ERR_CNT') -%}
    {%- endif -%}

    {{ return(result_lst) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_master_with_cdt_errcnt_lst(metadata_conf, alias = "", with_total_err_cnt = true) -%}
    {%- set result_lst = ktl_mdm_utils_metadata_get_master_column_lst(metadata_conf,alias) + ktl_mdm_utils_metadata_get_cdt_column_lst(metadata_conf,alias) + ktl_mdm_utils_metadata_get_errcnt_column_lst(metadata_conf, alias, with_total_err_cnt) -%}
    {{ return(result_lst) }}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_pk_col(metadata_conf,alias = "") -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('is_pk') is not none -%}
            {%- if col.get('is_pk') == true -%}
                {{ return(alias~col.get('name')|upper) }}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_cob_col(metadata_conf,alias = "") -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('is_cob_date') is not none -%}
            {%- if col.get('is_cob_date') == true -%}
                {{ return(alias~col.get('name')|upper) }}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}


{%- macro ktl_mdm_utils_metadata_get_ldt_col(metadata_conf, alias = "") -%}
    {%- for col in metadata_conf['columns'] -%}
        {%- if col.get('is_ldt') is not none -%}
            {%- if col.get('is_ldt') == true -%}
                {{ return(alias~col.get('name')|upper) }}
            {%- endif -%}
        {%- endif -%}
    {%- endfor -%}
{%- endmacro -%}

{%- macro ktl_mdm_utils_metadata_get_ldt_statement(ldt_col) -%}
    {%- if ldt_col is none -%}
        {%- set ldt_col = 'dfmdm_ldt' %}
    {%- endif -%}

    {{ return(adapter.dispatch('ktl_mdm_utils_metadata_get_ldt_statement')(ldt_col)) }}
{%- endmacro -%}

{%- macro oracle__ktl_mdm_utils_metadata_get_ldt_statement(ldt_col) -%}
    {{ return('CAST(SYSTIMESTAMP AS TIMESTAMP(6)) '~ldt_col) }}
{%- endmacro -%}

{%- macro spark__ktl_mdm_utils_metadata_get_ldt_statement(ldt_col) -%}
    {{ return('CURRENT_TIMESTAMP() '~ldt_col) }}
{%- endmacro -%}