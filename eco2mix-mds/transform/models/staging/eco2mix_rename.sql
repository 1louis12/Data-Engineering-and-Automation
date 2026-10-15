-- Étape 1 : renommage seulement (tout reste en texte).
-- Colonnes abandonnées : column_30 (parasite), heure (redondante avec date_heure),
-- tch_*, stockage/déstockage batterie, détail éolien (non exploités ici).
select
    code_insee_region,
    libelle_region   as region,
    nature,
    date             as date_locale,
    date_heure,
    consommation     as consommation_mw,
    thermique        as thermique_mw,
    nucleaire        as nucleaire_mw,
    eolien           as eolien_mw,
    solaire          as solaire_mw,
    hydraulique      as hydraulique_mw,
    bioenergies      as bioenergies_mw,
    pompage          as pompage_mw,
    ech_physiques    as ech_physiques_mw,
    tco_thermique,
    tco_nucleaire,
    tco_eolien,
    tco_solaire,
    tco_hydraulique,
    tco_bioenergies
from {{ ref('eco2mix_raw') }}
