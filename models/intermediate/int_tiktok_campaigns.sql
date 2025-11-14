{{ config(
    materialized='view',
    description='Cleaned and enriched TikTok campaign metadata, including business dimensions'
) }}

with campaign_history as (
    select *
    from {{ source('tiktok_ads', 'campaign_history') }}
    where _fivetran_active = true -- Deduping
),

final as (
    select
        campaign_id,
        advertiser_id,
        campaign_name,
        campaign_type,
        status as campaign_status,
        
        -- Campaign Metadata Extraction (Refactored from the monolithic CTE)
        split(campaign_name, '_') as campaign_parts,
        
        -- Determine platform position dynamically
        case 
            when upper(replace(campaign_parts[3], '"', '')) like 'TIKTOK' then 3
            when upper(replace(campaign_parts[4], '"', '')) like 'TIKTOK' then 4
            else null
        end as platform_position,
        
        replace(campaign_parts[0], '"', '') as brand,
        replace(campaign_parts[1], '"', '') as business_unit,
        replace(campaign_parts[2], '"', '') as product,
        replace(campaign_parts[platform_position + 1], '"', '') as sub_campaign,
        replace(campaign_parts[platform_position + 2], '"', '') as phase,
        
        -- Standard Campaign Reference ID (camp_ref)
        case 
            when regexp_like(lower(replace(campaign_parts[array_size(campaign_parts)-1], '"', '')), '^camp[0-9]{6}$')
            then lower(replace(campaign_parts[array_size(campaign_parts)-1], '"', ''))
            else null
        end as camp_ref,

        -- Standardized Campaign Key
        {{ dbt_utils.surrogate_key(['campaign_id', "'tiktok'"]) }} as campaign_key
        
    from campaign_history
)

select * from final