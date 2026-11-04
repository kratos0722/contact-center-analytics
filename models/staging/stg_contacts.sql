-- depends_on: {{ ref('raw_contacts') }}
with source as (
    select * from {{ source('raw', 'raw_contacts') }}
)

select
    cast(client_id as varchar)              as client_id,
    cast(contact_id as varchar)             as contact_id,
    cast(customer_id as varchar)            as customer_id,
    nullif(cast(agent_id as varchar), '')   as agent_id,
    cast(queue_id as varchar)               as queue_id,
    cast(channel_raw as varchar)            as channel_raw,
    cast(disposition_raw as varchar)        as disposition_raw,
    cast(contact_date as date)              as contact_date,
    cast(offered_ts as timestamp)           as offered_ts,
    cast(nullif(answered_ts, '') as timestamp) as answered_ts,
    cast(nullif(end_ts, '') as timestamp)   as end_ts,
    cast(talk_seconds as integer)           as talk_seconds,
    cast(hold_seconds as integer)           as hold_seconds,
    cast(wrap_seconds as integer)           as wrap_seconds
from source
