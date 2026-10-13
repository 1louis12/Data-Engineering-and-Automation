SELECT
    *,
    COALESCE(thermique_mw, 0) + COALESCE(nucleaire_mw, 0)
      + COALESCE(eolien_mw, 0) + COALESCE(solaire_mw, 0)
      + COALESCE(hydraulique_mw, 0) + COALESCE(bioenergies_mw, 0)
        AS production_totale_mw,

    COALESCE(eolien_mw, 0) + COALESCE(solaire_mw, 0)
      + COALESCE(hydraulique_mw, 0) + COALESCE(bioenergies_mw, 0)
        AS production_renouvelable_mw,

    (thermique_mw IS NULL)::int + (nucleaire_mw IS NULL)::int
      + (eolien_mw IS NULL)::int + (solaire_mw IS NULL)::int
      + (hydraulique_mw IS NULL)::int + (bioenergies_mw IS NULL)::int
        AS nb_filieres_null

FROM{{ ref('eco2mix_regional_cons_def_stage') }}
WHERE consommation_mw 
