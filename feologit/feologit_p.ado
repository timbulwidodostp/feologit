*! version 2.1.0  13Feb2019
/* predict for feologit*/
/* adapted from ologit_p */
/* score as per clogit_p */
program define feologit_p 
	version 9, missing

/* Parse. */

	syntax [anything] [if] [in] [, SCores * ]
	
	if `"`scores'"' != "" {
		if "`e(keepsample)'" == "dichotomised" {
			//GenScoresCL `0'
			di as err ///
			"option scores currently not available"
			exit 198
		}
		else {
			//GenScores `0'
			di as err ///
			"option scores currently not available"
			exit 198
		}
		exit
	}
	
	if index(`"`anything'"',"*") {
		ParseNewVars `0'
		local varspec `s(varspec)'
		local varlist `s(varlist)'
		local typlist `s(typlist)'
		local if `"`s(if)'"'
		local in `"`s(in)'"'
		local options `"`s(options)'"'
	}
	else {
		local varspec `anything'
		syntax [newvarlist] [if] [in] [, * ]
	}
	local nvars : word count `varlist'

	ParseOptions, `options'
	local type `s(type)'
	local outcome `s(outcome)'
//	local d1 `"`s(d1)'"'
//	local hasd1 : length local d1
//	local d2 `"`s(d2)'"'
//	local hasd2 : length local d2

	if "`type'" != "" {
		local `type' `type'
	}
	else {
		if "`e(estopt)'" != "thresholds"{
			di as txt ///
			"(option {bf:xb} assumed; linear prediction)"
			local type "xb"
		}
		else {
			di as txt ///
			"(option {bf:pu0} assumed; predicted probability assuming fixed effect is zero)"
		}
	}
	version 6, missing

/* Check syntax. */

	if `nvars' > 1 {
		MultVars `varlist'
		if `"`outcome'"' != "" {
			di as err ///
"option outcome() is not allowed when multiple new variables are specified"
			exit 198
		}
	}
	else if inlist("`type'","","pu0") & `"`outcome'"' == "" {
		local outcome "#1"
	}
	else if !inlist("`type'","","pu0") & `"`outcome'"' != "" {
		di in smcl as err ///
"{p 0 0 2}option outcome() cannot be specified with option `type'{p_end}"
		exit 198
	}

/* Index, XB, or STDP. */
	if "`type'"=="index" | "`type'"=="xb" | "`type'"=="stdp" {

		Onevar `type' `varlist'

		if e(df_m) != 0 | ("`e(offset)'"!="" & "`offset'"=="") {
			_predict `typlist' `varlist' `if' `in', `type' `offset'
		}
		else	gen `typlist' `varlist' = . `if' `in'

		if "`type'"=="index" | "`type'"=="xb"  {
			label var `varlist' /*
			*/ "Linear prediction (cutpoints excluded)"
		}
		else { /* stdp */
			label var `varlist' /*
			*/ "S.E. of linear prediction (cutpoints excluded)"
		}
		exit
	}
	
/* If Basic estimation and not Index, XB, or STDP. */
	if "`e(estopt)'" != "thresholds" {
		di as err ///
"Option `type' not allowed after basic feologit estimation." _n ///
"Use thresholds option with feologit estimation to then predict pu0."
		exit 184
	}


/* If here we compute probabilities.  Do general preliminaries. */
	//Stata 15 version this is "/cut"
	local cut "/:cut" /* _b[/cut1] */

	if "`e(cmd)'"=="feologit" {
		local func  "1/(1+exp("
		local funcn "1-1/(1+exp("
		local cmd feologit
		local cutadj = e(cut1)
	}
	else {
		di as err ///
"feologit_p should only be used after feologit estimation"
		exit 119	
	}

