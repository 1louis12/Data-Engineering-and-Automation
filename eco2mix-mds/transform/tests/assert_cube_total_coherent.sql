-- Chaque niveau géographique (au grain jour) doit donner la même somme que les données sources.
-- Échoue si une région n'est pas dans le seed (faute d'accent...). (0 ligne attendue)
with brut as (
    select sum(consommation_gwh) as total from {{ ref('eco2mix_daily_consomation_intermediate') }}
),

cube_niveaux as (
    select niveau_geo, sum(consommation_gwh) as total
    from {{ ref('exp_07_cube_consommation') }}
    where niveau_temps = 'jour'
    group by niveau_geo
)

select c.niveau_geo, c.total, b.total as total_brut
from cube_niveaux c, brut b
where abs(c.total - b.total) > 0.01
