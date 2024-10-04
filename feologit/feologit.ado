*! version 6.1.1  13Feb2019
cap program drop feologit
program feologit, eclass byable(recall) prop(swml or svyb svyj svyr mi fvaddcons)
	syntax [varlist(numeric ts fv)] [fw iw pw] [if] [in],[ ///
		GRoup(varname)				///
		STrata(varname)				///
		VCE(passthru)				///
		CLuster(varname)			///
		CLONes(integer 10)			///
		THresholds					///
		KEEPsample					/// Other clogit options below
		seed(integer 79846512)			///
		OR FROM(string) ///
		Level(cilevel) OFFset(varname numeric) ///
		Robust ///
		noLOg noDISPLAY noHEADer noNEST ///
		DOOPT* ///
		]
		
		

		
************* replay ************************* 
if replay() {
	if "`e(cmd)'" != "feologit" {
		error 301
	}
	if _by() { 	
		error 190  	
	}
	Display `0'
	error `e(rc)'
	exit
}		
		
		
************* check panel and get panelvar/group identifier ************************* 

local tsops = "`s(tsops)'" == "true"
local k = ("`strata'" != "") + ("`group'" != "")

//Check for time-series operators
if `tsops' {
		di as err ///
		"Time-series operators not allowed.{break}These could be constructed prior to estimation; " ///
		"{break}however, feologit assumes observations are independent over time." 
		exit 198
}

//Check group() and xtset
cap _xt
if `k' == 2 {
	di as err "strata() and group() may not be " _c
	di as err "specified at the same time"
	exit 198
}
else if `k' == 0 {
	if _rc == 0 {  //xtset panel identifier has been set
		local gid = "`r(ivar)'"	// Find variable used to determine groups/individuals in panel
		di as text "note: group() not specified; assuming group(`gid') from panel identifier"
	}
	else {  //xtset has not been set and no group()
		di as err "group({it:varname}) or xtset {it:varname} required"
		exit 198
	}
}
else { // if using group() option
	local group `group'`strata'
	if "`group'" != "`r(ivar)'" & _rc == 0 { // Warn if group() different to panelvar
		di as text "note: group() is not the same as panel identifier"
	}
	local gid = "`group'" // use group(); instead of panel identifier if xtset
}

//Check that variables "clone", "bucsample", "dkdepvar" and "dkthreshold" do not exist if using keepsample option
if "`keepsample'" != "" {
	foreach v in clone bucsample dkdepvar dkthreshold clonegroup{
		cap confirm variable `v'
		if _rc == 0 {
			di as err "one or more of variables clone, bucsample, dkdepvar or dkthreshold already exist;{break}" ///
				"rename to use option keepsample"
			exit 198
		}
	}
}

//Manually create time variable (also used to calculate observations)
tempvar faketvar
qui bysort `gid': gen `faketvar' = _n
//Get time var
if "`r(tvar)'" == "" {  //using group() or xtset with no time identifier
	local tvar "`faketvar'"
}
else {
	local tvar "`r(tvar)'"
}

// Determine clustering
if "`cluster'" == "" {
	local cluster = "`gid'"
}
else if "`cluster'" != "`gid'" {
	di as text "warning: cluster variable is not the same as group identifier;{break}" ///
		"user is responsible for validity"
}

//Save seed, preserve data
marksample touse 
local oldseed = "`c(seed)'"
preserve 
set seed `seed'

// Get display and ml options
_get_diopts diopts options, `options'
mlopts mlopts, `options' `vce'


************* parse regression variables *************************   

gettoken (global)gdepvar (local)xvars : (local)varlist  
// Generate cat matrix
tempname cat
_rmcoll $gdepvar , ologit expand
matrix `cat' = r(cat)

//Exit if no indepvars
if "`xvars'" == "" {  
	di as err "independent variable(s) required"
	exit 198
}

// Expand factor variables for naming xvars
_rmcoll `xvars', expand
local xvarlist `r(varlist)'
local nxvars : word count `xvarlist'


// Mark collinear
tempname b mo
matrix `b' = J(1, `nxvars', 0)
matrix colnames `b' = `xvarlist'
_ms_omit_info `b'
matrix `mo' = r(omit)
local nomit = r(k_omit)
matrix colnames `mo' = `xvarlist'


