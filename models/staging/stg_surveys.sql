-- depends_on: {{ ref('raw_surveys') }}
with source as (
    select * from {{ source('raw', 'raw_surveys') }}
)

select
    cast(client_id as varchar)    as client_id,
    cast(survey_id as varchar)    as survey_id,
    cast(contact_id as varchar)   as contact_id,
    cast(csat_score as integer)   as csat_score,
    cast(survey_ts as timestamp)  as survey_ts
from source
