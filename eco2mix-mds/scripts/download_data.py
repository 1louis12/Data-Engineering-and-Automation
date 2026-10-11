# scripts/download_data.py
"""Download the 3 ODRE datasets as CSV into ./data"""
import urllib.request
from pathlib import Path

BASE = "https://opendata.reseaux-energies.fr/api/explore/v2.1/catalog/datasets"
DATASETS = [
    "eco2mix-regional-cons-def",        # consolidated + definitive (2013 ->)
    "eco2mix-regional-tr",              # real time (recent months)
    "temperature-quotidienne-regionale" # daily temperatures (used in step 4)
]

data_dir = Path(__file__).resolve().parent.parent / "data"
data_dir.mkdir(exist_ok=True)

for name in DATASETS:
    url = f"{BASE}/{name}/exports/csv?delimiter=%3B"   # %3B = ';'
    dest = data_dir / f"{name}.csv"
    if dest.exists():
        print(f"skip {dest.name} (already there)")
        continue
    print(f"downloading {name} ...")
    urllib.request.urlretrieve(url, dest)
    print(f"  -> {dest} ({dest.stat().st_size / 1e6:.1f} MB)")
