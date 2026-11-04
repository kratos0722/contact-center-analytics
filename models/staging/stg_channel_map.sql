-- depends_on: {{ ref('map_channel') }}
with source as (
    select * from {{ source('raw', 'map_channel') }}
)

select
    cast(client_id as varchar)         as client_id,
    cast(raw_channel as varchar)       as raw_channel,
    cast(canonical_channel as varchar) as canonical_channel
from source
