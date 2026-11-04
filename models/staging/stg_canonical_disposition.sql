-- depends_on: {{ ref('ref_canonical_disposition') }}
with source as (
    select * from {{ source('raw', 'ref_canonical_disposition') }}
)

select
    cast(canonical_disposition as varchar)   as canonical_disposition,
    cast(is_resolved as boolean)             as is_resolved,
    cast(is_escalation as boolean)           as is_escalation,
    cast(disposition_description as varchar) as disposition_description
from source
