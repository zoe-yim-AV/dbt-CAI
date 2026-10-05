with

source as (

    select 
    
    MID, 
    BRAND,
    ACTIVE

     from {{ ref('raw_brand_mapping') }}

),

renamed as (

    select

        ----------  ids
        mid as m_id,
        brand,
        active,


    from source


)

select * from renamed
