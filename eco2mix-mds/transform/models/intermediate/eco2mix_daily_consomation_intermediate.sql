SELECT
    date_locale                                  AS jour,
    code_insee_region,
    region,

    SUM(consommation_mw) * 0.5 / 1000            AS consommation_gwh,
    SUM(production_totale_mw) * 0.5 / 1000       AS production_gwh,
    SUM(production_renouvelable_mw) * 0.5 / 1000 AS production_renouvelable_gwh,
    SUM(thermique_mw)    * 0.5 / 1000            AS thermique_gwh,
    SUM(nucleaire_mw)    * 0.5 / 1000            AS nucleaire_gwh,
    SUM(eolien_mw)       * 0.5 / 1000            AS eolien_gwh,
    SUM(solaire_mw)      * 0.5 / 1000            AS solaire_gwh,
    SUM(hydraulique_mw)  * 0.5 / 1000            AS hydraulique_gwh,
    SUM(bioenergies_mw)  * 0.5 / 1000            AS bioenergies_gwh,

    MIN(consommation_mw) AS consommation_min_mw,
    MAX(consommation_mw) AS consommation_max_mw,
    AVG(consommation_mw) AS consommation_moy_mw,

    COUNT(*)             AS nb_mesures   -- 48 attendues pour un jour complet

FROM {{ ref('int_eco2mix_production_intermediate') }}
GROUP BY 1, 2, 3