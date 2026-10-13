{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('Product','PRODUCT')}} "
    )
}}

select {{get_cleanse_fields('BRONZE','PRODUCT')}},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','PRODUCT')}}