{{ config(
    materialized='table',
    description='A calendar dimension table.'
) }}

-- Uses the dbt_date package. If not installed, replace this with the original date_spine CTE logic.
select
    date_day,
    to_char(date_day, 'YYYYMMDD') as date_id,
    to_char(date_day, 'YYYYMM') as year_month,
    date_part(week, date_day) as week_number,
    date_part(month, date_day) as month_number,
    date_part(year, date_day) as year_number
    
from {{ dbt_date.get_date_dimension('2024-01-01', '2026-01-01') }}