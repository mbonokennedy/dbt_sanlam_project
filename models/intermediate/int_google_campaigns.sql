{{ config(materialized='view') }}

with campaign_data as (
    select
        id as campaign_id,
        customer_id as advertiser_id,
        name as campaign_name,
        advertising_channel_type as channel,
        status as campaign_status,
        
        -- Extracted Campaign Metadata (Refactored split logic)
        split(name, '_') as campaign_parts,
        
        case 
            when upper(replace(campaign_parts[3], '"', '')) in ('GSN', 'SA360', 'DEMANDGEN', 'PMAX', 'GOOGLEADS') then 3
            when upper(replace(campaign_parts[4], '"', '')) in ('GSN', 'SA360', 'DEMANDGEN', 'PMAX', 'GOOGLEADS') then 4
            else null
        end as platform_position,
        
        replace(campaign_parts[0], '"', '') as brand,
        replace(campaign_parts[1], '"', '') as business_unit,
        replace(campaign_parts[2], '"', '') as product,
        replace(campaign_parts[platform_position + 1], '"', '') as sub_campaign,
        replace(campaign_parts[platform_position + 2], '"', '') as phase,
        
        case 
            when regexp_like(lower(replace(campaign_parts[array_size(campaign_parts)-1], '"', '')), '^camp[0-9]{6}$')
            then lower(replace(campaign_parts[array_size(campaign_parts)-1], '"', ''))
            else null
        end as camp_ref
        
    from {{ source('google_ads', 'campaign_history') }}
    where _fivetran_active = true
)

select
    *,
    'google' as platform_channel,
    {{ dbt_utils.surrogate_key(['campaign_id', "'google'"]) }} as campaign_key
from campaign_data