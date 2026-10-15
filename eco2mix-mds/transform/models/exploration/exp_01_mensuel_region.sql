-- Q1. Groupement simple : énergie (GWh) et puissance instantanée min/max/moyenne (MW),
-- par mois et par région. Source demi-horaire : min/max/avg exacts.
select
    date_trunc('month', date_locale)::date   as mois,
    region,
    sum(consommation_mw) * 0.5 / 1000        as consommation_gwh,
    sum(production_totale_mw) * 0.5 / 1000   as production_gwh,
    min(consommation_mw)                     as conso_min_mw,
    max(consommation_mw)                     as conso_max_mw,
    avg(consommation_mw)                     as conso_moy_mw,
    min(production_totale_mw)                as prod_min_mw,
    max(production_totale_mw)                as prod_max_mw,
    avg(production_totale_mw)                as prod_moy_mw
from {{ ref('int_eco2mix_production_intermediate') }}
group by all
order by mois, region