// recode depvar
tempvar dvnorm dvtemp
qui tab $gdepvar, gen(`dvtemp')
qui gen `dvnorm' = .
forvalues i=1/`r(r)' {
	qui replace `dvnorm' = `i' if `dvtemp'`i' == 1 
}
qui drop `dvtemp'*

// organise cuts
qui sum `dvnorm'                                                  
local lk = r(min)					// minimum of y
local hk = r(max)					// maximum of y
local ncut = `hk' - 1


//Check if binary dependent variable
if `hk'-`lk' == 1 {
	di as text "Dependent variable is binary, not ordered. Running clogit..."
}

if `hk'-`lk' == 1 {	  // Check if binary dependent variable
	//Run clogit
	local bopts = substr("`0'",strpos("`0'",","),.)
	clogit $gdepvar `xvarlist' [`weight'`exp'] `if' `in' `bopts'  // regression
	exit
}

************* blow up  ******************************	// expand data set

//Blow up dataset
tempvar iid cid bid gidcid cut r dk dkt samp gtid cutvars cloneflag
qui egen `gtid' = group(`gid' `tvar')	// ID for individual panel unit observation
local pc = `=`hk'-`lk''
sort `gid' `tvar'
if "`thresholds'" == "" { // base estimation, no additional (random) clones
	local clones = 0
	qui expand `pc' if `touse', gen(`cloneflag')
}
else { // thresh estimation, use clones
	qui expand `clones'+`pc' if `touse', gen(`cloneflag')
}

//Mark clones, base sample and generate dichotomised depvar
sort `gid' `tvar' `cloneflag'
qui by `gid' `tvar': gen long `cid'=_n if `touse'  // cid is clone id
qui gen `bid' = 1 if `cid' <= `pc'		// base estimation sample marker
qui egen long `gidcid' = group(`gid' `cid') if `touse'  // gidcid separates individuals and groups one clone from each time period
//AB: Following command requires ordered depvar to be 0, 1, 2, etc
qui gen `dk'= (`dvnorm'>=`cid'+1)*`bid' if `touse' 				// dep. var in clogit 

//Variables for keepsample
if "`keepsample'" != "" {
	qui gen clone = `cloneflag'
	qui gen bucsample = .
	qui replace bucsample = 0 if `touse'
	qui replace bucsample = 1 if `bid'==1
	qui gen dkdepvar = `dk'
	qui gen dkthreshold = `cid'
	qui gen clonegroup = `gidcid'
}


************* estimate  ******************************

if "`thresholds'" == "" {  // Check base estimation required
//Start basic estimation

	************** regress ******************************	// clogit estimation
	clogit_buc `dk' `xvars' [`weight'`exp'] `if' `in', ///
	group(`gidcid') cluster(`cluster') `mlopts'  ///
	from(`from') offset(`offset') `log' score(`score') `nest'  

	// Make labels for ereturn repost matrices
	local cnames `xvarlist'
	// Record sample
	gen `samp' = e(sample)

//End basic estimation	
}
else {  // Otherwise threshold estimation required
//Start thresh estimation

	//Generate variables for randomly dichotomised clones
	qui gen `r'=uniform() if `touse'
	qui gen `cut'=. if `touse'
	foreach c of num `=`lk'+1'/`hk' {
		qui replace `cut'= `c' if `r'<1/(`pc')*(`c'-1) & `r'>1/(`pc')*(`c'-2) & `touse'
	}
	qui replace `cut'=`cid'+`lk' if `cid' <= `pc' & `touse'
	qui gen `dkt'=cond(`dvnorm'>=`cut',1,0) if `touse'
	foreach c of num `=`lk'+1'/`=`hk'-1'{
		gen `cutvars'`c'=cond(`cut'==`c'+1,-1,0) 
	}
	tempname holdercut1
	qui gen `holdercut1' = 1
	
	//Variables for keepsample
	if "`keepsample'" != "" {
		qui replace dkdepvar = `dkt'
		qui replace dkthreshold = `cut'-1
	}
	
	************** regress ******************************	// clogit estimation with thresholds
	clogit_buc `dkt' `xvars' `holdercut1' `cutvars'* [`weight'`exp'] `if' `in', ///
	group(`gidcid') cluster(`cluster') `mlopts' ///
	from(`from') offset(`offset') `log' score(`score') `nest'  
	
	// Record sample
	gen `samp' = e(sample)
	
	// Make labels for ereturn repost matrices
	local cnames `xvarlist'
	foreach c of num `lk'/`=`hk'-1'{
		local cnames = "`cnames' cut`c'" 
	}
	

//End thresh estimation
}


//Store feologit eret details
eret sca clones = `clones'
eret sca seed = `seed'
eret loc group = "`group'"
eret loc cmd = "feologit"
eret loc cmdline = "feologit `0'"
eret loc predict = "feologit_p"
local mnotok = "Pr `e(marginsnotok)'"

//Store default margins command for eret
forval i = `lk'/`hk' {
	local j = `cat'[1,`i']
	local mdflt `mdflt' predict(pu0 outcome(`j'))
	local depvar_outcomes `"`depvar_outcomes' `j'"'
}
ereturn hidden local depvar_outcomes `"`:list retok depvar_outcomes'"'

//Calculate number of groups used in estimation
tempvar gused gcount tag
qui bys `gid': egen `gused' = sum(`samp') 
qui bys `gid': gen `gcount' = 1 if `gused' > 0 & _n ==1
qui sum `gcount'
local ngroup = r(sum)
eret sca N_group = `ngroup'

//Correct number of groups dropped
tempvar gtouse gtuc
qui bys `gid': egen `gtouse' = sum(`touse')
qui bys `gid': gen `gtuc' = 1 if `gtouse' > 0 & _n ==1
qui sum `gtuc'
local ngroupall = r(sum)
eret sca N_group_drop = `ngroupall'-`ngroup'


// Calculate number of true observations used in estimation
tempvar gtobused truobs
qui bys `gtid': egen `gtobused' = sum(`samp')
qui bys `gtid': gen `truobs' = 1 if `gtobused' > 0 & _n ==1
qui sum `truobs'
local ntrue = r(sum)
eret sca N_true = `ntrue'


