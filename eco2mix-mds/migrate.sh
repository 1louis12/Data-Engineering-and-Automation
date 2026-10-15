#!/usr/bin/env bash
# migrate_zip.sh : intègre le contenu de eco2mix-mds.zip dans TON arborescence existante,
# en gardant TES noms de fichiers/modèles (pas de refonte).
#
# Usage (depuis la racine du dépôt, celle qui contient transform/) :
#   bash migrate_zip.sh ~/Downloads/eco2mix-mds.zip
#
# Sécurité : tout fichier existant qui sera écrasé est d'abord copié dans
# migration_backup_<date>/ (même chemin relatif). Rien n'est supprimé.
# Compatible macOS (bash 3.2, BSD tools, perl).
set -euo pipefail

ZIP="${1:-}"
if [ -z "$ZIP" ] || [ ! -f "$ZIP" ]; then
  echo "Usage : bash migrate_zip.sh chemin/vers/eco2mix-mds.zip   (depuis la racine du dépôt)"
  exit 1
fi
if [ ! -f transform/dbt_project.yml ]; then
  echo "Erreur : lancez ce script depuis la racine du dépôt (le dossier qui contient transform/)."
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q "$ZIP" -d "$TMP"
SRC="$TMP/eco2mix-mds"
if [ ! -d "$SRC/transform" ]; then
  echo "Erreur : le zip n'a pas la structure attendue (eco2mix-mds/transform/...)."
  exit 1
fi

BACKUP="migration_backup_$(date +%Y%m%d_%H%M%S)"
M=transform/models

# ---------------------------------------------------------------------------
# 1. Table de correspondance : nom dans le zip -> TON nom
#    Les modèles absents de cette liste (stg_eco2mix_tr, dim_*, fct_*, exp_05..08...)
#    sont nouveaux et gardent le nom du zip.
# ---------------------------------------------------------------------------
RENAMES=(
  "base_eco2mix_1_rename:eco2mix_rename"
  "base_eco2mix_2_type:eco2mix_type"
  "stg_eco2mix_regional_cons_def:eco2mix_regional_cons_def_stage"
  "int_eco2mix_production:int_eco2mix_production_intermediate"
  "int_eco2mix_daily:eco2mix_daily_consomation_intermediate"
  "exp_04_variations_quotidiennes:exp_04_variations_quotidienne"
)
PERL_EXPR=""
for r in "${RENAMES[@]}"; do
  old="${r%%:*}"; new="${r##*:}"
  PERL_EXPR+="s/\\b${old}\\b/${new}/g;"
done

# put <chemin dans le zip> <destination> : copie (avec sauvegarde) puis renomme les ref()/name
put() {
  local src="$SRC/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
    mkdir -p "$BACKUP/$(dirname "$dst")"
    cp "$dst" "$BACKUP/$dst"
  fi
  cp "$src" "$dst"
  case "$dst" in
    *.sql|*.yml|*.md) perl -pi -e "$PERL_EXPR" "$dst" ;;
  esac
  echo "  + $dst"
}

# put_new : ne copie que si la destination n'existe pas
put_new() {
  if [ -f "$2" ]; then echo "  = conservé : $2"; else put "$1" "$2"; fi
}

echo "== Dossiers"
mkdir -p "$M/staging" "$M/intermediate" "$M/exploration" "$M/marts" \
         transform/seeds transform/tests scripts data

echo "== Staging"
put transform/models/staging/eco2mix/_sources.yml                  "$M/staging/_sources_eco2mix.yml"
put transform/models/staging/eco2mix/base_eco2mix_1_rename.sql     "$M/staging/eco2mix_rename.sql"
put transform/models/staging/eco2mix/base_eco2mix_2_type.sql       "$M/staging/eco2mix_type.sql"
put transform/models/staging/eco2mix/stg_eco2mix_regional_cons_def.sql "$M/staging/eco2mix_regional_cons_def_stage.sql"
put transform/models/staging/eco2mix/stg_eco2mix_tr.sql            "$M/staging/stg_eco2mix_tr.sql"
put transform/models/staging/eco2mix/_models.yml                   "$M/staging/_stg_eco2mix_models.yml"
put transform/models/staging/temperature/_sources.yml              "$M/staging/_sources_temperature.yml"
put transform/models/staging/temperature/stg_temperature_quotidienne.sql "$M/staging/stg_temperature_quotidienne.sql"
put transform/models/staging/temperature/_models.yml               "$M/staging/_stg_temperature_models.yml"

