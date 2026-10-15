-- Q4. Variation : les 20 plus grands écarts de consommation nationale d'un jour à l'autre.
with national as (
    select jour, sum(consommation_gwh) as consommation_gwh
    from {{ ref('eco2mix_daily_consomation_intermediate') }}
    group by jour
),

avec_veille as (
    select
        jour,
        consommation_gwh,
        lag(consommation_gwh) over (order by jour) as consommation_veille_gwh
    from national
),

ecarts as (
    select
        jour,
        consommation_gwh,
        consommation_veille_gwh,
        consommation_gwh - consommation_veille_gwh      as ecart_gwh,
        abs(consommation_gwh - consommation_veille_gwh) as ecart_abs_gwh
    from avec_veille
    where consommation_veille_gwh is not null
)

select *, dayname(jour) as jour_semaine
from ecarts
order by ecart_abs_gwh desc
limit 20