// Add number categories of dependent variable
eret sca k_cat = `hk'
// Add values of categories of dependent variable
eret mat cat = `cat'

// Add basic, threshold or margins type
if "`thresholds'" == ""  {
	eret loc estopt = "basic"
	eret loc marginsdefault "predict(xb)"
	eret loc marginsnotok = "Pu0 `mnotok'"
	eret loc marginsok = "XB"
}
else {
	eret loc estopt = "thresholds"
	eret loc marginsdefault `"`mdflt'"'
	eret loc marginsnotok = "`mnotok'"
	eret hidden loc marginsderiv = "default Pr OUTcome(passthru)"
}
// Add sample flag to eret
if "`keepsample'" != "" {
	eret loc keepsample = "dichotomised"
}	
else {
	eret loc keepsample = "original"
}

************* Fix e(b) e(V) matrices  ****************************** 
tempname newb newV bpclass tempmat tempVbase
mat `newb' = e(b)
mat `newV' = e(V)
mat `bpclass' = e(b)


if "`thresholds'" != "" {
//If threhsolds, separate into equations and fix names

	//LOOP THROUGH xvarlist and cuts to make equation names local and bpclass
	foreach x in `xvarlist' {
		local eqlist `eqlist' $gdepvar: 
		local colindex = colnumb(`bpclass',"`x'")
		mat `bpclass'[1,`colindex'] = 0
	}	
	forvalues i=1/`=`hk'-1' {
		local eqlist `eqlist' /: 
		mat `bpclass'[1,`=`nxvars'+`i''] = 2
	}

	matrix coleq `newb' = `eqlist'
	matrix coleq `newV' = `eqlist'
	matrix roweq `newV' = `eqlist'
	matrix colnames `newb' = `cnames'
	matrix colnames `newV' = `cnames'
	matrix rownames `newV' = `cnames'
	
	//copy for modelbased V
	matrix `tempVbase' = e(V_modelbased)
	matrix coleq `tempVbase' = `eqlist'
	matrix roweq `tempVbase' = `eqlist'
	matrix colnames `tempVbase' = `cnames'
	matrix rownames `tempVbase' = `cnames'

	//repost
	ereturn repost b=`newb' V=`newV', rename buildfvinfo ADDCONS
	eret mat V_modelbased = `tempVbase'
	
	matrix coleq `bpclass' = `eqlist'
	matrix colnames `bpclass' = `cnames'
	eret hidden mat b_pclass = `bpclass'
	eret sca k_eq = e(k_eq)+1
	
}
else {
//Otherwise remove equations and fix matrix names
	
	matrix coleq `newb' = :
	matrix coleq `newV' = :
	matrix roweq `newV' = :
	matrix colnames `newb' = `cnames'
	matrix colnames `newV' = `cnames'
	matrix rownames `newV' = `cnames'
	
	//copy for modelbased V
	matrix `tempVbase' = e(V_modelbased)
	matrix coleq `tempVbase' = :
	matrix roweq `tempVbase' = :
	matrix colnames `tempVbase' = `cnames'
	matrix rownames `tempVbase' = `cnames'

	//repost
	ereturn repost b=`newb' V=`newV', rename buildfvinfo ADDCONS	
	eret mat V_modelbased = `tempVbase'
	
}
************* ****************************** 

//Save copy of eret
tempname tempest
qui estimates store `tempest'

//If threhsolds calculate (biased) estimate of cut1 
if "`thresholds'" != "" {
	tempname c1 xb c1se
	qui predict `xb', xb
	qui logit `dk' if `touse' & `bid'==1 & `cut'==2, offset(`xb') vce(cluster `cluster')
	scalar `c1' = -_b[_cons]
	scalar `c1se' = _se[_cons]
}


//Fix up dataset to return if not keeping expanded (default option)
if "`keepsample'" == "" {

	// De-expand dataset and keep temp copy of adjusted e(sample) 
	tempfile tempsamp 
	tempvar panelused
	qui bys `gtid': egen `panelused' = sum(`samp')
	qui replace `samp' = 0
	qui replace `samp' = 1 if `panelused' > 0
	qui drop if `cid' != 1
	qui sort `gid' `faketvar'
	qui keep `gid' `faketvar' `samp'
	qui save `tempsamp', replace

	//Restore original data and seed
	restore
	set seed `oldseed'

	//Set e(sample)
	tempvar merge
	sort `gid' `faketvar'
	qui merge 1:1 `gid' `faketvar' using `tempsamp', gen(`merge') 
	qui replace `samp' = 0 if `merge' != 3
	qui drop `merge'
	eret clear
	qui estimates restore `tempest'
	estimates esample: if `samp'
	eret loc _estimates_sample ""

} 
else {  //If keepsample

	//Restore eret if calculated cut1
	if "`thresholds'" != "" {
		eret clear
		qui estimates restore `tempest'
	}
	
	//Keep expanded data and retore seed
	restore, not
	set seed `oldseed'
	
	eret loc depvar = "dkdepvar"
	//eret loc group = "clonegroup"
}


if "`thresholds'" != "" {
//If threhsolds add cut1 to eret
	eret sca cut1 = `c1'
	eret hidden sca cut1_se = `c1se'
}

//Make display go now!
if "`display'" == "" {
	Display, level(`level') `or' `header' `diopts'
}

end



//Display program using modified header
program Display
	syntax [, Level(cilevel) OR noHEADer diopts *]

	//_get_diopts diopts, `options'
	if "`or'"!="" {
		local eopt "eform(Odds Ratio)"
	}

	//Display header
	if "`header'" == "" {
		_coef_table_header_buc 
	}
	
	//Display table
	version 9: ml di, level(`level') `eopt' noheader nofootnote `diopts'
	_prefix_footnote

end

