{{ config(
    materialized='incremental',
    unique_key='date_campaign_key',
    description='A daily, campaign-level fact table uniting all ad platform metrics.',
    full_refresh=false,
    on_schema_change='fail'
) }}

-- Unioning all staged ad performance models (stg_tiktok_ad_report_daily, stg_meta_basic_ad, etc.)
with all_platform_stats_stg as (
    select * from {{ ref('stg_tiktok_ad_report_daily') }}
    union all 
    select * from {{ ref('stg_meta_basic_ad_report_daily') }}
    -- ... and so on for all other platforms (google, dv360, sa360)
),

-- Joining campaign attributes
campaign_joined as (
    select 
        aps.date_day,
        aps.platform_channel,
        aps.campaign_id,
        aps.advertiser_id, -- Keep for joining dim_account
        
        -- Metrics
        aps.spend,
        aps.impressions,
        aps.clicks,
        aps.conversions,
        aps.reach,
        aps.video_views,
        aps.engagements, -- Coalesced/Calculated engagement from staging layer
        
        -- Add GA4 data via a common camp_ref join, if available
        ga4_pageviews.page_views,
        ga4_leads.total_leads,

        -- Standardized Keys for joining dimensions
        {{ dbt_utils.surrogate_key(['aps.campaign_id', 'aps.platform_channel']) }} as campaign_key,
        {{ dbt_utils.surrogate_key(['aps.advertiser_id', 'aps.platform_channel']) }} as account_key,
        
        -- Unique key for this fact row
        {{ dbt_utils.surrogate_key(['aps.date_day', 'aps.campaign_id', 'aps.platform_channel']) }} as date_campaign_key

    from all_platform_stats_stg aps
    left join {{ ref('stg_ga4_pageviews_daily') }} ga4_pageviews 
        on aps.camp_ref = ga4_pageviews.camp_ref and aps.date_day = ga4_pageviews.date_day
    left join {{ ref('stg_ga4_leads_daily') }} ga4_leads
        on aps.camp_ref = ga4_leads.camp_ref and aps.date_day = ga4_leads.date_day

    {% if is_incremental() %}
    -- Only process new data in incremental runs
    where aps.date_day >= date_trunc('day', dateadd('day', -7, getdate()))
    {% endif %}
)

select * from campaign_joined