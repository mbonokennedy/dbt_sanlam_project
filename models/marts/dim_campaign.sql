{{ config(
    materialized='table',
    description='A dimension table containing standardized campaign attributes across all platforms.'
) }}

-- Combine intermediate campaign models
with all_campaigns as (
    select * from {{ ref('int_tiktok_campaigns') }}
    union all
    select * from {{ ref('int_meta_campaigns') }}
    union all
    select * from {{ ref('int_google_campaigns') }}
    -- Add other platforms as needed (DV360/SA360)
),

final as (
    select distinct
        campaign_key,
        platform_channel,
        campaign_name,
        campaign_status,
        brand,
        business_unit,
        product,
        sub_campaign,
        phase,
        camp_ref
    from all_campaigns
)

select * from final