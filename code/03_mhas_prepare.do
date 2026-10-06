* 03_mhas_prepare.do  Harmonized MHAS C.2: wide -> long panel, waves 1-5
* Not executed: no Stata or microdata in the authoring environment.
do code/00_config.do
log using "$OUT/logs/03_mhas_prepare.log", replace text
use "$MHAS", clear
* Stems present in codebook (confirm with -describe-): see docs/variable_availability.md
* Person identifier: CONFIRM with -describe- (candidates: unhhidnp / rahhidnp / hhidpn). Set once here.
local ID unhhidnp

* Household consumption is named HHwCTOT1M; align prefix with other household stems
forvalues w = 1/5 {
    capture rename hh`w'ctot1m h`w'ctot1m
}
keep `ID' ragender r?iwstat r?agey r?mstat r?shlt r?adlfive r?work r?cesd_m r?lsatsc3 r?wtresp r?wthh ///
     h?fcany h?tcany h?fcamt h?tcamt h?child h?coresd h?lvnear h?itot h?atotb h?hhres h?rural h?kcnt h?ctot1m

* Stems missing in some waves (lsatsc3 w1-2, amounts w5) are simply absent for those waves; -reshape- fills them with missing.
reshape long r@iwstat r@agey r@mstat r@shlt r@adlfive r@work r@cesd_m r@lsatsc3 r@wtresp r@wthh ///
    h@fcany h@tcany h@fcamt h@tcamt h@child h@coresd h@lvnear h@itot h@atotb h@hhres h@rural h@kcnt h@ctot1m, ///
    i(`ID') j(wave)
foreach v in iwstat agey mstat shlt adlfive work cesd_m lsatsc3 wtresp wthh {
    rename r`v' `v'
}
foreach v in fcany tcany fcamt tcamt child coresd lvnear itot atotb hhres rural kcnt ctot1m {
    rename h`v' `v'
}
keep if iwstat == 1
keep if agey >= 60 & !missing(agey)

* ---- Well-being
gen ls3  = lsatsc3                        // waves 3-5; higher = more satisfied
gen cesd = cesd_m                         // 0-9; higher = worse

* ---- Poverty (constructed; no official indicator in MHAS)
gen eq_inc  = itot / sqrt(hhres)                    // annual household income, sqrt equivalized (pesos, nominal)
gen eq_cons = (ctot1m*12) / sqrt(hhres)
* wave-specific relative poverty: <50% of weighted wave median
foreach v in eq_inc eq_cons {
    gen pov_`v' = .
    forvalues w = 1/5 {
        quietly summarize `v' [aw=wtresp] if wave==`w', detail
        replace pov_`v' = (`v' < 0.5*r(p50)) if wave==`w' & !missing(`v')
    }
}

* ---- Reciprocity (household-level, last 2 years; amounts annualized by MHAS, waves 1-4)
gen recip = .
replace recip = 0 if fcany==0 & tcany==0
replace recip = 1 if fcany==1 & tcany==0
replace recip = 2 if fcany==0 & tcany==1
replace recip = 3 if fcany==1 & tcany==1

* ---- Family structure
gen partnered = inlist(mstat,1,3) if !missing(mstat)   // CONFIRM MHAS mstat codes (same harmonized coding as LASI expected)
gen kids = cond(child==0,0,cond(child<=2,1,2)) if !missing(child)
gen famstruct = .
replace famstruct = 1 if child==0 & partnered==0
replace famstruct = 2 if child==0 & partnered==1
replace famstruct = 3 if child>0  & partnered==0 & coresd==0
replace famstruct = 4 if child>0  & partnered==0 & coresd==1
replace famstruct = 5 if child>0  & partnered==1 & coresd==0
replace famstruct = 6 if child>0  & partnered==1 & coresd==1
gen female = (ragender==2)

xtset `ID' wave
save "$OUT/mhas_long.dta", replace
log close
