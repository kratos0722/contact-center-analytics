-- Singular test: a contact cannot be "answered within SLA" unless it was
-- actually answered. Guards the service-level logic across both clients.

select
    contact_sk
from {{ ref('fct_contacts') }}
where answered_within_sla = true
  and is_answered = false