//STATA 15 needed
local hasx 1
/*
	_ms_lf_info
	
	if r(k_lf) == 1 {
		local hasx = r(k1) >= e(k_cat)
	}
	else if r(k_lf) == e(k_cat) {
		local hasx 1
	}
	else {
		local hasx 0
	}
*/
	if `hasx' {
		tempvar xb
		qui _predict double `xb' `if' `in', xb `offset'
	}
	else if "`e(offset)'"!="" & "`offset'"=="" {
		local xb `e(offset)'
	}
	else	local xb 0

/* Probability with outcome() specified: create one variable. */
	if ("`type'"=="pu0" | "`type'"=="") & `"`outcome'"'!="" {
		Onevar "p with outcome()" `varlist'
		Eq `outcome' 	//Find which outcome(), index 1:k_cat
		local i `s(icat)'
		local im1 = `i' - 1
		sret clear

		if `i' == 1 {
			gen `typlist' `varlist' = /*
			*/ `func'`xb'-_b[`cut'1]-`cutadj')) /*
			*/ `if' `in'
		}
		else if `i' < e(k_cat) {
			gen `typlist' `varlist' = /*
			*/   `func'`xb'-_b[`cut'`i']-`cutadj')) /*
			*/ - `func'`xb'-_b[`cut'`im1']-`cutadj')) /*
			*/ `if' `in'
		}
		else {
			gen `typlist' `varlist' = /*
			*/ `funcn'`xb'-_b[`cut'`im1']-`cutadj')) /*
			*/ `if' `in'
		}
		local val = el(e(cat),1,`i')
		label var `varlist' "Pr(`e(depvar)'==`val')"
		exit
	}



/* Probabilities with outcome() not specified: create e(k_cat) variables. */

	tempvar touse
	mark `touse' `if' `in'

	tempname miss
	local same 1
	mat `miss' = J(1,`e(k_cat)',0)

	quietly {
		local i 1
		while `i' <= e(k_cat) {
			local typ : word `i' of `typlist'
			tempvar p`i'
			local im1 = `i' - 1

			if `i' == 1 {
				gen `typ' `p`i'' = /*
				*/ `func'`xb'-_b[`cut'1]-`cutadj')) /*
				*/ if `touse'
			}
			else if `i' < e(k_cat) {
				gen `typ' `p`i'' = /*
				*/   `func'`xb'-_b[`cut'`i']-`cutadj')) /*
				*/ - `func'`xb'-_b[`cut'`im1']-`cutadj')) /*
				*/ if `touse'
			}
			else {
				gen `typ' `p`i'' = /*
				*/ `funcn'`xb'-_b[`cut'`im1']-`cutadj')) /*
				*/ if `touse'
			}

		/* Count # of missings. */

			count if `p`i''>=.
			mat `miss'[1,`i'] = r(N)
			if `miss'[1,`i']!=`miss'[1,1] {
				local same 0
			}

		/* Label variable. */

			local val = el(e(cat),1,`i')
			label var `p`i'' "Pr(`e(depvar)'==`val')"

			local i = `i' + 1
		}
	}

	tokenize `varlist'
	local i 1
	while `i' <= e(k_cat) {
		rename `p`i'' ``i''
		local i = `i' + 1
	}
	ChkMiss `same' `miss' `varlist'
end



program MultVars
	syntax [newvarlist]
	local nvars : word count `varlist'
	if `nvars' == e(k_eq) {
		exit
	}
	if `nvars' != e(k_cat) {
		capture noisily error cond(`nvars'<e(k_cat), 102, 103)
		di in red /*
		*/ "`e(depvar)' has `e(k_cat)' outcomes and so you " /*
		*/ "must specify `e(k_cat)' new variables, or " _n /*
		*/ "you can use the outcome() option and specify " /*
		*/ "variables one at a time"
		exit cond(`nvars'<e(k_cat), 102, 103)
	}
end




program define ChkMiss
	args same miss
	macro shift 2
	if `same' {
		SayMiss `miss'[1,1]
		exit
	}
	local i 1
	while `i' <= e(k_cat) {
		SayMiss `miss'[1,`i'] ``i''
		local i = `i' + 1
	}
end

program define SayMiss
	args nmiss varname
	if `nmiss' == 0 { exit }
	if "`varname'"!="" {
		local varname "`varname': "
	}
	if `nmiss' == 1 {
		di in blu "(`varname'1 missing value generated)"
		exit
	}
	local nmiss = `nmiss'
	di in blu "(`varname'`nmiss' missing values generated)"
end

//Determine which outcome() to use
program define Eq, sclass
	sret clear
	local out = trim(`"`0'"')
	// If denoted as #1, #2, etc
	// (Stata 15 version uses bsubstr below)
	if substr(`"`out'"',1,1)=="#" {
		local out = substr(`"`out'"',2,.)
		Chk confirm integer number `out'
		Chk assert `out' >= 1
		capture assert `out' <= e(k_cat)
		if _rc {
			di in red "there is no outcome #`out'" _n /*
			*/ "there are only `e(k_cat)' categories"
			exit 111
		}
		sret local icat `"`out'"'

		exit
	}
	// Or if denoted as a value of depvar
	Chk confirm number `out'
	local i 1
	while `i' <= e(k_cat) {
		if `out' == el(e(cat),1,`i') {
			sret local icat `i'
			exit
		}
		local i = `i' + 1
	}
	// Or not found
	di in red `"outcome `out' not found"'
	Chk assert 0 /* return error */
