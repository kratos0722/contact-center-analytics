-- Conformed disposition dimension - the canonical "what happened" definition
-- shared across every client. Per-client raw labels resolve to these rows
-- through the mapping seeds.

select
    cast(md5(canonical_disposition) as varchar)  as disposition_sk,
    cast(canonical_disposition as varchar)        as canonical_disposition,
    cast(is_resolved as boolean)                  as is_resolved,
    cast(is_escalation as boolean)                as is_escalation,
    cast(disposition_description as varchar)      as disposition_description
from {{ ref('stg_canonical_disposition') }}
