-- Union consolidé/définitif + temps réel. Une même demi-heure peut exister dans les deux jeux :
-- on garde le statut le plus fiable (1 définitif, 2 consolidé, 3 temps réel).
with cons_def as (
    select code_insee_region, region, nature, date_locale, date_heure,
           consommation_mw, thermique_mw, nucleaire_mw, eolien_mw,
           solaire_mw, hydraulique_mw, bioenergies_mw
    from {{ ref('eco2mix_regional_cons_def_stage') }}
),

tr as (
    select code_insee_region, region, nature, date_locale, date_heure,
           consommation_mw, thermique_mw, nucleaire_mw, eolien_mw,
           solaire_mw, hydraulique_mw, bioenergies_mw
    from {{ ref('stg_eco2mix_tr') }}
),

unies as (
    select * from cons_def
    union all
    select * from tr
),

classees as (
    select
        *,
        case nature
            when 'Données définitives' then 1
            when 'Données consolidées' then 2
            else 3
        end as statut_rang
    from unies
)

select
    *,
    coalesce(thermique_mw, 0) + coalesce(nucleaire_mw, 0) + coalesce(eolien_mw, 0)
      + coalesce(solaire_mw, 0) + coalesce(hydraulique_mw, 0) + coalesce(bioenergies_mw, 0)
        as production_totale_mw
from classees
qualify row_number() over (
    partition by code_insee_region, date_heure order by statut_rang
) = 1
