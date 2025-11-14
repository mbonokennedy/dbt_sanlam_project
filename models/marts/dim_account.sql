{{ config(
    materialized='table',
    description='A dimension table containing all advertiser accounts.'
) }}

with tiktok_accounts as (
    select
        id as advertiser_id,
        name as account_name,
        'tiktok' as platform_channel
    from {{ source('tiktok_ads', 'advertiser') }}
),

meta_accounts as (
    select
        id as advertiser_id,
        name as account_name,
        'meta' as platform_channel
    from {{ source('meta_ads', 'account_history') }}
    where _fivetran_active = true
),

google_accounts as (
    select
        id as advertiser_id,
        descriptive_name as account_name,
        'google' as platform_channel
    from {{ source('google_ads', 'account_history') }}
    where _fivetran_active = true
),

sa360_accounts as (
    select
        id as advertiser_id,
        descriptive_name as account_name,
        'sa360' as platform_channel
    from {{ source('sa360_brand_msn', 'customer') }}
),

-- DV360 data does not expose a standard account history table, 
-- but we can approximate a dimension from the fact table if needed.
-- For now, we will union the explicit account tables.

unioned_accounts as (
    select * from tiktok_accounts
    union all
    select * from meta_accounts
    union all
    select * from google_accounts
    union all
    select * from sa360_accounts
)

select
    {{ dbt_utils.surrogate_key(['advertiser_id', 'platform_channel']) }} as account_key,
    advertiser_id,
    account_name,
    platform_channel
from unioned_accounts