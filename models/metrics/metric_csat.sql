-- Shared definition: CUSTOMER SATISFACTION (CSAT).
-- csat_avg      = mean survey score (1-5).
-- csat_pct_satisfied = top-box rate = share of responses scoring 4 or 5.
-- GRAIN: client x survey_date.

select
    client_id,
    survey_date,
    cast(count(*) as integer)                        as responses,
    cast(avg(csat_score) as double)                  as csat_avg,
    cast(count(*) filter (where is_satisfied) as integer) as satisfied_responses,
    cast(
        count(*) filter (where is_satisfied) * 1.0 / nullif(count(*), 0)
        as double
    ) as csat_pct_satisfied
from {{ ref('fct_csat') }}
group by 1, 2
