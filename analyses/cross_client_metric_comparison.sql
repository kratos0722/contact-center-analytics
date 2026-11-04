-- Analysis (compiled by `dbt compile`, never materialised by `dbt build`).
--
-- The payoff of the shared-definitions layer: because every client's raw data
-- is conformed onto the same canonical dispositions/channels and every KPI is
-- computed in one place, this query compares two very different client feeds
-- (Acme vs Globex, which use completely different raw labels) apples-to-apples.

with daily as (
    select
        f.client_id,
        f.contact_date,
        count(*)                                        as contacts,
        avg(s.service_level)                            as service_level,
        avg(fcr.fcr_rate)                               as fcr_rate
    from {{ ref('fct_contacts') }} f
    left join {{ ref('metric_sla') }} s
        on f.client_id = s.client_id
       and f.contact_date = s.contact_date
       and f.canonical_channel = s.canonical_channel
    left join {{ ref('metric_fcr') }} fcr
        on f.client_id = fcr.client_id
       and f.contact_date = fcr.contact_date
    group by 1, 2
)

select
    d.client_id,
    cl.client_name,
    d.contact_date,
    d.contacts,
    round(d.service_level, 3) as service_level,
    round(d.fcr_rate, 3)      as fcr_rate
from daily d
join {{ ref('stg_clients') }} cl on d.client_id = cl.client_id
order by d.client_id, d.contact_date
