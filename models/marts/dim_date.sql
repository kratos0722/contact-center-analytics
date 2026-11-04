-- Conformed date dimension. Built from a DuckDB date spine (no external
-- packages) spanning the demo window.

with spine as (
    select
        cast(unnest(generate_series(
            date '2024-01-01',
            date '2024-01-31',
            interval 1 day
        )) as date) as date_day
)

select
    cast(date_day as date)                                  as date_day,
    cast(extract('isodow' from date_day) as integer)        as day_of_week,
    cast(dayname(date_day) as varchar)                      as day_name,
    cast(extract('week' from date_day) as integer)          as week_of_year,
    cast(extract('day' from date_day) as integer)           as day_of_month,
    cast(extract('month' from date_day) as integer)         as month_number,
    cast(monthname(date_day) as varchar)                    as month_name,
    cast(extract('quarter' from date_day) as integer)       as quarter_number,
    cast(extract('year' from date_day) as integer)          as year_number,
    cast(extract('isodow' from date_day) in (6, 7) as boolean) as is_weekend
from spine
