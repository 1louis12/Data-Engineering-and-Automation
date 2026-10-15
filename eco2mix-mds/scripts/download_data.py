"""Télécharge les 3 jeux de données ODRÉ en CSV dans ./data (idempotent)."""
import urllib.request
from pathlib import Path

BASE = "https://opendata.reseaux-energies.fr/api/explore/v2.1/catalog/datasets"
DATASETS = [
    "eco2mix-regional-cons-def",         # consolidé + définitif (2013 ->)
    "eco2mix-regional-tr",               # temps réel (derniers mois)
    "temperature-quotidienne-regionale", # températures quotidiennes (2016 ->)
]

data_dir = Path(__file__).resolve().parent.parent / "data"
data_dir.mkdir(exist_ok=True)

for name in DATASETS:
    url = f"{BASE}/{name}/exports/csv?delimiter=%3B"   # %3B = ';'
    dest = data_dir / f"{name}.csv"
    if dest.exists():
        print(f"skip {dest.name} (déjà présent)")
        continue
    print(f"téléchargement {name} ...")
    urllib.request.urlretrieve(url, dest)
    print(f"  -> {dest} ({dest.stat().st_size / 1e6:.1f} Mo)")
