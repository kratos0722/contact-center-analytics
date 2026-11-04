-- depends_on: {{ ref('raw_queues') }}
with source as (
    select * from {{ source('raw', 'raw_queues') }}
)

select
    cast(client_id as varchar)             as client_id,
    cast(queue_id as varchar)              as queue_id,
    cast(queue_name as varchar)            as queue_name,
    cast(channel_raw as varchar)           as channel_raw,
    cast(sla_threshold_seconds as integer) as sla_threshold_seconds
from source
