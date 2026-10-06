* 00_config.do  Paths and globals. EDIT paths; data are not stored in the repository.
clear all
set more off
global ROOT   "."                              // repository root
global LASI   "$ROOT/data/H_LASI_a3.dta"       // Harmonized LASI A.3 (path/name: confirm)
global MHAS   "$ROOT/data/H_MHAS_c2.dta"       // Harmonized MHAS C.2 (path/name: confirm)
global OUT    "$ROOT/output"
capture mkdir "$OUT"
capture mkdir "$OUT/tables"
capture mkdir "$OUT/logs"
