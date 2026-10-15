-- Q7. Cube : toutes les combinaisons de deux hiérarchies.
--   temps : jour -> mois -> année -> toute la période
--   géo   : région -> zone -> France métropolitaine
-- Deux ROLLUP côte à côte = produit cartésien de leurs ensembles = 4 x 3 = 12 niveaux.
-- NULL = "toutes les valeurs" ; grouping() le distingue d'un vrai NULL.
with base as (
    select
        d.jour,
        year(d.jour)   as annee,
        month(d.jour)  as mois,
        z.zone,
        d.region,
        d.consommation_gwh
    from {{ ref('eco2mix_daily_consomation_intermediate') }} d
    join {{ ref('ref_zones_regions') }} z on d.region = z.region
)

select
    annee,
    mois,
    jour,
    zone,
    region,
    case
        when grouping(jour)  = 0 then 'jour'
        when grouping(mois)  = 0 then 'mois'
        when grouping(annee) = 0 then 'annee'
        else 'toute_la_periode'
    end as niveau_temps,
    case
        when grouping(region) = 0 then 'region'
        when grouping(zone)   = 0 then 'zone'
        else 'france_metropolitaine'
    end as niveau_geo,
    sum(consommation_gwh) as consommation_gwh
from base
group by rollup(annee, mois, jour), rollup(zone, region)
