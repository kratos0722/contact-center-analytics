-- Versioned model (v2 - the latest). See rpt_client_scorecard in _rpt.yml.
-- GRAIN: one row per client.
--
-- Breaking changes vs v1, all caught by `dbt build` in CI if a consumer's
-- expectations drift:
--   * dropped  resolution_rate
--   * renamed  csat_avg -> csat_mean
--   * added    fcr_contacts, fcr_rate, occupancy_pct

with contacts as (
    select
        client_id,
        cast(count(*) as bigint)                            as total_contacts,
        cast(count(*) filter (where is_resolved) as bigint) as resolved_contacts,
        cast(count(*) filter (where is_fcr) as bigint)      as fcr_contacts,
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
        cast(avg(csat_score) as double) as csat_mean
    from {{ ref('fct_csat') }}
    group by 1
),

occupancy as (
    select
        client_id,
        cast(
            sum(handle_seconds) * 1.0 / nullif(sum(available_seconds), 0)
            as double
        ) as occupancy_pct
    from {{ ref('fct_agent_day') }}
    group by 1
)

select
    cast(c.client_id as varchar)                                        as client_id,
    c.total_contacts,
    c.resolved_contacts,
    c.fcr_contacts,
    cast(c.fcr_contacts * 1.0 / nullif(c.resolved_contacts, 0) as double) as fcr_rate,
    cast(s.csat_mean as double)                                         as csat_mean,
    cast(c.aht_seconds as double)                                       as aht_seconds,
    cast(o.occupancy_pct as double)                                     as occupancy_pct
from contacts c
left join csat s on c.client_id = s.client_id
left join occupancy o on c.client_id = o.client_id
