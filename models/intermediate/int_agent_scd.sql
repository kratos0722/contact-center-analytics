{{ config(materialized='ephemeral') }}

-- Build a Slowly Changing Dimension (type 2) from the agent version feed.
-- Each raw row is a point-in-time version keyed by effective_date; we derive
-- valid_from / valid_to / is_current and a version surrogate key.

with versions as (
    select
        client_id,
        agent_id,
        agent_name,
        team,
        site,
        employment_type,
        effective_date as valid_from
    from {{ ref('stg_agents') }}
),

bounded as (
    select
        *,
        lead(valid_from) over (
            partition by client_id, agent_id
            order by valid_from
        ) as next_valid_from
    from versions
)

select
    md5(client_id || '|' || agent_id || '|' || cast(valid_from as varchar)) as agent_sk,
    client_id,
    agent_id,
    agent_name,
    team,
    site,
    employment_type,
    valid_from,
    coalesce(next_valid_from - 1, date '9999-12-31') as valid_to,
    (next_valid_from is null)                                    as is_current
from bounded
