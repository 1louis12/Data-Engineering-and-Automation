-- Q2. Pivot (CASE WHEN) : consommation journalière (GWh), une colonne par région.
-- Pas de ELSE : une région absente donne NULL (et non 0).
select
    jour,
    sum(case when region = 'Auvergne-Rhône-Alpes'        then consommation_gwh end) as auvergne_rhone_alpes,
    sum(case when region = 'Bourgogne-Franche-Comté'     then consommation_gwh end) as bourgogne_franche_comte,
    sum(case when region = 'Bretagne'                    then consommation_gwh end) as bretagne,
    sum(case when region = 'Centre-Val de Loire'         then consommation_gwh end) as centre_val_de_loire,
    sum(case when region = 'Grand Est'                   then consommation_gwh end) as grand_est,
    sum(case when region = 'Hauts-de-France'             then consommation_gwh end) as hauts_de_france,
    sum(case when region = 'Normandie'                   then consommation_gwh end) as normandie,
    sum(case when region = 'Nouvelle-Aquitaine'          then consommation_gwh end) as nouvelle_aquitaine,
    sum(case when region = 'Occitanie'                   then consommation_gwh end) as occitanie,
    sum(case when region = 'Pays de la Loire'            then consommation_gwh end) as pays_de_la_loire,
    sum(case when region = 'Provence-Alpes-Côte d''Azur' then consommation_gwh end) as paca,
    sum(case when region = 'Île-de-France'               then consommation_gwh end) as ile_de_france
from {{ ref('eco2mix_daily_consomation_intermediate') }}
group by jour
order by jour
