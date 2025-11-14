{{ config(materialized='view') }}

with pageviews as (
    select
        date_day, -- assuming date is cleaned/cast in a pre-staged table or a CTE not shown
        regexp_substr(page_location, 'camp=([^&]+)', 1, 1, '', 1) as camp_ref,
        
        sum(case when event_name = 'page_view' then 1 else 0 end) as page_views,
        sum(case when engagement_time_msec > 10000 then 1 else 0 end) as engaged_page_views,
        count(distinct user_pseudo_id) as users,
        sum(engagement_time_msec) / 60000 as mins_engaged
        
    from {{ source('ga4', 'events') }}
    where event_name in ('page_view', 'session_start')
    group by 1, 2
)

select * from pageviews
where camp_ref is not null