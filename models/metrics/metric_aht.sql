-- Shared definition: AVERAGE HANDLE TIME (AHT).
-- AHT = total handle time (talk + hold + wrap) / number of handled contacts.
-- Computed once here so every client account reports AHT identically.
-- GRAIN: client x contact_date x canonical_channel.

select
    client_id,
    contact_date,
    canonical_channel,
    cast(count(*) filter (where is_answered) as integer) as handled_contacts,
    cast(
        sum(handle_seconds) filter (where is_answered) * 1.0
        / nullif(count(*) filter (where is_answered), 0)
        as double
    ) as aht_seconds
from {{ ref('fct_contacts') }}
group by 1, 2, 3
