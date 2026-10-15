-- Q5. Quantité cumulée : jour du dépassement des énergies renouvelables, par année complète.
-- Premier jour où la consommation cumulée de l'année >= production renouvelable annuelle totale.
-- Années complètes uniquement : on exclut l'année du dernier jour disponible.
with national as (
    select
        jour,
        sum(consommation_gwh)            as consommation_gwh,
        sum(production_renouvelable_gwh) as renouvelable_gwh
    from {{ ref('eco2mix_daily_consomation_intermediate') }}
    group by jour
),

cumuls as (
    select
        jour,
        year(jour) as annee,
        sum(consommation_gwh) over (partition by year(jour) order by jour) as conso_cumulee_gwh,
        sum(renouvelable_gwh) over (partition by year(jour))               as renouvelable_annuel_gwh
    from national
),

depassements as (
    select
        *,
        row_number() over (partition by annee order by jour) as rang
    from cumuls
    where conso_cumulee_gwh >= renouvelable_annuel_gwh
)

select
    annee,
    jour                             as jour_depassement,
    dayofyear(jour)                  as jour_de_lannee,
    round(renouvelable_annuel_gwh)   as renouvelable_annuel_gwh,
    round(conso_cumulee_gwh)         as conso_cumulee_gwh
from depassements
where rang = 1
  and annee < (select year(max(jour)) from national)
order by annee
