-- GRAIN: one row per CSAT survey response.

with surveys as (
    select * from {{ ref('stg_surveys') }}
),

contacts as (
    select client_id, contact_id, contact_sk, canonical_disposition
    from {{ ref('fct_contacts') }}
)

select
    cast(md5(s.client_id || '|' || s.survey_id) as varchar) as survey_sk,
    cast(s.client_id as varchar)         as client_id,
    cast(s.survey_id as varchar)         as survey_id,
    cast(s.contact_id as varchar)        as contact_id,
    cast(c.contact_sk as varchar)        as contact_sk,
    cast(c.canonical_disposition as varchar) as canonical_disposition,
    cast(s.csat_score as integer)        as csat_score,
    cast(s.csat_score >= 4 as boolean)   as is_satisfied,
    cast(cast(s.survey_ts as date) as date) as survey_date,
    cast(s.survey_ts as timestamp)       as survey_ts
from surveys s
left join contacts c
    on s.client_id = c.client_id
   and s.contact_id = c.contact_id
