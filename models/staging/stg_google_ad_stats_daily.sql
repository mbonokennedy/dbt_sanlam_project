{{ config(materialized='view') }}

with ad_stats as (
    select
        date_day,
        campaign_id,
        ad_id,
        sum(conversions) as conversions,
        sum(interactions) as interactions,
        sum(clicks) as clicks,
        sum(impressions) as impressions,
        sum(video_views) as video_views,
        sum(cost_micros / 1000000) as spend
    from {{ source('google_ads', 'ad_stats') }}
    group by 1, 2, 3
),

video_metrics as (
    select
        date_day,
        campaign_id,
        sum(video_quartile_p_100_rate * video_views) as video_views_p_100,
        sum(video_quartile_p_25_rate * video_views) as video_views_p_25,
        sum(video_quartile_p_50_rate * video_views) as video_views_p_50,
        sum(video_quartile_p_75_rate * video_views) as video_views_p_75,
        sum(engagements) as video_engagements
    from {{ source('google_ads', 'standard_all') }}
    group by 1, 2
),

joined as (
    select
        a.date_day,
        a.ad_id,
        a.campaign_id,
        'google' as platform_channel,

        -- Metrics
        a.spend,
        a.impressions,
        a.clicks,
        a.conversions,
        coalesce(v.video_views, a.video_views) as video_views,
        coalesce(v.video_engagements, a.interactions) as engagements, -- Use interactions as catch-all engagement
        
        -- Video Quartiles (for later aggregation)
        v.video_views_p_25,
        v.video_views_p_50,
        v.video_views_p_75,
        v.video_views_p_100

    from ad_stats a
    left join video_metrics v on a.campaign_id = v.campaign_id and a.date_day = v.date_day
)

select * from joined