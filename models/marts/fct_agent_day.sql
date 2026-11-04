-- GRAIN: one row per agent per staffed day (driven by the shift roster).
-- Combines scheduled/available time with handled-contact volume and handle
-- time to produce the WFM occupancy measure.

with shifts as (
    select * from {{ ref('stg_agent_shifts') }}
),

handled as (
    -- Sourced from the enriched intermediate because it carries the agent
    -- natural key (agent_id); fct_contacts only exposes the SCD-2 agent_sk.
    select
        client_id,
        agent_id,
        contact_date,
        count(*)            as handled_contacts,
        sum(handle_seconds) as handle_seconds
    from {{ ref('int_contacts_enriched') }}
    where agent_id is not null
    group by 1, 2, 3
),

agents as (
    select * from {{ ref('dim_agent') }}
)

select
    cast(md5(s.client_id || '|' || s.agent_id || '|' || cast(s.work_date as varchar)) as varchar) as agent_day_sk,
    cast(s.client_id as varchar)                 as client_id,
    cast(s.agent_id as varchar)                  as agent_id,
    cast(a.agent_sk as varchar)                  as agent_sk,
    cast(s.work_date as date)                    as work_date,
    cast(s.scheduled_seconds as integer)         as scheduled_seconds,
    cast(s.available_seconds as integer)         as available_seconds,
    cast(coalesce(h.handled_contacts, 0) as integer) as handled_contacts,
    cast(coalesce(h.handle_seconds, 0) as integer)   as handle_seconds,
    cast(
        coalesce(h.handle_seconds, 0) * 1.0 / nullif(s.available_seconds, 0)
        as double
    ) as occupancy_pct
from shifts s
left join handled h
    on s.client_id = h.client_id
   and s.agent_id = h.agent_id
   and s.work_date = h.contact_date
left join agents a
    on s.client_id = a.client_id
   and s.agent_id = a.agent_id
   and s.work_date between a.valid_from and a.valid_to
