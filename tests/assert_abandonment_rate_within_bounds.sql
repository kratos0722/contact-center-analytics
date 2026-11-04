-- abandonment_rate is a proportion and must fall within [0, 1].
-- Any row outside those bounds indicates a broken definition and fails the build.
select
    client_id,
    contact_date,
    canonical_channel,
    abandonment_rate
from {{ ref('metric_abandonment') }}
where abandonment_rate < 0
   or abandonment_rate > 1
