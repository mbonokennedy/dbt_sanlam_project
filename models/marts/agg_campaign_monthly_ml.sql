{{ config(
    materialized='table',
    description='Monthly aggregated campaign performance for analytics, insights, and ML use cases.'
) }}

with monthly_agg as (
    select
        -- Time Dimensions
        to_char(date_day, 'YYYYMM') as year_month,
        
        -- Keys
        fact.campaign_key,
        
        -- Dimensions (from Dim)
        min(dim_c.platform_channel) as platform_channel,
        min(dim_c.campaign_name) as campaign_name,
        min(dim_c.brand) as brand,
        min(dim_c.camp_ref) as camp_ref,
        
        -- Aggregated Metrics (Measures)
        sum(fact.spend) as total_spend_usd,
        sum(fact.impressions) as impression_count,
        sum(fact.clicks) as click_count,
        sum(fact.conversions) as conversion_count,
        sum(fact.ga4_page_views) as ga4_page_view_count,
        sum(fact.ga4_total_leads) as ga4_lead_count,
        
        -- Calculate first active date for age feature
        min(fact.date_day) over (partition by fact.campaign_key) as campaign_start_date

    from {{ ref('fact_campaign_performance_daily') }} fact
    left join {{ ref('dim_campaign') }} dim_c on fact.campaign_key = dim_c.campaign_key
    group by 1, 2
),

feature_engineering as (
    select
        *,
        
        -- Derived Rates
        (click_count / nullif(impression_count, 0)) as ctr_rate,
        (conversion_count / nullif(click_count, 0)) as conversion_rate_click_through,
        (total_spend_usd / nullif(conversion_count, 0)) as cpa_cost_per_acquisition,
        
        -- ML Feature: Lagged Spend
        lag(total_spend_usd, 1) over (partition by campaign_key order by year_month) as spend_usd_lag_1m
        
    from monthly_agg
)

select * from feature_engineering