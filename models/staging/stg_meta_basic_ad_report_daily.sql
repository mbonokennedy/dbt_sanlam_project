{{ config(materialized='view') }}

with raw_ad_data as (
    select
        date_day,
        ad_id,
        campaign_id,
        spend,
        reach,
        impressions
    from {{ source('meta_ads', 'basic_ad') }}
),

ad_actions as (
    select
        date_day,
        ad_id,
        sum(case when action_type like 'page_engagement%' then value else 0 end) as page_engagements,
        sum(case when action_type like 'post_engagement%' then value else 0 end) as post_engagements_raw,
        sum(case when action_type like 'post_reaction%' then value else 0 end) as post_reactions,
        sum(case when action_type like 'video_view%' then value else 0 end) as video_views,
        sum(case when action_type like 'link_click%' then value else 0 end) as clicks,
        sum(case when action_type like 'landing_page_view%' then value else 0 end) as landing_page_views,
        sum(case when action_type like 'onsite_conversion%' then value else 0 end) as onsite_conversions,
        sum(case when action_type like 'offsite_conversion%' then value else 0 end) as offsite_conversions,
        sum(case when action_type like 'comment%' then value else 0 end) as comments,
        sum(case when action_type like 'like%' then value else 0 end) as likes,
        sum(case when action_type like 'lead%' then value else 0 end) as leads
    from {{ source('meta_ads', 'basic_ad_actions') }}
    group by 1, 2
),

joined as (
    select
        r.date_day,
        r.ad_id,
        r.campaign_id,
        'meta' as platform_channel,
        
        -- Metrics
        r.spend,
        r.impressions,
        r.reach,
        coalesce(a.clicks, 0) as clicks,
        coalesce(a.onsite_conversions, 0) + coalesce(a.offsite_conversions, 0) + coalesce(a.leads, 0) as conversions,
        coalesce(a.landing_page_views, 0) as landing_page_views,
        coalesce(a.video_views, 0) as video_views,
        
        -- Engagements (Refactored logic for Meta engagement)
        coalesce(a.page_engagements, 0) + coalesce(a.post_engagements_raw, 0) + coalesce(a.post_reactions, 0) + coalesce(a.comments, 0) + coalesce(a.likes, 0) as engagements

    from raw_ad_data r
    left join ad_actions a
        on r.ad_id = a.ad_id and r.date_day = a.date_day
)

select * from joined