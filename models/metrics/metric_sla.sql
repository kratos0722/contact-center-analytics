-- Shared definition: SERVICE LEVEL (SLA attainment).
-- service_level = contacts answered within the queue's SLA threshold / offered.
-- Offered includes abandoned contacts (they were presented but not answered
-- in time), which is the conservative, client-comparable definition.
-- GRAIN: client x contact_date x canonical_channel.

select
    client_id,
    contact_date,
    canonical_channel,
    cast(count(*) as integer)                                  as offered_contacts,
    cast(count(*) filter (where answered_within_sla) as integer) as answered_within_sla_contacts,
    cast(
        count(*) filter (where answered_within_sla) * 1.0 / nullif(count(*), 0)
        as double
    ) as service_level
from {{ ref('fct_contacts') }}
group by 1, 2, 3
