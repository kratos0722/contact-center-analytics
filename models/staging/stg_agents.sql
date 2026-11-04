-- depends_on: {{ ref('raw_agents') }}
with source as (
    select * from {{ source('raw', 'raw_agents') }}
)

select
    cast(client_id as varchar)       as client_id,
    cast(agent_id as varchar)        as agent_id,
    cast(agent_name as varchar)      as agent_name,
    cast(team as varchar)            as team,
    cast(site as varchar)            as site,
    cast(employment_type as varchar) as employment_type,
    cast(effective_date as date)     as effective_date
from source
