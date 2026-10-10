```bash
pip freeze | grep -E "dbt|duckdb" > requirements.txt
```

```bash
cd ~/.dbt #pour copier le contenu de profiles.ymal et le déplacer dans transform/
dbt debug --profiles-dir . 
```