end

program define Chk
	capture `0'
	if _rc {
		di in red "outcome() must either be a value of `e(depvar)'," /*
		*/ _n "or #1, #2, ..."
		exit 111
	}
end

program define Onevar
	gettoken option 0 : 0
	local n : word count `0'
	if `n'==1 { exit }
	di in red "option `option' requires that you specify 1 new variable"
	error cond(`n'==0,102,103)
end


program ParseNewVars, sclass
	version 9, missing
	syntax [anything(name=vlist)] [if] [in] [, SCores * ]

	if missing(e(version)) {
		local old oldologit
	}
	
	if "`scores'" == "" {
		local pr pr
	}

	_score_spec `vlist', `old' `pr'
	sreturn local varspec `vlist'
	sreturn local if	`"`if'"'
	sreturn local in	`"`in'"'
	sreturn local options	`"`options' `scores'"'
end

program ParseOptions, sclass
	version 9, missing
	syntax [,			///
		Outcome(string)		///
		EQuation(string)	///
		Index			///
		XB			///
		STDP			///
		PU0			///
		noOFFset		///
	]
		
		//AB removed
		//d1(string)		///
		//d2(string)		///
		
	if `"`score'"' != "" {
		di as err "score used"
		exit
	}
	// check options that take arguments
	if `"`equation'"' != "" & `"`score'"' != "" {
		di as err ///
		"options score() and equation() may not be combined"
		exit 198
	}
	if `"`score'"' != "" & `"`outcome'"' != "" {
		di as err ///
		"options score() and outcome() may not be combined"
		exit 198
	}
	if `"`equation'"' != "" & `"`outcome'"' != "" {
		di as err ///
		"options equation() and outcome() may not be combined"
		exit 198
	}
	local eq `"`score'`equation'`outcome'"'

	// check switch options
	local type `index' `xb' `stdp' `pc1' `pu0'
	if `:word count `type'' > 1 {
		local type : list retok type
		di as err "the following options may not be combined: `type'"
		exit 198
	}


	// save results
	sreturn clear
	sreturn local type	`type'
	sreturn local outcome	`"`eq'"'

end


