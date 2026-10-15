-- Production totale et renouvelable (MW) par demi-heure.
-- Une filière absente (NULL) compte pour 0 dans la somme ; nb_filieres_null garde la trace.
-- Pompage (consommation) et échanges (flux avec les voisins) sont exclus de la production.
select
    *,
    coalesce(thermique_mw, 0) + coalesce(nucleaire_mw, 0)
      + coalesce(eolien_mw, 0) + coalesce(solaire_mw, 0)
      + coalesce(hydraulique_mw, 0) + coalesce(bioenergies_mw, 0)
        as production_totale_mw,

    coalesce(eolien_mw, 0) + coalesce(solaire_mw, 0)
      + coalesce(hydraulique_mw, 0) + coalesce(bioenergies_mw, 0)
        as production_renouvelable_mw,

    (thermique_mw is null)::int + (nucleaire_mw is null)::int
      + (eolien_mw is null)::int + (solaire_mw is null)::int
      + (hydraulique_mw is null)::int + (bioenergies_mw is null)::int
        as nb_filieres_null

from {{ ref('eco2mix_regional_cons_def_stage') }}
where consommation_mw is not null