# Ton modèle eco2mix_raw est conservé tel quel ; il est créé seulement s'il manque.
# Dans le zip, l'étape rename lisait la source directement : on la branche ici sur ton eco2mix_raw.
if [ ! -f "$M/staging/eco2mix_raw.sql" ]; then
  cat > "$M/staging/eco2mix_raw.sql" <<'EOF'
-- Copie brute du CSV (tout en texte). Aucune transformation.
select * from {{ source('raw_eco2mix', 'eco2mix-regional-cons-def') }}
EOF
  echo "  + $M/staging/eco2mix_raw.sql (créé)"
else
  echo "  = conservé : $M/staging/eco2mix_raw.sql"
fi
perl -pi -e 's/\{\{\s*source\(\x27raw_eco2mix\x27,\s*\x27eco2mix-regional-cons-def\x27\)\s*\}\}/{{ ref(\x27eco2mix_raw\x27) }}/' \
  "$M/staging/eco2mix_rename.sql"
# documentation de eco2mix_raw dans le yml de staging
perl -0pi -e 's/(models:\n)/$1  - name: eco2mix_raw\n    description: "Copie brute du CSV éCO2mix consolidé\/définitif (tout en texte)."\n\n/' \
  "$M/staging/_stg_eco2mix_models.yml"

echo "== Intermediate"
put transform/models/intermediate/eco2mix/_models.yml                  "$M/intermediate/_int_eco2mix_models.yml"
put transform/models/intermediate/eco2mix/int_eco2mix_production.sql   "$M/intermediate/int_eco2mix_production_intermediate.sql"
put transform/models/intermediate/eco2mix/int_eco2mix_daily.sql        "$M/intermediate/eco2mix_daily_consomation_intermediate.sql"
put transform/models/intermediate/eco2mix/int_eco2mix_union_demi_heure.sql "$M/intermediate/int_eco2mix_union_demi_heure.sql"

echo "== Exploration"
put transform/models/exploration/eco2mix/_models.yml                          "$M/exploration/_exp_eco2mix_models.yml"
put transform/models/exploration/eco2mix/exp_01_mensuel_region.sql            "$M/exploration/exp_01_mensuel_region.sql"
put transform/models/exploration/eco2mix/exp_02_pivot_conso_regions.sql       "$M/exploration/exp_02_pivot_conso_regions.sql"
put transform/models/exploration/eco2mix/exp_03_conso_mois_glissant.sql       "$M/exploration/exp_03_conso_mois_glissant.sql"
put transform/models/exploration/eco2mix/exp_04_variations_quotidiennes.sql   "$M/exploration/exp_04_variations_quotidienne.sql"
put transform/models/exploration/eco2mix/exp_05_jour_depassement_renouvelables.sql "$M/exploration/exp_05_jour_depassement_renouvelables.sql"
put transform/models/exploration/eco2mix/exp_06_sequences_hausse.sql          "$M/exploration/exp_06_sequences_hausse.sql"
put transform/models/exploration/eco2mix/exp_07_cube_consommation.sql         "$M/exploration/exp_07_cube_consommation.sql"
put transform/models/exploration/eco2mix/exp_08_cuboide_mois_quart_temperature.sql "$M/exploration/exp_08_cuboide_mois_quart_temperature.sql"

echo "== Marts (entrepôt)"
put transform/models/marts/_models.yml                "$M/marts/_marts_models.yml"
put transform/models/marts/dim_temps.sql              "$M/marts/dim_temps.sql"
put transform/models/marts/dim_geographie.sql         "$M/marts/dim_geographie.sql"
put transform/models/marts/dim_temperature.sql        "$M/marts/dim_temperature.sql"
put transform/models/marts/fct_energie_journaliere.sql "$M/marts/fct_energie_journaliere.sql"

