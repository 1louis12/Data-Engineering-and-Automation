# eco2mix-mds : Modern Data Stack (dbt + DuckDB) sur les données éCO2mix

Projet ELT complet sur la production et la consommation d'électricité en France par région
(données ouvertes RTE / ODRÉ) : nettoyage, requêtes SQL avancées (OLAP), entrepôt en étoile
avec mise à jour incrémentale.

**Stack** : `DuckDB` (base embarquée) · `dbt-duckdb` (transformations, tests, documentation) · Python (téléchargement).
Extensions possibles : `Evidence` (visualisation), `Meltano` (extraction/chargement).

## Avancement

- [x] **Étape 0** : environnement (venv, dbt-duckdb, profil embarqué dans le dépôt)
- [x] **Étape 1** : extraction + sources dbt (CSV lus directement via `external_location`)
- [x] **Étape 2** : nettoyage (staging `base_` → `stg_`), production totale, grain journalier, tests, documentation
- [x] **Étape 3** : 7 requêtes d'exploration (agrégation, pivot, fenêtre glissante, variation, cumul, CTE récursive, cube)
- [x] **Étape 4** : entrepôt en étoile (3 dimensions + faits), températures, cuboïde, mise à jour incrémentale
- [ ] **Étape 5** (bonus) : comparaison des formats CSV / JSON / Parquet / DuckDB / Arrow
- [ ] Visualisation avec Evidence (optionnel)

## Mise en route

```bash
git clone <url-du-depot> && cd eco2mix-mds
python -m venv venv && source venv/bin/activate      # Windows : venv\Scripts\activate
pip install -r requirements.txt

python scripts/download_data.py        # 3 CSV ODRÉ dans data/ (ou : python scripts/make_sample_data.py pour un jeu de test fictif)

cd transform
export DBT_PROFILES_DIR=.              # le profil est dans le dépôt
dbt deps                               # installe dbt_utils
dbt seed                               # table de correspondance région -> zone
dbt build                              # run + tests de tous les modèles (ou : dbt run puis dbt test)
dbt docs generate && dbt docs serve    # documentation + graphe de lignage
```

La base est créée dans `data/eco2mix_dev.duckdb` (cible `dev`). Cible `prod` : `dbt build --target prod`.
Explorer : `duckdb data/eco2mix_dev.duckdb`.

> Le dossier `data/` n'est pas versionné (sauf `.gitkeep`) : les CSV et la base sont régénérables.

## Architecture

```
eco2mix-mds/
├── README.md
├── requirements.txt
├── data/                       # CSV + base .duckdb (ignorés par git)
├── scripts/
│   ├── download_data.py        # télécharge les 3 jeux ODRÉ
│   └── make_sample_data.py     # jeu synthétique pour tester sans réseau
└── transform/                  # projet dbt
    ├── dbt_project.yml · profiles.yml · packages.yml
    ├── seeds/                  # ref_zones_regions.csv (région -> zone)
    ├── tests/                  # tests singuliers (cohérence métier)
    └── models/
        ├── staging/            # nettoyage mécanique : eco2mix/ et temperature/
        ├── intermediate/       # production totale, grain journalier, union consolidé + temps réel
        ├── exploration/        # requêtes d'analyse exp_01 … exp_08
        └── marts/              # entrepôt : dim_*.sql et fct_*.sql
```

| Couche | Rôle | Matérialisation |
|---|---|---|
| `staging` | renommer, typer (`try_cast`), filtrer sur les clés. Aucune logique métier | `base_*` en vue (schéma `main_base`), `stg_*` en table |
| `intermediate` | calculs et changements de grain (demi-heure → jour) | vue, sauf `daily` et `union` en table |
| `exploration` | les requêtes SQL avancées | vue (`exp_06` en table) |
| `marts` | tables finales de l'entrepôt (schéma en étoile) | table (faits : incrémental) |

Chaîne de staging éCO2mix : `source` → `eco2mix_rename` → `eco2mix_type` → `eco2mix_regional_cons_def_stage`.
Chaque étape est un objet interrogeable dans la base, donc facile à déboguer.

### Ajouter une table à l'entrepôt

**Il suffit de créer un fichier `.sql` dans `transform/models/marts/`** : dbt le matérialise en table
(configuré dans `dbt_project.yml`). Exemple :

```sql
-- transform/models/marts/dim_saison_hiver.sql
select * from {{ ref('dim_temps') }} where saison = 'hiver'
```

```bash
dbt run --select dim_saison_hiver
```

Pensez à la déclarer (description + tests) dans `models/marts/_models.yml`.

## Les 7 requêtes d'exploration (étape 3)

