-- Singular test: occupancy must sit in the sane (0, 1] range - handle time
-- should never exceed the agent's logged-in available time.

select
    agent_day_sk,
    occupancy_pct
from {{ ref('fct_agent_day') }}
where occupancy_pct < 0
   or occupancy_pct > 1
