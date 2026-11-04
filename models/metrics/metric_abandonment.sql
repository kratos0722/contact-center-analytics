-- Shared definition: ABANDONMENT RATE.
-- abandonment_rate = abandoned contacts / offered contacts.
-- Offered = every contact presented (answered or abandoned), matching the SLA
-- model's denominator so abandonment and service level stay consistent and
-- client-comparable.
-- GRAIN: client x contact_date x canonical_channel.

select
    client_id,
    contact_date,
    canonical_channel,
    cast(count(*) as integer)                             as offered_contacts,
    cast(count(*) filter (where is_abandoned) as integer) as abandoned_contacts,
    cast(
        count(*) filter (where is_abandoned) * 1.0 / nullif(count(*), 0)
        as double
    ) as abandonment_rate
from {{ ref('fct_contacts') }}
group by 1, 2, 3
