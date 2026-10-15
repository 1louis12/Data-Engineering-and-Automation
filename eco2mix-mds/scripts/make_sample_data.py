"""Génère de PETITS CSV synthétiques (même schéma que ODRÉ) dans ./data.
Sert à tester le pipeline sans réseau. N'écrase rien : supprimez data/*.csv avant
si vous voulez regénérer. Les valeurs sont fictives."""
from pathlib import Path
import duckdb

data = Path(__file__).resolve().parent.parent / "data"
data.mkdir(exist_ok=True)
con = duckdb.connect()
con.execute("select setseed(0.42)")

con.execute("""
create table regions as select * from (values
 ('84','Auvergne-Rhône-Alpes',6000),('27','Bourgogne-Franche-Comté',2200),('53','Bretagne',2400),
 ('24','Centre-Val de Loire',2000),('44','Grand Est',4300),('32','Hauts-de-France',4000),
 ('28','Normandie',2800),('75','Nouvelle-Aquitaine',3600),('76','Occitanie',3300),
 ('52','Pays de la Loire',2900),('93','Provence-Alpes-Côte d''Azur',3500),('11','Île-de-France',6500)
) t(code, nom, base)""")

def eco(start, end, nature_expr, path, tr=False):
    con.execute(f"""
    copy (
      select r.code as code_insee_region, r.nom as libelle_region, {nature_expr} as nature,
        strftime(ts, '%Y-%m-%d') as date, strftime(ts, '%H:%M') as heure,
        strftime(ts, '%Y-%m-%dT%H:%M:%S') || '+01:00' as date_heure,
        round(r.base * (1 + 0.3*cos(2*pi()*(dayofyear(ts)-15)/365) + 0.15*sin(2*pi()*(hour(ts)-6)/24)) + random()*40, 0) as consommation,
        round(r.base*0.15*random(), 0) as thermique,
        round(r.base*0.9*(0.8+0.2*random()), 0) as nucleaire,
        case when year(ts)=2024 and month(ts)=1 then null else round(r.base*0.2*random(),0) end as eolien,
        round(greatest(0, r.base*0.1*sin(pi()*(hour(ts)-5)/14))*random(), 0) as solaire,
        round(r.base*0.25*(0.5+random()*0.5), 0) as hydraulique,
        -round(r.base*0.02*random(), 0) as pompage,
        round(r.base*0.03, 0) as bioenergies,
        round(r.base*0.2*(random()-0.5), 0) as ech_physiques,
        null as stockage_batterie, null as destockage_batterie, null as eolien_terrestre, null as eolien_offshore,
        round(random()*10, 1) as tco_thermique, round(random()*10, 1) as tch_thermique,
        round(random()*100, 1) as tco_nucleaire, round(random()*100, 1) as tch_nucleaire,
        round(random()*20, 1) as tco_eolien, round(random()*20, 1) as tch_eolien,
        round(random()*10, 1) as tco_solaire, round(random()*10, 1) as tch_solaire,
        round(random()*30, 1) as tco_hydraulique, round(random()*30, 1) as tch_hydraulique,
        round(random()*5, 1) as tco_bioenergies, round(random()*5, 1) as tch_bioenergies,
        null as column_30
      from regions r, generate_series(timestamp '{start}', timestamp '{end}', interval 30 minute) g(ts)
      order by r.code, ts
    ) to '{path}' (format csv, delimiter ';', header true)""")

eco('2024-01-01 00:00', '2025-12-31 23:30', "'Données définitives'", data/"eco2mix-regional-cons-def.csv")
# ajoute les lignes consolidées (janvier 2026)
eco('2026-01-01 00:00', '2026-01-31 23:30', "'Données consolidées'", data/"_cons_2026.csv")
eco('2026-01-20 00:00', '2026-02-10 23:30', "'Données temps réel'", data/"eco2mix-regional-tr.csv")
# concatène sans l'en-tête
with open(data/"eco2mix-regional-cons-def.csv", "a", encoding="utf-8") as out, open(data/"_cons_2026.csv", encoding="utf-8") as inp:
    next(inp)
    out.write(inp.read())
(data/"_cons_2026.csv").unlink()

con.execute(f"""
copy (
  select strftime(d, '%Y-%m-%d') as date, r.code as code_insee_region, r.nom as region,
    round(tm - 4 - random()*3, 1) as tmin, round(tm + 4 + random()*3, 1) as tmax, round(tm, 1) as tmoy
  from regions r, generate_series(date '2024-01-01', date '2026-02-10', interval 1 day) g(d),
       lateral (select 12 - 11*cos(2*pi()*(dayofyear(d)-15)/365) + (random()-0.5)*4 as tm) x
  order by r.code, d
) to '{data/"temperature-quotidienne-regionale.csv"}' (format csv, delimiter ';', header true)""")
print("CSV synthétiques générés dans", data)
