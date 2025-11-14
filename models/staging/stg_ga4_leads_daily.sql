{{ config(materialized='view') }}

with leads as (
    select
        date_day,
        regexp_substr(page_location, 'camp=([^&]+)', 1, 1, '', 1) as camp_ref,
        
        sum(case when event_name = 'call_me_back' then 1 else 0 end) as call_me_back,
        sum(case when event_name = 'email_submit' then 1 else 0 end) as email_lead,
        sum(case when event_name = 'coach_cellphone_submit' then 1 else 0 end) as coach_cellphone_submit,
        sum(case when event_name = 'coach_email' then 1 else 0 end) as coach_email,
        sum(case when event_name = 'tfsa_online_application' then 1 else 0 end) as tfsa_online_application,
        sum(case when event_name = 'ra_online_application' then 1 else 0 end) as ra_online_application,
        
        -- Aggregate all lead events into a single metric for the fact table
        sum(case when event_name in ('call_me_back', 'email_submit', 'coach_cellphone_submit', 'coach_email', 'tfsa_online_application', 'ra_online_application') then 1 else 0 end) as total_leads

    from {{ source('ga4', 'events') }}
    where event_name in ('call_me_back', 'email_submit', 'coach_cellphone_submit', 'coach_email', 'coach_otp', 'tfsa_online_application', 'ra_online_application')
    group by 1, 2
)

select * from leads
where camp_ref is not null