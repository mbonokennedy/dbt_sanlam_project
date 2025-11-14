{{ config(
    materialized='incremental',
    unique_key='date_campaign_key',
    description='A daily, campaign-level fact table uniting all ad platform metrics.',
    on_schema_change='fail'
) }}

-- 1. Union all Staging Fact Models (Daily, Campaign-Level Metrics)
with all_platform_stats as (
    select * from {{ ref('stg_tiktok_ad_report_daily') }}
    union all
    select * from {{ ref('stg_meta_basic_ad_report_daily') }}
    union all
    select * from {{ ref('stg_google_ad_stats_daily') }}
    -- Add DV360, SA360 etc. here
),

-- 2. Join Campaign Metadata and GA4 data
joined_data as (
    select
        aps.date_day,
        aps.platform_channel,
        aps.campaign_id,
        
        -- Metrics (use Zeros for NULLs for consistent aggregation)
        coalesce(aps.spend, 0) as spend,
        coalesce(aps.impressions, 0) as impressions,
        coalesce(aps.clicks, 0) as clicks,
        coalesce(aps.conversions, 0) as conversions,
        coalesce(aps.engagements, 0) as engagements,
        coalesce(aps.reach, 0) as reach,
        
        -- Foreign Key Joins
        dim_c.campaign_key,
        
        -- GA4 Metrics (joined via camp_ref)
        coalesce(ga4_pv.page_views, 0) as ga4_page_views,
        coalesce(ga4_l.total_leads, 0) as ga4_total_leads,
        
        -- Primary Key
        {{ dbt_utils.surrogate_key(['aps.date_day', 'aps.campaign_id', 'aps.platform_channel']) }} as date_campaign_key

    from all_platform_stats aps
    left join {{ ref('dim_campaign') }} dim_c
        on {{ dbt_utils.surrogate_key(['aps.campaign_id', 'aps.platform_channel']) }} = dim_c.campaign_key
    
    -- GA4 joins use the common camp_ref, which is on the dim_campaign
    left join {{ ref('stg_ga4_pageviews_daily') }} ga4_pv
        on aps.date_day = ga4_pv.date_day and dim_c.camp_ref = ga4_pv.camp_ref

    left join {{ ref('stg_ga4_leads_daily') }} ga4_l
        on aps.date_day = ga4_l.date_day and dim_c.camp_ref = ga4_l.camp_ref
    
    {% if is_incremental() %}
    -- Incremental filter for better performance
    where aps.date_day >= date_trunc('day', dateadd('day', -7, current_date()))
    {% endif %}
)

select * from joined_data