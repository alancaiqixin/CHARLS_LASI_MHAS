* 01_lasi_prepare.do  Harmonized LASI A.3, wave 1 (cross-section)
* NOTE: written from the codebook; not executed (no data / Stata in the authoring environment).
do code/00_config.do
log using "$OUT/logs/01_lasi_prepare.log", replace text
use "$LASI", clear
keep if r1iwstat == 1                       // responded
keep if r1agey >= 60 & !missing(r1agey)     // old-age sample; change to >=45 for full LASI

* ---- Outcomes: subjective well-being (higher = better for LS; higher = worse for CESD)
gen ls3   = r1lsatsc3                        // 1-3, higher = more satisfied
gen cesd  = r1cesd10                         // 0-30, higher = more depressive symptoms
gen ls7   = r1lsatsc                         // 1-7 sensitivity

* ---- Poverty
gen pov_abs = hh1poverty                     // consumption, USD1.90/day (2011 PPP)
gen eq_cons = hh1ctot / sqrt(hh1hhres)       // equivalized (sqrt scale) annual consumption
gen pretr_inc = hh1itot - hh1ipxfr           // market income, net of private transfers
replace pretr_inc = hh1itot if missing(hh1ipxfr)
gen eq_pinc = pretr_inc / sqrt(hh1hhres)
* Relative poverty: <50% of weighted median (person-weighted)
foreach v in eq_cons eq_pinc {
    quietly summarize `v' [aw=r1wtresp], detail
    gen pov_rel_`v' = (`v' < 0.5*r(p50)) if !missing(`v')
}

* ---- Reciprocity (past year)
gen rec_any  = r1fcany
gen give_any = r1tcany
gen ln_rec   = ln(r1frec + 1)
gen ln_give  = ln(r1tgiv + 1)
gen netflow  = r1ftot
* Reciprocity typology (needs both any-flows non-missing)
gen recip = .
replace recip = 0 if rec_any==0 & give_any==0   // no exchange
replace recip = 1 if rec_any==1 & give_any==0   // receive only
replace recip = 2 if rec_any==0 & give_any==1   // give only
replace recip = 3 if rec_any==1 & give_any==1   // reciprocal
label define recip 0 "None" 1 "Receive only" 2 "Give only" 3 "Reciprocal"
label values recip recip

* ---- Family structure typology
gen nchild = r1child
gen kids = cond(nchild==0,0,cond(nchild<=2,1,2)) if !missing(nchild)
label define kids 0 "No child" 1 "1-2 children" 2 "3+ children"
label values kids kids
gen partnered = inlist(r1mstat,1,3) if !missing(r1mstat)   // 1 = married, 3 = partnered (verified in codebook)
gen coreside = r1coresd
gen famstruct = .
replace famstruct = 1 if nchild==0 & partnered==0
replace famstruct = 2 if nchild==0 & partnered==1
replace famstruct = 3 if nchild>0  & partnered==0 & coreside==0
replace famstruct = 4 if nchild>0  & partnered==0 & coreside==1
replace famstruct = 5 if nchild>0  & partnered==1 & coreside==0
replace famstruct = 6 if nchild>0  & partnered==1 & coreside==1
label define fs 1 "No child, unpartnered" 2 "No child, partnered" 3 "Child, unpartnered, apart" ///
    4 "Child, unpartnered, co-resident" 5 "Child, partnered, apart" 6 "Child, partnered, co-resident"
label values famstruct fs

* ---- Controls
gen female = (ragender==2)
gen rural  = hh1rural
gen age    = r1agey
gen adl    = r1adlfive
gen lnwealth = asinh(hh1atotb)
gen work   = r1work

* ---- Weights and clustering
gen wt = r1wtresp
gen psu_proxy = hh1state                     // no PSU/strata in harmonized file
svyset psu_proxy [pw=wt]

* ---- Missing-data audit
misstable summarize ls3 cesd pov_abs rec_any give_any nchild partnered coreside age female rural adl
count if !missing(ls3,pov_abs,rec_any,give_any,famstruct,age,female,rural,adl,lnwealth)
save "$OUT/lasi_analytic.dta", replace
log close
