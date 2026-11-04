-- Shared definition: FIRST CONTACT RESOLUTION (FCR).
-- fcr_rate = contacts resolved on first contact / all resolved contacts.
-- A contact is FCR if it was resolved AND the same customer did not contact
-- the same client again within 7 days (see int_contacts_enriched).
-- GRAIN: client x contact_date.

select
    client_id,
    contact_date,
    cast(count(*) filter (where is_resolved) as integer) as resolved_contacts,
    cast(count(*) filter (where is_fcr) as integer)      as fcr_contacts,
    cast(
        count(*) filter (where is_fcr) * 1.0
        / nullif(count(*) filter (where is_resolved), 0)
        as double
    ) as fcr_rate
from {{ ref('fct_contacts') }}
group by 1, 2
