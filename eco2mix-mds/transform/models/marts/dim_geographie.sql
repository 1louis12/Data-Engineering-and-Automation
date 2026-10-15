-- Dimension géographie. Hiérarchie : région -> quart (zone) -> pays.
select distinct
    s.code_insee_region,
    s.region,
    z.zone                  as quart,
    'France métropolitaine' as pays
from {{ ref('eco2mix_regional_cons_def_stage') }} s
join {{ ref('ref_zones_regions') }} z on s.region = z.region
