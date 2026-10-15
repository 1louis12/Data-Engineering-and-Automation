-- Étape 3 : filtre sur les clés uniquement (aucun choix métier ici).
-- Grain : une ligne par région et par demi-heure.
select *
from {{ ref('eco2mix_type') }}
where date_heure is not null
  and code_insee_region is not null