echo "== Seeds et tests singuliers"
put transform/seeds/ref_zones_regions.csv   transform/seeds/ref_zones_regions.csv
put transform/seeds/_seeds.yml              transform/seeds/_seeds.yml
for t in assert_pivot_egal_total_national assert_sequences_strictement_croissantes \
         assert_cube_total_coherent assert_fact_egal_daily; do
  put "transform/tests/$t.sql" "transform/tests/$t.sql"
done

echo "== Scripts, README, fichiers racine"
put scripts/download_data.py     scripts/download_data.py
put scripts/make_sample_data.py  scripts/make_sample_data.py
put README.md                    README.md
put_new requirements.txt         requirements.txt
put_new transform/packages.yml   transform/packages.yml
put_new data/.gitkeep            data/.gitkeep
for l in 'data/*' '!data/.gitkeep' 'transform/target/' 'transform/dbt_packages/' 'transform/logs/' \
         '*.duckdb' '*.duckdb.wal' 'transform/.user.yml' 'migration_backup_*/' '__pycache__/' '.DS_Store'; do
  grep -qxF "$l" .gitignore 2>/dev/null || echo "$l" >> .gitignore
done

echo "== dbt_project.yml : remplacement du bloc models: (adapté à ton arborescence à plat)"
mkdir -p "$BACKUP/transform"
cp transform/dbt_project.yml "$BACKUP/transform/dbt_project.yml"
# on garde tout sauf l'ancien bloc "models:" (et on conserve les autres blocs éventuels)
awk '/^models:/ {skip=1; next} skip && /^[A-Za-z_+-]+:/ {skip=0} !skip {print}' \
  "$BACKUP/transform/dbt_project.yml" > "$TMP/dbt_head.yml"
cat "$TMP/dbt_head.yml" - > transform/dbt_project.yml <<'EOF'

models:
  # Une couche = un dossier = une responsabilité.
  #   staging      : nettoyage mécanique (raw -> rename -> type -> stage)
  #   intermediate : calculs et changements de grain
  #   exploration  : requêtes SQL avancées
  #   marts        : entrepôt (faits + dimensions). Un nouveau .sql ici = une nouvelle table.
  transform:
    staging:
      +materialized: view
      eco2mix_raw:
        +schema: base
      eco2mix_rename:
        +schema: base
      eco2mix_type:
        +schema: base
      eco2mix_regional_cons_def_stage:
        +materialized: table
      stg_eco2mix_tr:
        +materialized: table
      stg_temperature_quotidienne:
        +materialized: table
    intermediate:
      +materialized: view
      eco2mix_daily_consomation_intermediate:
        +materialized: table
      int_eco2mix_union_demi_heure:
        +materialized: table
    exploration:
      +materialized: view
    marts:
      +materialized: table
EOF
echo "  + transform/dbt_project.yml (ancien fichier sauvegardé)"

echo "== Contrôle des doublons de documentation (un modèle ne doit être décrit qu'une fois)"
dups=$(grep -rhoE "^  - name: [A-Za-z0-9_]+" "$M" --include=*.yml | sort | uniq -d || true)
if [ -n "$dups" ]; then
  echo "  ATTENTION : ces noms apparaissent plusieurs fois dans vos .yml (supprimez l'ancienne définition) :"
  echo "$dups" | sed 's/^/    /'
else
  echo "  OK, aucun doublon."
fi

echo
echo "Migration terminée. Sauvegardes éventuelles : $BACKUP/"
echo
echo "Suite :"
echo "  cd transform && export DBT_PROFILES_DIR=."
echo "  rm -f ../data/eco2mix_dev.duckdb      # base propre : les schémas ont changé (vues base_ -> schéma main_base)"
echo "  dbt deps && dbt seed && dbt build"
echo "  (données absentes ? python ../scripts/download_data.py, ou ../scripts/make_sample_data.py pour un jeu fictif)"

