with

source as (

    -- {# This references seed (CSV) data - try switching to {{ source('ecom', 'raw_customers') }} #}
    select 
        SENDID,
        CAMPAIGNID,
    
    from {{ ref('raw_mc_man_sent') }}

),

renamed as (

    select

        SENDID as SEND_ID,
        CAMPAIGNID as CAMPAIGN_ID,

    from source
)

select * from renamed
