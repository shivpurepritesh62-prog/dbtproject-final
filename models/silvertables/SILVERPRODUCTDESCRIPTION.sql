{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('ProductDescription','PRODUCTDESCRIPTION')}} "
    )
}}

select {{get_cleanse_fields('BRONZE','PRODUCTDESCRIPTION')}},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','PRODUCTDESCRIPTION')}}