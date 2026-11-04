-- Conformed queue dimension with canonicalised channel.

with queues as (
    select * from {{ ref('stg_queues') }}
),

channel_map as (
    select * from {{ ref('stg_channel_map') }}
)

select
    cast(md5(q.client_id || '|' || q.queue_id) as varchar) as queue_sk,
    cast(q.client_id as varchar)             as client_id,
    cast(q.queue_id as varchar)              as queue_id,
    cast(q.queue_name as varchar)            as queue_name,
    cast(q.channel_raw as varchar)           as channel_raw,
    cast(ch.canonical_channel as varchar)    as canonical_channel,
    cast(q.sla_threshold_seconds as integer) as sla_threshold_seconds
from queues q
left join channel_map ch
    on q.client_id = ch.client_id
   and q.channel_raw = ch.raw_channel
