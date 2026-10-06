# Variable availability audit: Harmonized LASI A.3 and Harmonized MHAS C.2

Source: the two codebooks in the repository root (text extracted with `pdftotext`; names verified against the codebook body, not from memory).
Harmonized files use lower-case names in Stata. `w` = wave number, `R` = respondent, `S` = spouse, `H` = household (respondent + spouse), `HH` = household unit.
**No CHARLS codebook is in the repository, so CHARLS availability is not audited.**

## Structural constraints (these determine the design)

| Issue | LASI A.3 | MHAS C.2 |
|---|---|---|
| Waves | Wave 1 only (2017-19; n = 73,408 R). **Cross-section.** | Waves 1-5 (2001, 2003, 2012, 2015, 2018). Panel, wide format. |
| Transfer recall window | Past year (individual R) | Last **two** years for `HwFCANY`/`HwTCANY` (household, R + spouse); amounts rescaled to annual by MHAS |
| Transfer amounts | `R1FREC`, `R1TGIV`, `R1FTOT` (imputed, flagged) | `HwFCAMT`, `HwTCAMT` (imputed). **Wave 5: no amounts, only any/none.** Waves 1-2 are halved 2-year totals; waves 3-4 are monthly x 12. |
| Poverty indicator | `HH1POVERTY` (consumption, USD 1.90/day, 2011 PPP, per capita) | **None.** Must be constructed from `HwITOT` or `HHwCTOT1M`. |
| Design variables | No PSU or strata in harmonized file; `HH1STATE` only | `RwWTRESP`, `RwWTHH`; no PSU or strata |
| Life satisfaction | `R1LSATSC` (1-7 mean), `R1LSATSC3` (1-3, higher = more satisfied) | `RwLSATSC3` (1-3, same direction, **waves 3-5 only**), `RwSATLIFE_M` (1 agree to 3 disagree, **reverse**; waves 3+) |
| Depressive symptoms | `R1CESD10` (0-30, higher = worse) | `RwCESD_M` (0-9, higher = worse; waves 1-5; different item set) |
| Child-level data (who gives, which child) | Not in harmonized file | Not in harmonized file |

## Constructs and variables

| Construct | LASI (w1) | MHAS (w1-5) |
|---|---|---|
| Transfers from children/grandchildren: any | `r1fcany` | `h{w}fcany` |
| Transfers to children/grandchildren: any | `r1tcany` | `h{w}tcany` |
| Transfers received / given (amount) | `r1frec`, `r1tgiv`, `r1ftot` (net), flags `r1ffrec`, `r1ftgiv` | `h{w}fcamt`, `h{w}tcamt` (flags `h{w}fcflag`, `h{w}tcflag`) |
| Transfers from parents / others | `r1fpany`, `r1foany`, `r1tpany`, `r1toany` | not found in codebook |
| Number of living children | `r1child` (deceased: `r1dchild`) | `h{w}child` (`h{w}dchild`) |
| Grandchildren | `r1grchild` | `h{w}grchild` |
| Co-residence with child | `r1coresd` | `h{w}coresd` |
| Child lives nearby | `r1lvnear` | `h{w}lvnear` |
| Weekly contact with children | not found | `h{w}kcnt` |
| Living arrangement (1 alone, 2 spouse only, 3 children only, 4 spouse + children, 5 other combos) | `r1lvwith` | not found |
| Marital status | `r1mstat`, `r1mstath`, `h1cpl` | `r{w}mstat`, `h{w}cpl` |
| Siblings | `r1livsib` | `r{w}livsib` |
| Household size | `hh1hhres` | `h{w}hhres` |
| Household income | `hh1itot` (includes private transfers `hh1ipxfr`) | `h{w}itot` |
| Household consumption | `hh1ctot` (annual), `hh1cperc` (per capita) | `hh{w}ctot1m` (monthly) |
| Wealth | `hh1atotb` | `h{w}atotb`, `h{w}atotf` |
| Public pension / government transfer income | `r1pubpeni`, `hh1igxfr` | `r{w}isret`, `r{w}igxfr` |
| Poverty | `hh1poverty` | construct |
| Subjective well-being | `r1lsatsc3`, `r1lsatsc`, `r1cesd10`, `r1satwlife`, `r1ydlonely` | `r{w}lsatsc3`, `r{w}satlife_m`, `r{w}cesd_m` |
| Controls | `r1agey`, `ragender`, `r1educl`, `hh1rural`, `r1caste`, `r1relig_l`, `r1shlt`, `r1adlfive`, `r1work` | `r{w}agey`, `ragender`, `r{w}educl` (via `raeduc`), `h{w}rural`, `r{w}shlt`, `r{w}adlfive`, `r{w}work` |
| Weight | `r1wtresp` (person), `hh1wthh` (household) | `r{w}wtresp`, `r{w}wthh` |

Items to confirm against the actual `.dta` (`describe`, `codebook`): `ragender`/`raeduc` stems in MHAS and the exact name of the education variable; whether `h{w}itot` includes private transfers in MHAS (the LASI codebook states `hh1itot` does).

## Design consequences for the manuscript

1. **Poverty is not harmonized across sources.** LASI has an absolute consumption-based indicator; MHAS requires a constructed relative measure (e.g. below 50% of the weighted median equivalized income or consumption). Cross-country poverty coefficients are not comparable in level; compare standardized or within-country relative patterns.
2. **Mechanical overlap between transfers and poverty.** LASI `hh1itot` includes private transfers; consumption-based poverty reflects transfer-financed consumption. Use pre-transfer income (`hh1itot - hh1ipxfr`) for a "market-income poverty risk" measure and treat consumption poverty as an outcome of the whole system.
3. **LASI is cross-sectional.** Associations only. The panel (MHAS) supports within-person estimates, but the 2001-2003 versus 2012+ gap and wave-5 amount loss limit the amount-based analysis to waves 1-4.
4. **Transfer recall windows differ** (1 year LASI, 2 years MHAS). Report the two sources separately and avoid pooling transfer incidence.
5. **No PSU or strata.** Use `pweight` with state-clustered SEs (LASI) and person-clustered SEs (MHAS); acknowledge that design effects are not fully captured.
