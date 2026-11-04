{{ config(materialized='ephemeral') }}

-- Silver layer: conform every client's raw interaction onto the shared
-- definitions. This is where the per-client mapping seeds do real work -
-- Acme's "CALLBACK" and Globex's "Follow-up" both become FOLLOW_UP, etc.
-- Derived measures (handle time, wait time, resolution/SLA/FCR flags) are
-- computed once here so every downstream mart and metric agrees.

with contacts as (
    select * from {{ ref('stg_contacts') }}
),

disposition_map as (
    select * from {{ ref('stg_disposition_map') }}
),

channel_map as (
    select * from {{ ref('stg_channel_map') }}
),

canonical_disposition as (
    select * from {{ ref('stg_canonical_disposition') }}
),

queues as (
    select * from {{ ref('stg_queues') }}
),

joined as (
    select
        c.client_id,
        c.contact_id,
        c.customer_id,
        c.agent_id,
        c.queue_id,
        c.contact_date,
        c.offered_ts,
        c.answered_ts,
        ch.canonical_channel,
        dm.canonical_disposition,
        cd.is_resolved,
        cd.is_escalation,
        q.sla_threshold_seconds,
        (c.talk_seconds + c.hold_seconds + c.wrap_seconds) as handle_seconds,
        case
            when c.answered_ts is not null
            then date_diff('second', c.offered_ts, c.answered_ts)
        end as wait_seconds,
        (c.answered_ts is not null) as is_answered,
        (c.answered_ts is null)     as is_abandoned
    from contacts c
    left join disposition_map dm
        on c.client_id = dm.client_id
       and c.disposition_raw = dm.raw_disposition
    left join channel_map ch
        on c.client_id = ch.client_id
       and c.channel_raw = ch.raw_channel
    left join canonical_disposition cd
        on dm.canonical_disposition = cd.canonical_disposition
    left join queues q
        on c.client_id = q.client_id
       and c.queue_id = q.queue_id
),

fcr as (
    select
        *,
        -- next time this same customer contacted this same client
        lead(offered_ts) over (
            partition by client_id, customer_id
            order by offered_ts
        ) as next_contact_ts
    from joined
)

select
    client_id,
    contact_id,
    customer_id,
    agent_id,
    queue_id,
    contact_date,
    offered_ts,
    answered_ts,
    canonical_channel,
    canonical_disposition,
    is_resolved,
    is_escalation,
    sla_threshold_seconds,
    handle_seconds,
    wait_seconds,
    is_answered,
    is_abandoned,
    -- First Contact Resolution: resolved AND the customer did not come back
    -- within a 7-day window.
    (
        is_resolved
        and (
            next_contact_ts is null
            or next_contact_ts > offered_ts + interval 7 day
        )
    ) as is_fcr,
    -- Service level: answered within the queue's SLA threshold.
    (is_answered and wait_seconds <= sla_threshold_seconds) as answered_within_sla
from fcr