| Modèle | Technique SQL |
|---|---|
| `exp_01_mensuel_region` | groupement et agrégation, énergie (GWh) et min/max/moyenne (MW) |
| `exp_02_pivot_conso_regions` | pivot `CASE WHEN … END` |
| `exp_03_conso_mois_glissant` | fenêtre `RANGE` sur un mois |
| `exp_04_variations_quotidienne` | `lag` + CTE, top 20 des écarts |
| `exp_05_jour_depassement_renouvelables` | sommes cumulées + `row_number` |
| `exp_06_sequences_hausse` | **CTE récursive** : 3 plus longues séquences de hausse |
| `exp_07_cube_consommation` | `ROLLUP` x `ROLLUP` : 4 niveaux de temps x 3 niveaux géographiques |

Les interprétations des résultats sont à ajouter dans la section « Résultats » ci-dessous
(à rédiger à partir de vos propres chiffres sur les vraies données).

## Entrepôt en étoile (étape 4)

```
dim_temps ──┐
dim_geographie ──┼── fct_energie_journaliere ──► exp_08_cuboide_mois_quart_temperature
dim_temperature ──┘
```

- **Faits** `fct_energie_journaliere` : grain région x jour ; consommation, production et production par filière (GWh) ;
  taux de couverture (%) recalculés depuis les énergies ; températures min/max/moyenne.
- **`dim_temps`** : jour → mois → saison → année → toute la période.
- **`dim_geographie`** : région → quart (NO, NE, SO, SE, IdF) → pays.
- **`dim_temperature`** : au degré, par intervalle (glacial, froid, modéré, idéal, chaud, extrême) et clé `-999` « inconnue ».

### Mise à jour incrémentale

`dbt run` (sans `--full-refresh`) ne réécrit dans les faits que :

1. les jours **nouveaux** ;
2. les jours dont le **statut s'améliore** (temps réel → consolidé → définitif) ;
3. les journées dont le **nombre de mesures change** (journée complétée) ;
4. les jours dont la **température est arrivée après coup** ;
5. une marge de sécurité de **3 jours**.

L'union `int_eco2mix_union_demi_heure` garde, pour chaque (région, demi-heure), la donnée de meilleur statut.
`dbt run --full-refresh` reconstruit tout.

**Test de la procédure** (testé sur le jeu synthétique : 9264 lignes restaurées, statuts corrigés) :

```sql
delete from fct_energie_journaliere where jour >= '2026-01-15';
update fct_energie_journaliere set statut_rang = 3 where jour between '2025-03-01' and '2025-03-31';
```
```bash
dbt run --select fct_energie_journaliere     # répare uniquement ce qui a changé
```

Fermer le client DuckDB avant `dbt run` : un seul processus peut écrire dans le fichier.

## Qualité des données : tests

- **Génériques** (YAML) : `not_null`, `unique`, `accepted_values`, `relationships` (clés étrangères du schéma en étoile), `dbt_utils.unique_combination_of_columns`, `accepted_range`.
- **Singuliers** (`transform/tests/`, 0 ligne attendue) : le pivot égale le total national, les séquences sont strictement croissantes, le cube est cohérent entre niveaux géographiques, les faits égalent le journalier.

`dbt test` → 65 tests passent sur le jeu synthétique.

## Choix de conception (à relire et à justifier)

| Choix | Raison |
|---|---|
| Raw = fichiers CSV lus via `external_location` | une seule définition de la source, dans dbt |
| `all_varchar` + `try_cast` en staging | le raw reste fidèle, une valeur invalide donne `NULL` au lieu de planter |
| `date_heure` en `timestamptz` | évite l'ambiguïté de l'heure locale au changement d'heure d'octobre |
| Production totale = thermique + nucléaire + éolien + solaire + hydraulique + bioénergies | exclut pompage (consommation) et échanges (flux avec les voisins) |
| `NULL` = 0 uniquement dans la somme, avec `nb_filieres_null` | pas d'écrasement des données, la règle est visible |
| GWh = MW x 0,5 h / 1000 | chaque mesure est une puissance moyenne sur 30 min |
| Zones NO/NE/SO/SE/IdF (seed) | **découpage à valider** : le sujet ne le précise pas |
| Idéal = [17, 25[ | le sujet donne [17, 25] et chaud = [25, 33[ : chevauchement à 25 |
| Jour du dépassement sur les années complètes | l'année du dernier jour disponible est exclue |
| Temps réel > consolidé > définitif dans les faits, mais statut le plus fiable gardé | cycle de vie de la donnée |

## Limites connues

- Les noms de colonnes du CSV température (`date, code_insee_region, tmin, tmax, tmoy`) et du temps réel sont **supposés** : vérifier avec `DESCRIBE` sur les vrais fichiers.
- `exp_06` suppose des demi-heures consécutives ; un trou dans les données prolongerait une séquence artificiellement.
- Le projet a été exécuté sur des **données synthétiques** : les chiffres et interprétations sur les vraies données restent à produire.

## Résultats et interprétations

_À compléter à partir des résultats sur les vraies données (une courte interprétation par requête)._

## Ressources

- dbt : https://docs.getdbt.com · DuckDB : https://duckdb.org/docs/
- Jeux de données : https://opendata.reseaux-energies.fr (éCO2mix régional consolidé/définitif, temps réel, températures quotidiennes régionales)
