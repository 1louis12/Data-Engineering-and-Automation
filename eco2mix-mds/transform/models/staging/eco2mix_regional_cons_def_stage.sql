SELECT *
FROM {{ ref('eco2mix_type') }}
WHERE date_heure is not null
  and code_insee_region is not null