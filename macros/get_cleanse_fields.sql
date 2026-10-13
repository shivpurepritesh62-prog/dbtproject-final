{% macro get_cleanse_fields(schema_name, table_name) %}
 
    {% set query %}
        with t as (
            select
                table_name,
                column_name,
                data_type,
                ordinal_position,
                case
                    when data_type = 'NUMBER'
                        then 'COALESCE(' || column_name || '::int, -1) ' || column_name
                    when data_type like 'TIMESTAMP%'
                        then 'COALESCE(' || column_name || '::timestamp, current_timestamp()) ' || column_name
                    else
                        'COALESCE(' || column_name || ', ''NA'') ' || column_name
                end as dynamic_col
            from {{ target.database }}.information_schema.columns
            where table_schema = upper('{{ schema_name }}')
              and table_name   = upper('{{ table_name }}')
        )
        select
            listagg(dynamic_col, ',') within group (order by ordinal_position) as cleanse_cols
        from t
        group by table_name
    {% endset %}
 
    {% if execute %}
        {% set results = run_query(query) %}
 
        {% if results.rows | length == 0 %}
            {{ exceptions.raise_compiler_error("get_cleanse_fields: no columns found for " ~ schema_name ~ "." ~ table_name) }}
        {% endif %}
 
        {{ return(results.columns[0].values()[0]) }}
    {% else %}
        {{ return('') }}
    {% endif %}
 
{% endmacro %}