-- Conformed agent dimension, modelled as Slowly Changing Dimension type 2.
-- One row per agent *version*; join on contact_date between valid_from/valid_to
-- to attribute each contact to the attributes that were true at the time.

select
    cast(agent_sk as varchar)         as agent_sk,
    cast(client_id as varchar)        as client_id,
    cast(agent_id as varchar)         as agent_id,
    cast(agent_name as varchar)       as agent_name,
    cast(team as varchar)             as team,
    cast(site as varchar)             as site,
    cast(employment_type as varchar)  as employment_type,
    cast(valid_from as date)          as valid_from,
    cast(valid_to as date)            as valid_to,
    cast(is_current as boolean)       as is_current
from {{ ref('int_agent_scd') }}