program GenScoresCL, rclass
	version 9, missing
	syntax [anything] [if] [in] [, * ]
	
	di as txt ///
	"(scores calculated with respect to regression equation using dichotomised sample)"

	marksample touse
	_score_spec `anything', `options'
	local varn `s(varlist)'
	local vtyp `s(typlist)'
	local varn `: word 1 of `varn''
	local vtyp `: word 1 of `vtyp''
	tempname eb
	matrix `eb' = e(b)
	local cut1 = colnumb(`eb',"/:cut1")
	matrix `eb' = `eb'[1...,1..`=`cut1'-1']
	local xvars : colna `eb'
	_get_offopt `e(offset)'
	local offopt `"`s(offopt)'"'

	_clogit_lf `e(depvar)' `xvars' if `touse', ///
			group(`e(group)') score(`varn') beta(`eb') `offopt'

	label var `varn' "equation-level score from clogit"
	return local scorevars `varn'
end



program GenScores, rclass
	version 9, missing
	local cmd = cond("`e(cmd)'"=="svy","svy:","")+"`e(cmd)'"
	syntax [anything] [if] [in] [, * ]
	marksample doit
	if missing(e(version)) {
		local old oldologit
	}

	/* If Basic estimation, score cannot be created. */
	if e(estopt) != "thresholds" {
		di as err ///
"Option scores not allowed after basic feologit estimation." _n ///
"Use thresholds option with feologit estimation to then calculate scores." _n ///
"Alternatively, use the keepsample option to then calculate dichotomised scores."
		exit 184
	}
	
	_score_spec `anything', `options' `old'
	local varlist `s(varlist)'
	local typlist `s(typlist)'
	local nvars : word count `varlist'
	// (Stata 15 version uses bsubstr below)
	local spec = substr("`s(eqspec)'",2,.)
	if "`spec'" == "" {
		numlist "1/`nvars'"
		local spec `r(numlist)'
	}

	forval i = 1/`nvars' {
		local typ : word `i' of `typlist'
		local var : word `i' of `varlist'
		local eq  : word `i' of `spec'
		local score = `eq'
//AB: add quietly in below again
		CompScores `doit' `typ' `var', score(`score')

		if e(version) == 3 {
			local lcut "/cut"
		}
		else	local lcut "_cut"

		if !`score' {
			local label = "x*b"
		}
		else if e(k_eq) == e(k_cat) {
			local label = cond(`eq'==1,"x*b","`lcut'`score'")
		}
		else	local label = "`lcut'`score'"
		local cmd = cond("`e(prefix)'"=="svy","svy:","")+"`e(cmd)'"
		label var `var' "equation-level score for `label' from `cmd'"
	}
	return local scorevars `varlist'
end



program CompScores, sortpreserve
	version 9, missing
	gettoken doit 0 : 0
	syntax newvarname [, noOFFset score(integer 0) ]

	local depvar `e(depvar)'
	local cutadj = e(cut1)
	markout `doit' `depvar'

	tempvar cat cutL cutU 
	tempname cuts

	mat `cuts' = e(b)
	if colsof(`cuts') >= e(k_cat) {
		tempvar xb
		_predict `typlist' `xb' if `doit', xb `offset'
		local --score
		c_local score `score'
	}
	else if `"`e(offset)'"' != "" & `"`offset'"' == "" {
		local xb `e(offset)'
	}
	else	local xb 0

	if inlist("`e(cmd)'", "feologit") {
		//Stata 15 version this is "/cut"
		local cut1 = colnumb(`cuts',"/:cut1")
		local prog `e(cmd)'_scores
	}
	else {
		di as err ///
		"feologit_p should only be used after feologit estimation"
		exit 119
	}
	
	matrix `cuts' = `cuts'[1,`cut1'...]
	local ncut = colsof(`cuts')

	sort `doit' `depvar'
	by `doit' `depvar' : gen double `cat' = _n==1 if `doit'
	replace `cat' = sum(`cat')

	gen double `cutL' = `cutadj'+`cuts'[1,`cat'-1]-`xb' if `doit'
	gen double `cutU' = `cutadj'+`cuts'[1,`cat']-`xb' if `doit'
	mat list `cuts'

	gen `typlist' `varlist' = 0 if `doit'

	`prog' `varlist' `doit' `cat' `cutL' `cutU' `score' `ncut'
end

program feologit_scores
	args varlist doit cat cutL cutU score ncut
	if `score' == 0 | `ncut' == 1 {
		if `score' == 0 {
			local minus0 "-"
			local minus1 "-"
			local minus2 ""
		}
		else {
			local minus0 ""
			local minus1 ""
			local minus2 "-"
		}
		replace `varlist' = `minus0'(			///
			 invlogit(`cutU')*invlogit(-`cutU')	///
			-invlogit(`cutL')*invlogit(-`cutL')	///
			) / (invlogit(`cutU')-invlogit(`cutL'))	///
			if `doit'
		replace `varlist' = `minus1'invlogit(-`cutU')	///
			if `doit' & missing(`cutL')
		replace `varlist' = `minus2'invlogit(`cutL')	///
			if `doit' & missing(`cutU')
	}
	else if `score' == 1 {
		replace `varlist' = invlogit(-`cutU')		///
			if `doit' & `cat' == `score'
		replace `varlist' =				///
			-invlogit(`cutL')*invlogit(-`cutL') /	///
			(invlogit(`cutU')-invlogit(`cutL'))	///
			if `doit' & `cat' == `score'+1
	}
	else if `score' == `ncut' {
		replace `varlist' = -invlogit(`cutL')		///
			if `doit' & `cat' == `score'+1
		replace `varlist' =				///
			 invlogit(`cutU')*invlogit(-`cutU') /	///
			(invlogit(`cutU')-invlogit(`cutL'))	///
			if `doit' & `cat' == `score'
	}
	else {
		replace `varlist' =				///
			 invlogit(`cutU')*invlogit(-`cutU') /	///
			(invlogit(`cutU')-invlogit(`cutL'))	///
			if `doit' & `cat' == `score'
		replace `varlist' =				///
			-invlogit(`cutL')*invlogit(-`cutL') /	///
			(invlogit(`cutU')-invlogit(`cutL'))	///
			if `doit' & `cat' == `score'+1
	}
end


exit
