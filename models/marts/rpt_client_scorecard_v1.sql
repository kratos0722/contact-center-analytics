-- Versioned model (v1). See rpt_client_scorecard in _rpt.yml.
-- GRAIN: one row per client.
--
-- v1 is the ORIGINAL contract clients' dashboards were built against. It is
-- kept alive unchanged so existing consumers keep working while they migrate
-- to v2 (which renames/adds columns - a breaking change).

with contacts as (
    select
        client_id,
        cast(count(*) as bigint)                              as total_contacts,
        cast(count(*) filter (where is_resolved) as bigint)   as resolved_contacts,
        cast(
            sum(handle_seconds) filter (where is_answered) * 1.0
            / nullif(count(*) filter (where is_answered), 0)
            as double
        ) as aht_seconds
    from {{ ref('fct_contacts') }}
    group by 1
),

csat as (
    select
        client_id,
        cast(avg(csat_score) as double) as csat_avg
    from {{ ref('fct_csat') }}
    group by 1
)

select
    cast(c.client_id as varchar)                                       as client_id,
    c.total_contacts,
    c.resolved_contacts,
    cast(c.resolved_contacts * 1.0 / nullif(c.total_contacts, 0) as double) as resolution_rate,
    cast(s.csat_avg as double)                                         as csat_avg,
    cast(c.aht_seconds as double)                                      as aht_seconds
from contacts c
left join csat s on c.client_id = s.client_id
