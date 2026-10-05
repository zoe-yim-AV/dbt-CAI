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
        mid as M_ID,
        brand,
        active,
        CASE MID
            WHEN 1406838     THEN 'UNKNOWN'
            WHEN 1417231     THEN 'UNKNOWN'
            WHEN 1417232     THEN 'UNKNOWN'
            WHEN 1421824     THEN 'UNKNOWN'
            WHEN 1422498     THEN 'UNKNOWN'
            WHEN 1426657     THEN 'UNKNOWN'
            WHEN 1426658     THEN 'UNKNOWN'
            WHEN 1435038     THEN 'UNKNOWN'
            WHEN 1435039     THEN 'UNKNOWN'
            WHEN 1440870     THEN 'Cox Automotive'
            WHEN 1441462     THEN 'UNKNOWN'
            WHEN 1441582     THEN 'UNKNOWN'
            WHEN 1476201     THEN 'UNKNOWN'
            WHEN 1476204     THEN 'UNKNOWN'
            WHEN 1476207     THEN 'Manheim Private Store'
            WHEN 1476236     THEN 'vAuto'
            WHEN 1476326     THEN 'UNKNOWN'
            WHEN 1486109     THEN 'Manheim - Corporate'
            WHEN 1486110     THEN 'Manheim - Regional'
            WHEN 1486111     THEN 'Manheim - East Region'        -- CHILD OF MANHEIM - REGIONAL
            WHEN 1486113     THEN 'Manheim - Central Region'     -- CHILD OF MANHEIM - REGIONAL
            WHEN 1486115     THEN 'Manheim - West Region'        -- CHILD OF MANHEIM - REGIONAL
            WHEN 1486116     THEN 'UNKNOWN'
            WHEN 1486255     THEN 'UNKNOWN'
            WHEN 523008045   THEN 'UNKNOWN'
            WHEN 523009249   THEN 'CAM - Cox Automotive Mobility'
            WHEN 523009362   THEN 'Ready Logistics'
            WHEN 523009363   THEN 'Central Dispatch'
            WHEN 523015578   THEN 'UNKNOWN'
            WHEN 523018126   THEN 'DealShield'
            WHEN 523020318   THEN 'UNKNOWN'
            WHEN 523022196   THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS BRAND_LABEL

    from source
    where ACTIVE = 'true'

)

select * from renamed
