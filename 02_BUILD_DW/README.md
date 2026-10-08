# Niveau 2 : Data Warehouse et Data Marts (DuckDB)

Après l'analyse exploratoire (niveau 1), ce niveau transforme les données brutes en un **Data Warehouse** structuré en modèle en étoile, puis dérive **4 Data Marts** spécialisés pour des cas d'usage analytiques précis. Tout le pipeline est écrit en SQL pour DuckDB.

## Prérequis

- **DuckDB CLI 1.4 ou supérieur** .
- Les 4 fichiers CSV du dataset des offres d'emploi de Luke Barousse (même source que le niveau 1) :

| Fichier | Lien |
|---|---|
| `company_dim.csv` | https://storage.googleapis.com/sql_de/company_dim.csv |
| `skills_dim.csv` | https://storage.googleapis.com/sql_de/skills_dim.csv |
| `job_postings_fact.csv` | https://storage.googleapis.com/sql_de/job_postings_fact.csv |
| `skills_job_dim.csv` | https://storage.googleapis.com/sql_de/skills_job_dim.csv |

Placez les CSV dans un dossier `CSV/` à la racine du projet, au même niveau que `02_BUILD_DW/`. Le script de chargement les lit via le chemin relatif `../CSV/`.

```text
.
├── CSV/
│   ├── company_dim.csv
│   ├── skills_dim.csv
│   ├── job_postings_fact.csv
│   └── skills_job_dim.csv
└── 02_BUILD_DW/
    ├── build_stage.sql
    ├── 01_create_tables_dw.sql
    ├── 02_load_schema.sql
    ├── 03_create_flat_mart.sql
    ├── 04_create_skills_mart.sql
    ├── 05_create_priority_mart.sql
    ├── 06_update_priority_mart.sql
    ├── 07_create_company_mart.sql
    └── README.md
```

## Architecture des données

Le projet suit une approche classique d'ingénierie des données : ingestion des données brutes, modélisation en Data Warehouse, puis Data Marts orientés usage métier.

### 1. Data Warehouse (schéma en étoile)

Les CSV sont chargés dans un modèle en étoile.

| Table | Type | Description |
|---|---|---|
| `company_dim` | Dimension | Entreprises (identifiant, nom, liens) |
| `skills_dim` | Dimension | Compétences et leur catégorie (`type`) |
| `job_postings_fact` | Fait | Offres d'emploi (titre, lieu, salaire, télétravail, etc.) |
| `skills_job_dim` | Pont | Lien many-to-many entre offres et compétences |

Fichiers : `01_create_tables_dw.sql` (création des tables et des clés) et `02_load_schema.sql` (chargement des CSV et contrôles d'intégrité référentielle, qui doivent retourner 0 identifiant orphelin).

### 2. Data Marts

Chaque Data Mart est créé dans son propre schéma. Chaque script commence par `DROP SCHEMA IF EXISTS ... CASCADE`, ce qui permet de le ré-exécuter sans erreur.

| Data Mart | Script | Schéma | Contenu et granularité |
|---|---|---|---|
| **Flat Mart** | `03_create_flat_mart.sql` | `flat_mart` | Table large `job_postings` : une ligne par offre. Les compétences sont regroupées dans une colonne `skills_and_types` (tableau de STRUCT, via `ARRAY_AGG` et `STRUCT_PACK`). |
| **Skills Demand Mart** | `04_create_skills_mart.sql` | `skills_mart` | Demande de compétences dans le temps. Granularité : `skill_id` + `month_start_date` + `job_title_short`. Les mesures (nombre d'offres, télétravail, assurance santé, absence de diplôme exigé) sont des compteurs additifs. |
| **Priority Mart** | `05_create_priority_mart.sql` & `06_update_priority_mart.sql` | `priority_mart` | Snapshot des offres liées aux rôles prioritaires, avec un niveau de priorité. Le script 06 met à jour les rôles (UPDATE, INSERT), puis synchronise le snapshot avec `MERGE INTO` (mise à jour, insertion et suppression) à partir d'une table temporaire `src_priority_jobs`. |
| **Company Prospecting Mart** | `07_create_company_mart.sql` | `company_mart` | Habitudes de recrutement des entreprises. Dimensions : entreprise, titre court, titre, localisation, mois. Ponts : `bridge_company_location` et `bridge_job_title`. Faits : nombre d'offres, salaire médian, minimum et maximum par entreprise, titre, pays et mois. |

## Exécution du pipeline

Le script `build_stage.sql` exécute toutes les étapes dans le bon ordre.

1. Vérifiez que les 4 CSV sont dans `../CSV/`.
2. Ouvrez DuckDB dans le dossier `02_BUILD_DW` :
```bash
   cd 02_BUILD_DW
   duckdb
```
3. Lancez le pipeline complet :
```sql
   .read build_stage.sql
```

Le script affiche le statut de chaque étape, de la création des tables jusqu'à la construction du dernier Data Mart.

## Vérifications intégrées

- **Intégrité référentielle** : le script 02 contrôle l'absence d'identifiants orphelins (`company_id`, `skill_id`, `job_id`).
- **Comptages** : chaque script affiche le nombre d'enregistrements créés dans ses tables.
- **Échantillons** : chaque script affiche un aperçu des données produites.

## Points d'attention

- **Ré-exécution du pipeline** : lancez toujours le pipeline complet via `build_stage.sql`. Les scripts 01 et 05 suppriment les tables et schémas existants avant de les recréer. Le script 02 utilise un `INSERT` simple et doit donc être exécuté après 01 uniquement.
- **Script 06** : il dépend de l'état créé par le script 05 et ajoute le rôle `role_id = 4` (Data Scientist). Il ne doit pas être relancé seul sans réexécuter 05, sinon l'insertion échoue sur la clé primaire.
- **Flat Mart** : une offre sans compétence associée produit un élément de tableau avec des valeurs `NULL`.

## Compétences techniques démontrées

- **Modélisation de données** : modèle en étoile, Data Marts, tables de pont pour les relations many-to-many.
- **SQL avancé** : `ARRAY_AGG`, `STRUCT_PACK`, `DATE_TRUNC`, `MEDIAN`, tables temporaires, `GROUP BY ALL`.
- **Mises à jour incrémentales** : `MERGE INTO` pour synchroniser un snapshot (logique proche d'un SCD de type 1).
- **Qualité des données** : contrôles d'intégrité référentielle intégrés.
- **Idempotence** : suppression conditionnelle des schémas et tables avant recréation.