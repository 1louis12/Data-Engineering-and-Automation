-- Q3. Fenêtre glissante (RANGE) : consommation nationale (GWh) du mois écoulé, chaque jour.
-- Bornes incluses : jour courant + un mois calendaire en arrière.
with national as (
    select jour, sum(consommation_gwh) as consommation_gwh
    from {{ ref('eco2mix_daily_consomation_intermediate') }}
    group by jour
)
select
    jour,
    consommation_gwh,
    sum(consommation_gwh) over (
        order by jour
        range between interval 1 month preceding and current row
    ) as conso_mois_ecoule_gwh
from national
order by jour
