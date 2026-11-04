-- depends_on: {{ ref('ref_clients') }}
with source as (
    select * from {{ source('raw', 'ref_clients') }}
)

select
    cast(client_id as varchar)   as client_id,
    cast(client_name as varchar) as client_name,
    cast(industry as varchar)    as industry,
    cast(go_live_date as date)   as go_live_date
from source
