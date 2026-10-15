{{ config(
    materialized='incremental',
    unique_key=['code_insee_region', 'jour'],
    incremental_strategy='delete+insert'
) }}
-- Table de faits. Grain : une ligne par région et par jour. Mesures en GWh.
-- Taux de couverture recalculés depuis les énergies (filière / consommation), pas moyennés.
-- Incrémental : ne réécrit que les jours nouveaux, mieux validés, complétés ou dont
-- la température vient d'arriver (+ marge de sécurité de 3 jours).
with daily as (
    select
        date_locale                                   as jour,
        code_insee_region,
        sum(consommation_mw)      * 0.5 / 1000        as consommation_gwh,
        sum(production_totale_mw) * 0.5 / 1000        as production_gwh,
        sum(thermique_mw)         * 0.5 / 1000        as thermique_gwh,
        sum(nucleaire_mw)         * 0.5 / 1000        as nucleaire_gwh,
        sum(eolien_mw)            * 0.5 / 1000        as eolien_gwh,
        sum(solaire_mw)           * 0.5 / 1000        as solaire_gwh,
        sum(hydraulique_mw)       * 0.5 / 1000        as hydraulique_gwh,
        sum(bioenergies_mw)       * 0.5 / 1000        as bioenergies_gwh,
        count(*)                                      as nb_mesures,
        max(statut_rang)                              as statut_rang  -- pire statut du jour
    from {{ ref('int_eco2mix_union_demi_heure') }}
    where consommation_mw is not null
    group by 1, 2
),

enrichi as (
    select
        d.*,
        t.tmin_c, t.tmax_c, t.tmoy_c,
        case
            when t.tmoy_c is null then -999   -- pas de relevé : clé "inconnue"
            else greatest(-30, least(50, round(t.tmoy_c)::int))
        end as temperature_key
    from daily d
    left join {{ ref('stg_temperature_quotidienne') }} t
      on t.code_insee_region = d.code_insee_region and t.jour = d.jour
)

select
    e.jour,
    e.code_insee_region,
    e.temperature_key,
    e.consommation_gwh, e.production_gwh,
    e.thermique_gwh, e.nucleaire_gwh, e.eolien_gwh,
    e.solaire_gwh, e.hydraulique_gwh, e.bioenergies_gwh,
    100 * e.production_gwh  / nullif(e.consommation_gwh, 0) as tco_total_pct,
    100 * e.thermique_gwh   / nullif(e.consommation_gwh, 0) as tco_thermique_pct,
    100 * e.nucleaire_gwh   / nullif(e.consommation_gwh, 0) as tco_nucleaire_pct,
    100 * e.eolien_gwh      / nullif(e.consommation_gwh, 0) as tco_eolien_pct,
    100 * e.solaire_gwh     / nullif(e.consommation_gwh, 0) as tco_solaire_pct,
    100 * e.hydraulique_gwh / nullif(e.consommation_gwh, 0) as tco_hydraulique_pct,
    100 * e.bioenergies_gwh / nullif(e.consommation_gwh, 0) as tco_bioenergies_pct,
    e.tmin_c, e.tmax_c, e.tmoy_c,
    e.nb_mesures,
    e.statut_rang
from enrichi e
{% if is_incremental() %}
left join {{ this }} f
  on f.code_insee_region = e.code_insee_region and f.jour = e.jour
where f.jour is null                                              -- jour nouveau
   or e.statut_rang < f.statut_rang                               -- mieux validé (TR -> consolidé -> définitif)
   or e.nb_mesures <> f.nb_mesures                                -- journée complétée
   or (f.temperature_key = -999 and e.temperature_key <> -999)    -- température arrivée après coup
   or e.jour >= (select max(jour) from {{ this }}) - interval 3 day  -- marge de sécurité
{% endif %}
