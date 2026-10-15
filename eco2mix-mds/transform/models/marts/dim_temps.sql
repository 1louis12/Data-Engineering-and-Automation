-- Dimension temps. Hiérarchie : jour -> mois -> saison -> année -> toute la période.
with jours as (
    select unnest(generate_series(date '2013-01-01', date '2035-12-31', interval 1 day))::date as jour
)
select
    jour,
    date_trunc('month', jour)::date as mois,
    quarter(jour)                   as trimestre,
    case
        when month(jour) in (12, 1, 2) then 'hiver'
        when month(jour) in (3, 4, 5)  then 'printemps'
        when month(jour) in (6, 7, 8)  then 'été'
        else 'automne'
    end                             as saison,
    year(jour)                      as annee,
    'toute_la_periode'              as periode
from jours
