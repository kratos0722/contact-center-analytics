{#
    Override dbt's default schema-naming behaviour.

    By default dbt concatenates the target schema with any custom `+schema`
    value (e.g. `main` + `raw` -> `main_raw`). For this self-contained demo we
    want the custom schema name used verbatim (seeds land in `raw`), so the
    `sources:` declarations can point at a stable, predictable schema.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
