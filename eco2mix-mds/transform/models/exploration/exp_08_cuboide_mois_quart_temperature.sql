-- Étape 4 : requête sur le schéma en étoile -> cuboïde (mois, quart, intervalle de température).
-- Le taux de couverture est recalculé à partir des sommes, jamais en moyennant des pourcentages.
-- Pour ajouter les niveaux "tous quarts" / "toutes températures" : remplacer
-- `group by all` par `group by rollup(t.mois, g.quart, d.intervalle)`.
select
    t.mois,
    g.quart,
    d.intervalle                              as intervalle_temperature,
    count(*)                                  as nb_region_jours,
    sum(f.consommation_gwh)                   as consommation_gwh,
    sum(f.production_gwh)                     as production_gwh,
    100 * sum(f.production_gwh) / nullif(sum(f.consommation_gwh), 0) as tco_total_pct
from {{ ref('fct_energie_journaliere') }} f
join {{ ref('dim_temps') }}        t on f.jour = t.jour
join {{ ref('dim_geographie') }}   g on f.code_insee_region = g.code_insee_region
join {{ ref('dim_temperature') }}  d on f.temperature_key = d.temperature_key
group by all
order by t.mois, g.quart, d.intervalle
