{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('Address','ADDRESS')}} "
    )
}}

select {{get_cleanse_fields('BRONZE','ADDRESS')}},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','ADDRESS')}}