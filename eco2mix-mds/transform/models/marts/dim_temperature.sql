-- Dimension température. Grain : un degré entier.
-- glacial <0 | froid [0,8) | modéré [8,17) | idéal [17,25) | chaud [25,33) | extrême >=33
-- (le sujet écrit idéal=[17,25] et chaud=[25,33) : chevauchement à 25, on retient [17,25)).
-- La clé -999 sert aux jours sans relevé de température (jointure à gauche, rien n'est perdu).
with degres as (
    select unnest(range(-30, 51)) as degre
)
select
    degre as temperature_key,
    degre,
    case
        when degre < 0  then 'glacial'
        when degre < 8  then 'froid'
        when degre < 17 then 'modéré'
        when degre < 25 then 'idéal'
        when degre < 33 then 'chaud'
        else 'extrême'
    end as intervalle,
    'toutes_temperatures' as toutes
from degres

union all

select -999, null, 'inconnue', 'toutes_temperatures'
