-- depends_on: {{ ref('raw_agent_shifts') }}
with source as (
    select * from {{ source('raw', 'raw_agent_shifts') }}
)

select
    cast(client_id as varchar)          as client_id,
    cast(agent_id as varchar)           as agent_id,
    cast(work_date as date)             as work_date,
    cast(scheduled_seconds as integer)  as scheduled_seconds,
    cast(available_seconds as integer)  as available_seconds
from source
