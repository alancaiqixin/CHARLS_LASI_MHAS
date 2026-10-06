* 02_lasi_analysis.do  Main models, diagnostics, robustness (LASI wave 1). Not executed: no Stata or microdata in the authoring environment.
do code/00_config.do
log using "$OUT/logs/02_lasi_analysis.log", replace text
use "$OUT/lasi_analytic.dta", clear
ssc install estout, replace    // esttab; requires internet

global X "i.female c.age c.age#c.age i.rural c.adl lnwealth i.work i.hh1state"
* Analytic sample common to all models
gen byte insamp = !missing(ls3,pov_abs,rec_any,give_any,famstruct,age,female,rural,adl,lnwealth,work)
tab famstruct if insamp [aw=wt]

* ---------- Descriptives
estpost tabstat ls3 cesd pov_abs rec_any give_any if insamp [aw=wt], by(famstruct) stat(mean) columns(statistics)
esttab using "$OUT/tables/t1_descriptives.csv", cells("mean(fmt(3))") replace

* ---------- M1: poverty -> well-being (OLS, svy-weighted, SE clustered on state)
eststo m1: reg ls3 i.pov_abs $X if insamp [pw=wt], vce(cluster hh1state)
* ---------- M2: + reciprocity
eststo m2: reg ls3 i.pov_abs i.recip $X if insamp [pw=wt], vce(cluster hh1state)
* ---------- M3: poverty x family structure (heterogeneity)
eststo m3: reg ls3 i.pov_abs##i.famstruct i.recip $X if insamp [pw=wt], vce(cluster hh1state)
testparm i.pov_abs#i.famstruct                       // joint test of heterogeneity
margins famstruct, dydx(pov_abs) post
marginsplot, name(me_pov, replace)
graph export "$OUT/tables/f1_pov_by_famstruct.png", replace width(1600)
* ---------- M4: poverty x reciprocity x family structure (three-way; exploratory)
reg ls3 i.pov_abs##i.recip##i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
testparm i.pov_abs#i.recip#i.famstruct

* ---------- Transfer receipt as outcome of poverty risk (who is in poverty?)
eststo p1: logit pov_abs i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
margins famstruct, post

* ---------- Diagnostics
quietly reg ls3 i.pov_abs i.recip i.famstruct $X if insamp
estat hettest
predict r, resid
swilk r
estat vif
histogram r, normal name(resid_hist, replace)
drop r
* Influential observations
quietly reg ls3 i.pov_abs i.recip i.famstruct $X if insamp
predict cooksd, cooksd
summarize cooksd, detail
count if cooksd > 4/e(N)

* ---------- Robustness
* R1 alternative outcomes
eststo r1a: reg cesd i.pov_abs i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
eststo r1b: reg ls7  i.pov_abs i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
* R2 ordered logit on 3-point satisfaction (outcome is rounded mean; use categories)
gen ls3c = round(ls3)
eststo r2:  ologit ls3c i.pov_abs i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
* R3 alternative poverty definitions: relative (consumption, market income)
eststo r3a: reg ls3 i.pov_rel_eq_cons i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
eststo r3b: reg ls3 i.pov_rel_eq_pinc i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
* R4 continuous: log equivalized consumption
gen ln_eqcons = ln(eq_cons) if eq_cons>0
eststo r4: reg ls3 c.ln_eqcons i.recip i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
* R5 amounts instead of incidence
eststo r5: reg ls3 i.pov_abs c.ln_rec c.ln_give i.famstruct $X if insamp [pw=wt], vce(cluster hh1state)
* R6 exclude imputed transfer amounts
eststo r6: reg ls3 i.pov_abs c.ln_rec c.ln_give i.famstruct $X if insamp & r1ffrec==0 & r1ftgiv==0 [pw=wt], vce(cluster hh1state)
* R7 age 70+ ; R8 unweighted
eststo r7: reg ls3 i.pov_abs i.recip i.famstruct $X if insamp & age>=70 [pw=wt], vce(cluster hh1state)
eststo r8: reg ls3 i.pov_abs i.recip i.famstruct $X if insamp, vce(cluster hh1state)
* R9 sensitivity to unobserved confounding (Oster delta): requires `ssc install psacalc`
* psacalc delta pov_abs, rmax(...)

* ---------- Tables
esttab m1 m2 m3 using "$OUT/tables/t2_main.csv", b(3) se(3) star(* 0.05 ** 0.01 *** 0.001) ///
    keep(1.pov_abs *.recip *.famstruct) label replace
esttab r1a r1b r2 r3a r3b r4 r5 r6 r7 r8 using "$OUT/tables/t3_robustness.csv", b(3) se(3) ///
    star(* 0.05 ** 0.01 *** 0.001) keep(1.pov_abs 1.pov_rel* ln_eqcons ln_rec ln_give) replace
log close
