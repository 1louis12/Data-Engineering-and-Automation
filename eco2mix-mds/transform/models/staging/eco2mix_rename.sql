-- Rename columns
SELECT
    code_insee_region,
    libelle_region   AS region,
    nature,
    date             AS date_locale,
    date_heure,
    consommation     AS consommation_mw,
    thermique        AS thermique_mw,
    nucleaire        AS nucleaire_mw,
    eolien           AS eolien_mw,
    solaire          AS solaire_mw,
    hydraulique      AS hydraulique_mw,
    bioenergies      AS bioenergies_mw,
    pompage          AS pompage_mw,
    ech_physiques    AS ech_physiques_mw,
    tco_thermique,
    tco_nucleaire,
    tco_eolien,
    tco_solaire,
    tco_hydraulique,
    tco_bioenergies
FROM {{ ref('eco2mix_raw') }}