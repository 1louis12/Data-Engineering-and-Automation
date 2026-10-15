-- Chaque séquence de Q6 doit être strictement croissante. (0 ligne attendue)
-- Les index de listes DuckDB commencent à 1.
select rang, region, date_heure
from {{ ref('exp_06_sequences_hausse') }}
where len(list_filter(
        range(1, len(sequence_mw)),
        i -> sequence_mw[i + 1] <= sequence_mw[i]
      )) > 0
   or len(sequence_mw) <> nb_points
