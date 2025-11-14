{{ config(materialized='view') }}

with source as (
    select *
    from {{ source('tiktok_ads', 'ad_report_daily') }}
),

renamed as (
    select
        stat_time_day as date_day,
        campaign_id,
        ad_id,
        'tiktok' as platform_channel,
        
        -- Metrics
        spend as spend,
        reach as reach,
        impressions as impressions,
        clicks as clicks,
        conversion as conversions,
        
        -- Engagement Metrics
        follows,
        comments,
        likes,
        profile_visits,
        shares,
        
        -- Calculated Engagement (Refactored logic)
        follows + comments + likes + profile_visits + shares + clicks as engagements,
        
        -- Video Metrics
        video_play_actions as video_views,
        video_views_p_100,
        video_views_p_25,
        video_views_p_50,
        video_views_p_75
        
    from source
)

select * from renamed