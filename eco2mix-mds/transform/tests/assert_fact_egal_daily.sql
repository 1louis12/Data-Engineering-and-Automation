-- Jusqu'à fin 2025 (données définitives), la table de faits doit égaler le modèle journalier. (0 ligne attendue)
select f.total, d.total
from (select sum(consommation_gwh) as total from {{ ref('fct_energie_journaliere') }} where jour <= '2025-12-31') f,
     (select sum(consommation_gwh) as total from {{ ref('eco2mix_daily_consomation_intermediate') }} where jour <= '2025-12-31') d
where abs(f.total - d.total) > 0.01
