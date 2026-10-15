-- Grain : un relevé par région et par jour (doublons éventuels éliminés).
-- Colonnes sources supposées : date, code_insee_region, tmin, tmax, tmoy
-- (vérifier avec DESCRIBE si le portail ODRÉ change les noms).
with source as (
    select * from {{ source('raw_temperature', 'temperature-quotidienne-regionale') }}
),

typed as (
    select
        code_insee_region,
        try_cast(date as date)    as jour,
        try_cast(tmin as double)  as tmin_c,
        try_cast(tmax as double)  as tmax_c,
        try_cast(tmoy as double)  as tmoy_c
    from source
)

select *
from typed
where jour is not null
  and code_insee_region is not null
qualify row_number() over (partition by code_insee_region, jour order by jour) = 1
