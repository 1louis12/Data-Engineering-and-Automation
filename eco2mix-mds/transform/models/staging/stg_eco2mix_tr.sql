-- Données temps réel : mêmes règles que le consolidé (renommage + try_cast + filtre sur les clés).
-- Grain : une ligne par région et par demi-heure.
select
    code_insee_region,
    libelle_region                          as region,
    nature,
    try_cast(date as date)                  as date_locale,
    try_cast(date_heure as timestamptz)     as date_heure,
    try_cast(consommation as double)        as consommation_mw,
    try_cast(thermique as double)           as thermique_mw,
    try_cast(nucleaire as double)           as nucleaire_mw,
    try_cast(eolien as double)              as eolien_mw,
    try_cast(solaire as double)             as solaire_mw,
    try_cast(hydraulique as double)         as hydraulique_mw,
    try_cast(bioenergies as double)         as bioenergies_mw
from {{ source('raw_eco2mix', 'eco2mix-regional-tr') }}
where try_cast(date_heure as timestamptz) is not null
  and code_insee_region is not null
