{%- macro spark__drop_relation(relation) -%}
  {%- set sql -%}
    DROP TABLE IF EXISTS {{ relation }}
  {%- endset -%}
  {%- do run_query(sql) -%}
{%- endmacro -%}
