-- Singular test: handle time can never be negative. Any failing row is an
-- upstream data or logic error. Returns offending rows (0 rows = pass).

select
    contact_sk,
    handle_seconds
from {{ ref('fct_contacts') }}
where handle_seconds < 0
