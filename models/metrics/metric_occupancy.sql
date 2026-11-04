-- Shared definition: WFM OCCUPANCY.
-- occupancy = productive (handle) time / logged-in available time.
-- GRAIN: client x work_date (rolled up from fct_agent_day).

select
    client_id,
    work_date,
    cast(sum(handle_seconds) as bigint)     as handle_seconds,
    cast(sum(available_seconds) as bigint)  as available_seconds,
    cast(
        sum(handle_seconds) * 1.0 / nullif(sum(available_seconds), 0)
        as double
    ) as occupancy_pct
from {{ ref('fct_agent_day') }}
group by 1, 2
