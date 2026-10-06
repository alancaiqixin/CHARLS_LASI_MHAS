* 04_mhas_analysis.do  Panel models: pooled and within-person (waves 3-5 for life satisfaction)
* Not executed: no Stata or microdata in the authoring environment.
do code/00_config.do
log using "$OUT/logs/04_mhas_analysis.log", replace text
use "$OUT/mhas_long.dta", clear   // id variable name must match 03_mhas_prepare.do
xtset unhhidnp wave
global X "c.agey i.rural c.adlfive i.work i.wave"
gen byte insamp = !missing(ls3, pov_eq_cons, recip, famstruct, agey, adlfive, rural, work)
* Pooled
eststo p1: reg ls3 i.pov_eq_cons i.recip i.famstruct $X if insamp [pw=wtresp], vce(cluster unhhidnp)
eststo p2: reg ls3 i.pov_eq_cons##i.famstruct i.recip $X if insamp [pw=wtresp], vce(cluster unhhidnp)
* Person fixed effects (identification from within-person change; time-varying family structure)
eststo f1: xtreg ls3 i.pov_eq_cons i.recip i.famstruct $X if insamp, fe vce(cluster unhhidnp)
eststo f2: xtreg ls3 i.pov_eq_cons##i.famstruct i.recip $X if insamp, fe vce(cluster unhhidnp)
* Hausman-type check (non-robust variant required)
quietly xtreg ls3 i.pov_eq_cons i.recip i.famstruct $X if insamp, fe
estimates store fe_nr
quietly xtreg ls3 i.pov_eq_cons i.recip i.famstruct $X if insamp, re
estimates store re_nr
hausman fe_nr re_nr, sigmamore
* Depressive symptoms (waves 1-5)
gen byte insamp2 = !missing(cesd, pov_eq_cons, recip, famstruct, agey, adlfive, rural, work)
eststo f3: xtreg cesd i.pov_eq_cons i.recip i.famstruct $X if insamp2, fe vce(cluster unhhidnp)
* Robustness: income-based poverty; lagged poverty (temporal ordering)
eststo r1: xtreg ls3 i.pov_eq_inc i.recip i.famstruct $X if insamp, fe vce(cluster unhhidnp)
gen L_pov = L.pov_eq_cons
eststo r2: xtreg ls3 i.L_pov i.recip i.famstruct $X if insamp, fe vce(cluster unhhidnp)
esttab p1 p2 f1 f2 f3 r1 r2 using "$OUT/tables/t4_mhas.csv", b(3) se(3) star(* 0.05 ** 0.01 *** 0.001) ///
    keep(1.pov* 1.L_pov *.recip *.famstruct) replace
log close
