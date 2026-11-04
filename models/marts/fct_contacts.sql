-- GRAIN: one row per customer interaction (contact).
-- Foreign keys resolve to the conformed dimensions; the SCD-2 agent join uses
-- contact_date between valid_from/valid_to so history is attributed correctly.

with enriched as (
    select * from {{ ref('int_contacts_enriched') }}
),

agents as (
    select * from {{ ref('dim_agent') }}
),

queues as (
    select * from {{ ref('dim_queue') }}
),

dispositions as (
    select * from {{ ref('dim_disposition') }}
)

select
    cast(md5(e.client_id || '|' || e.contact_id) as varchar) as contact_sk,
    cast(e.client_id as varchar)              as client_id,
    cast(e.contact_id as varchar)             as contact_id,
    cast(e.customer_id as varchar)            as customer_id,
    cast(e.contact_date as date)              as contact_date,
    cast(a.agent_sk as varchar)               as agent_sk,
    cast(q.queue_sk as varchar)               as queue_sk,
    cast(d.disposition_sk as varchar)         as disposition_sk,
    cast(e.canonical_channel as varchar)      as canonical_channel,
    cast(e.canonical_disposition as varchar)  as canonical_disposition,
    cast(e.offered_ts as timestamp)           as offered_ts,
    cast(e.answered_ts as timestamp)          as answered_ts,
    cast(e.handle_seconds as integer)         as handle_seconds,
    cast(e.wait_seconds as integer)           as wait_seconds,
    cast(e.is_answered as boolean)            as is_answered,
    cast(e.is_abandoned as boolean)           as is_abandoned,
    cast(e.is_resolved as boolean)            as is_resolved,
    cast(e.is_fcr as boolean)                 as is_fcr,
    cast(e.answered_within_sla as boolean)    as answered_within_sla
from enriched e
left join agents a
    on e.client_id = a.client_id
   and e.agent_id = a.agent_id
   and e.contact_date between a.valid_from and a.valid_to
left join queues q
    on e.client_id = q.client_id
   and e.queue_id = q.queue_id
left join dispositions d
    on e.canonical_disposition = d.canonical_disposition
