-- depends_on: {{ ref('map_disposition') }}
with source as (
    select * from {{ source('raw', 'map_disposition') }}
)

select
    cast(client_id as varchar)             as client_id,
    cast(raw_disposition as varchar)       as raw_disposition,
    cast(canonical_disposition as varchar) as canonical_disposition
from source
