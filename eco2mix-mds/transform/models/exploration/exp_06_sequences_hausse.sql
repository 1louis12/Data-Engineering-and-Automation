{{ config(materialized='table') }}
-- Q6. Point fixe (CTE récursive) : les 3 plus longues séquences de hausse stricte
-- de la consommation instantanée (demi-heures consécutives), toutes régions confondues.
-- La récursion ne porte que (début, position courante) ; la liste de valeurs n'est
-- reconstruite que pour les 3 gagnantes (économie de mémoire).
with recursive mesures as (
    select
        region,
        date_heure,
        consommation_mw,
        row_number() over (partition by region order by date_heure) as rn
    from {{ ref('eco2mix_regional_cons_def_stage') }}
    where consommation_mw is not null
),

pas as (
    -- un pas = deux mesures consécutives ; hausse = la seconde dépasse strictement la première
    select
        a.region,
        a.rn,
        a.date_heure,
        b.consommation_mw > a.consommation_mw as hausse
    from mesures a
    join mesures b on a.region = b.region and b.rn = a.rn + 1
),

sequences as (
    -- ANCRE : un pas en hausse dont le pas précédent n'est pas une hausse
    select
        p.region,
        p.rn          as rn_debut,
        p.rn + 1      as rn_fin,
        p.date_heure  as debut
    from pas p
    left join pas q on q.region = p.region and q.rn = p.rn - 1
    where p.hausse and not coalesce(q.hausse, false)

    union all

    -- RÉCURSION : on prolonge d'un pas tant que la hausse continue
    select
        s.region,
        s.rn_debut,
        s.rn_fin + 1,
        s.debut
    from sequences s
    join pas p on p.region = s.region and p.rn = s.rn_fin and p.hausse
),

plus_longues as (
    -- la récursion produit un état par longueur ; on garde le plus long de chaque début
    select
        region, rn_debut, rn_fin, debut,
        rn_fin - rn_debut + 1 as nb_points
    from sequences
    qualify row_number() over (partition by region, rn_debut order by rn_fin desc) = 1
),

top3 as (
    select
        *,
        row_number() over (order by nb_points desc, debut) as rang
    from plus_longues
    qualify rang <= 3
)

select
    t.debut                                     as date_heure,
    (t.nb_points - 1) * interval 30 minute      as duree,
    t.region,
    (select list(m.consommation_mw order by m.rn)
       from mesures m
      where m.region = t.region and m.rn between t.rn_debut and t.rn_fin) as sequence_mw,
    t.nb_points,
    t.rang
from top3 t
order by t.rang
