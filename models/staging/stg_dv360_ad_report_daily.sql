{{ config(materialized='view') }}

select
    date_day,
    campaign_id,
    creative_id as ad_id, -- Using creative_id as the ad identifier
    'dv360' as platform_channel,
    
    -- Campaign metadata needed for enrichment
    campaign as campaign_name,
    advertiser_id,
    
    -- Metrics
    revenue_adv_currency as spend,
    impressions,
    clicks,
    post_click_conversions + post_view_conversions as conversions,
    starts_video as video_views,
    
    -- Video Quartiles
    first_quartile_views_video as video_views_p_25,
    midpoint_views_video as video_views_p_50,
    third_quartile_views_video as video_views_p_75,
    complete_views_video as video_views_p_100

from {{ source('dv360', 'standard_all') }}