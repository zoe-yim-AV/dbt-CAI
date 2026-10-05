with

source as (

    -- {# This references seed (CSV) data - try switching to {{ source('ecom', 'raw_items') }} #}
    select 
            SENDID	
            ,EVENTDATE
            ,EVENTTYPE
            ,CLIENTID
            ,SUBSCRIBERKEY
            ,SUBSCRIBERID
    
    from {{ ref('raw_items') }}

),

renamed as (

    select

        SENDID	
        ,EVENTDATE
        ,EVENTTYPE
        ,CLIENTID
        ,SUBSCRIBERKEY
        ,SUBSCRIBERID
        ,UPPER(EMAILADDRESS) AS EMAILADDRESS
        ,CONCAT(SUBSCRIBERKEY,'-',UPPER(EMAILADDRESS)) AS SUBSCRIBERKEY_EMAIL
        ,ROW_NUMBER() OVER(
            PARTITION BY SENDID, SUBSCRIBERID
            ORDER BY EVENTDATE ASC
        ) AS INITIAL_OPEN

    from source


)

select * from renamed
