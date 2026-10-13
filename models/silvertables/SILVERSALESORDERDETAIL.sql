{{
    config(materialized = 'incremental',
           incremental_strategy = 'merge',
           pre_hook = " {{refresh_bronze_data('SalesOrderDetail','SALESORDERDETAIL')}} "
    )
}}

select {{get_cleanse_fields('BRONZE','SALESORDERDETAIL')}},
       current_timestamp() as ETL_MODIFIEDDATE
from {{ source('bronze','SALESORDERDETAIL')}}