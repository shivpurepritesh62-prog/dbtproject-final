{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('Customer','CUSTOMER')}} "
    )
}}

select {{get_cleanse_fields('BRONZE','CUSTOMER')}},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','CUSTOMER')}}