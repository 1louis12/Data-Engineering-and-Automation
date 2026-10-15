-- Grain : une ligne par région et par jour.
-- Énergie (GWh) = puissance moyenne sur 30 min (MW) x 0,5 h / 1000.
select
    date_locale                                  as jour,
    code_insee_region,
    region,

    sum(consommation_mw) * 0.5 / 1000            as consommation_gwh,
    sum(production_totale_mw) * 0.5 / 1000       as production_gwh,
    sum(production_renouvelable_mw) * 0.5 / 1000 as production_renouvelable_gwh,
    sum(thermique_mw)   * 0.5 / 1000             as thermique_gwh,
    sum(nucleaire_mw)   * 0.5 / 1000             as nucleaire_gwh,
    sum(eolien_mw)      * 0.5 / 1000             as eolien_gwh,
    sum(solaire_mw)     * 0.5 / 1000             as solaire_gwh,
    sum(hydraulique_mw) * 0.5 / 1000             as hydraulique_gwh,
    sum(bioenergies_mw) * 0.5 / 1000             as bioenergies_gwh,

    min(consommation_mw) as consommation_min_mw,
    max(consommation_mw) as consommation_max_mw,
    avg(consommation_mw) as consommation_moy_mw,

    count(*)             as nb_mesures   -- 48 pour un jour complet (46/50 aux changements d'heure)

from {{ ref('int_eco2mix_production_intermediate') }}
group by all
