-- Étape 2 : conversion de types seulement. try_cast : valeur invalide -> NULL (pas d'erreur).
select
    code_insee_region,
    region,
    nature,
    try_cast(date_locale as date)          as date_locale,
    try_cast(date_heure as timestamptz)    as date_heure,
    try_cast(consommation_mw as double)    as consommation_mw,
    try_cast(thermique_mw as double)       as thermique_mw,
    try_cast(nucleaire_mw as double)       as nucleaire_mw,
    try_cast(eolien_mw as double)          as eolien_mw,
    try_cast(solaire_mw as double)         as solaire_mw,
    try_cast(hydraulique_mw as double)     as hydraulique_mw,
    try_cast(bioenergies_mw as double)     as bioenergies_mw,
    try_cast(pompage_mw as double)         as pompage_mw,
    try_cast(ech_physiques_mw as double)   as ech_physiques_mw,
    try_cast(tco_thermique as double)      as tco_thermique,
    try_cast(tco_nucleaire as double)      as tco_nucleaire,
    try_cast(tco_eolien as double)         as tco_eolien,
    try_cast(tco_solaire as double)        as tco_solaire,
    try_cast(tco_hydraulique as double)    as tco_hydraulique,
    try_cast(tco_bioenergies as double)    as tco_bioenergies
from {{ ref('eco2mix_rename') }}
