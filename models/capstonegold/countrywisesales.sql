{{ config(materialized='table') }}

select b.countryregion, sum(a.totaldue) totalamt
from {{ ref("SILVERSALESORDERHEADER") }} as a
join
    {{ ref("silveraddress") }} as b
    on b.addressid = case when a.shiptoaddressid = 1092 then 9 else b.addressid end
group by b.countryregion