{{ config(materialized='view') }}

select
    date_day,
    ad_id,
    campaign_id,
    'sa360' as platform_channel,
    
    -- Metrics
    cost_micros / 1000000 as spend,
    impressions,
    clicks,
    visits as landing_page_views,
    client_account_conversions as conversions
    
from {{ source('sa360_brand_msn', 'ad_device_report') }}