-- Le total des 12 colonnes du pivot doit égaler la consommation nationale du jour. (0 ligne attendue)
with pivot_total as (
    select
        jour,
        auvergne_rhone_alpes + bourgogne_franche_comte + bretagne + centre_val_de_loire
          + grand_est + hauts_de_france + normandie + nouvelle_aquitaine + occitanie
          + pays_de_la_loire + paca + ile_de_france as total_pivot
    from {{ ref('exp_02_pivot_conso_regions') }}
),

national as (
    select jour, sum(consommation_gwh) as total_national
    from {{ ref('eco2mix_daily_consomation_intermediate') }}
    group by jour
)

select p.jour, p.total_pivot, n.total_national
from pivot_total p
join national n using (jour)
where abs(p.total_pivot - n.total_national) > 0.001
