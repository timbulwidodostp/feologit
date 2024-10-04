*! version 1.1.0  17july2018
/* margins postestimation for feologit, [and others...] */
program define logitmarg, eclass prop(fvaddcons)
	syntax [if] [in] [, ///
		Outcome(string)		///  
		dydx(varlist)	///
		eretstore		///
		noOFFset		///
		NOEsample		///
		noHeader		///
	]

//Check for feologit
if !inlist("`e(cmd)'", "feologit") {
	di as err "Warning: logitmarg should only be used after feologit estimation; logistic functional form assumed"
	//exit 198
}

//Parse options	
tempvar esamp
if "`noesample'" == "" {
	gen `esamp' = e(sample)
}
else {
	gen `esamp' = 1
}


//Preserve data
marksample touse 
preserve 

	
//Retrieve parameters
local depvar = e(depvar)
local ncats = e(k_cat)
local clustvar = e(clustvar)
local ecmd = e(cmd)
local estopt = e(estopt)
tempname mcat
mat `mcat' = e(cat)

if "`estopt'" == "thresholds" {
	//Get e(b) and e(V) excluding thresholds
	tempname bmat vmat varvec
	mat `bmat' = e(b)
	local nvars = colsof(`bmat')
	mat `bmat' = `bmat'[1, 1..`=`nvars'-`ncats'+1']
	mat `vmat' = e(V)
	mat `vmat' = `vmat'[1..`=`nvars'-`ncats'+1', 1..`=`nvars'-`ncats'+1']
}
else {
	//Get e(b) and e(V)
	tempname bmat vmat varvec
	mat `bmat' = e(b)
	mat `vmat' = e(V)
}
local nvars = colsof(`bmat')
local bnames : colnames `bmat'
mat `varvec' = vecdiag(`vmat')


//Remove omitted variables from coeff matrix
tempname mo bflag
_ms_omit_info `bmat'
mat `mo' = r(omit) 
mat `bflag' = J(1,`nvars',1)
mat `bflag' = `bflag'-`mo'
mat colnames `bflag' = `bnames'

//Get varlist and match to coefficients
if "`dydx'" == "" {
	local varlist = "`bnames'"
}
else {
	tempname specflag
	mat `specflag' = `bflag'*0
	local varlist = "`dydx'"
	foreach x in `varlist' {
		local ind = 1
		foreach y in `bnames' {
			if "`x'" == "`y'" | strmatch("`y'","*.`x'") | strmatch("`y'","*.`x'#*") {
			//match found
				mat `specflag'[1,`ind'] = 1
			}
			local ind = `ind'+1
		}
	}
}

//Final list of variables
if "`dydx'" != "" {
	mata: BF = st_matrix("`bflag'") :* st_matrix("`specflag'")
	mata: st_matrix("`bflag'", BF)
	mat colnames `bflag' = `bnames'
}
tempname tempm
mata: temp = rowsum(st_matrix("`bflag'"))
mata: st_matrix("`tempm'", temp)
local nfvars = `tempm'[1,1]


//Remove omitted and not requested variables from b and V
tempname bfin vfin vtemp
mat `vfin' = J(`nfvars',`nfvars',.)
local ind = 1
foreach y in `bnames' {
	local i = colnumb(`bflag',"`y'")
	if `bflag'[1,`i'] == 1 { //Keep variable
		if `ind' == 1 {
			mat `bfin' = `bmat'[1,`i']
			mat `vtemp' = `vmat'[1...,`i']
			local varnames = "`y'"
			local ind = 99
		}
		else {
			mat `bfin' = (`bfin',`bmat'[1,`i'])
			mat `vtemp' = (`vtemp',`vmat'[1...,`i'])		
			local varnames = "`varnames' `y'"
		}
	}
}
//Clean up var-covar matrix
local ind = 1
forvalues i=1/`nvars' {
	if `bflag'[1,`i'] == 1 { //Keep variable
		mat `vfin'[`ind',1] = `vtemp'[`i',1...]
		local ind = `ind'+1
		
	}
}


//Save copy of eret
tempname tempest
qui estimates store `tempest'

//Get sample probabilities
tempvar dk 
tempname cdfj 
if "`ncats'" == "." {  //Make binary assumption if not a categorical estimation
	local ncats = 2
	di as err "Warning: number of categories not found in ereturn; binary dependent variable assumed"
	qui gen `dk'1 = 1 if `depvar' == 0
	qui replace `dk'1 = 0 if `depvar' != 0 & `depvar' != .
	qui gen `dk'2 = 1-`dk'1 if `depvar' != .
}
else {	//Otherwise as normal
	qui tab `depvar' if `touse' & `esamp' == 1, g(`dk')
	if `r(r)' < `ncats' { //Should be impossible?
		local ncats = r(r)
		di as err "Warning: number of categories greater than unique dependent variable values"
	}
}
mat `cdfj' = J(1,`ncats',.)
//Calculations
forvalues i=1/`ncats' {
	if "`clustvar'" == "" | "`clustvar'" == "."{
		qui reg `dk'`i' if `touse' & `esamp' == 1
	}
	else {
		qui reg `dk'`i' if `touse' & `esamp' == 1, cluster(`clustvar')
	}
	if `i' == 1 { // first category base
		mat `cdfj'[1,`i'] = _b[_cons]
	}
	else { // all other categories accumulate
		mat `cdfj'[1,`i'] = `cdfj'[1,`i'-1]+_b[_cons]
	}
}
// observations used in regression
local estn = e(N)
local estnclust = e(N_clust) // for consistency with initial estimation


//Construct logistic derivates
tempname logdev
forvalues j=1/`ncats' {
	scalar `logdev'`j' = `cdfj'[1,`j']*(1-`cdfj'[1,`j'])
}
scalar `logdev'0 = 0


//Marginal effects point estimates
tempname gblock gmat memat mematvar
mat `memat' = J(1,`=`nfvars'*`ncats'',.)
//Loop: categories
forvalues i=1/`nfvars' {
	//Loop: variables
	forvalues j=1/`ncats' {
		//Marginal effect
		mat `memat'[1,`=`ncats'*(`i'-1)+`j''] = ( `logdev'`=`j'-1' - `logdev'`j' )*`bfin'[1,`i']
	}
}

//Calculate variances taking sample probabilities as exact population
mat `gblock' = J(`ncats',1,.)
forvalues j=1/`ncats' {
	mat `gblock'[`j',1] = ( `logdev'`=`j'-1' - `logdev'`j' ) //Vector of derviatives
}
mat `gmat' = I(`nfvars')#`gblock'
//Delta method but taking sample probabilities as exact population
mat `mematvar' = `gmat'*`vfin'*`gmat''



//Correct names of matrices
foreach x in `varnames' {
	forvalues i=1/`ncats' {
		local eqlist "`eqlist' `x':"
		local collist "`collist' `i'"
	}
}	
matrix coleq `memat' = `eqlist'
matrix colnames `memat' = `collist'
matrix coleq `mematvar' = `eqlist'
matrix roweq `mematvar' = `eqlist'
matrix colnames `mematvar' = `collist'
matrix rownames `mematvar' = `collist'

//copy
tempname mmcopy mmvcopy
mat `mmcopy' = `memat'
mat `mmvcopy' = `mematvar'


if "`outcome'" == "" {
	eret clear 
	eret post `memat' `mematvar'
	eret sca N = `estn'
	eret sca N_clust = `estnclust'
	eret loc est_opt = "`estopt'"
	eret loc est_cmd = "`ecmd'"
	eret loc cmdline = "logitmarg `0'"
	eret loc cmd = "logitmarg"
	//Display table
	if "`header'" == "" {
		logitmarg_header
	}
	_coef_table, coeftitle(Margin)
}
else {
	// Get outcome choice
	eret loc depvar = "`depvar'"  
	eret sca k_cat = `ncats'
	eret mat cat = `mcat'
	Eq `outcome'
	local i `s(icat)'
	sret clear
		
	// Make e(b) and e(V) for outcome
	tempname mmout mmvout
	mat `mmout' = J(1,`nfvars',0)
	mat `mmvout' = J(`nfvars',`nfvars',0)
	local j = 1
	foreach x in `varnames' {
		mat `mmout'[1,`j'] = `memat'[1,"`x':`i'"]
		mat `mmvout'[`j',`j'] = `mematvar'["`x':`i'","`x':`i'"]
		local oeqlist "`oeqlist' `x':"
		local ocollist "`ocollist' `i'"
		local j = `j'+1
	}	
	matrix coleq `mmout' = `oeqlist'
	matrix colnames `mmout' = `ocollist'
	matrix coleq `mmvout' = `oeqlist'
	matrix roweq `mmvout' = `oeqlist'
	matrix colnames `mmvout' = `ocollist'
	matrix rownames `mmvout' = `ocollist'
	
	// Load eret with only outcome values
	eret clear 
	eret post `mmout' `mmvout'
	eret sca N = `estn'
	eret sca N_clust = `estnclust'
	
	//Display table
	if "`header'" == "" {
		logitmarg_header
	}
	_coef_table, coeftitle(Margin)
	
	// Reload full eret
	eret clear 
	eret post `memat' `mematvar'
	eret sca N = `estn'
	eret sca N_clust = `estnclust'
	eret loc est_opt = "`estopt'"
	eret loc est_cmd = "`ecmd'"
	eret loc cmdline = "logitmarg `0'"
	eret loc cmd = "logitmarg"
}



// Load rreturn & Restore feologit estimates
if "`eretstore'" == "" {
	qui estimates restore `tempest'
	rreturn `estn' `estnclust' `ecmd' "`0'" `estopt' `mmcopy' `mmvcopy'
}


end




//-------------------------------------------
// Program - r return instead of e return
program rreturn, rclass
args estn estnclust ecmd naught estopt memat mematvar

return clear 

return mat V = `mematvar'
return mat b = `memat'

return sca N_clust = `estnclust'
return sca N = `estn'

ret loc est_opt = "`estopt'"
ret loc est_cmd = "`ecmd'"
ret loc cmdline = "logitmarg `naught'"
ret loc cmd = "logitmarg"


end

//-------------------------------------------
// Program - parse outcome choice (from ologit_p.ado)
program define Eq, sclass
	sret clear
	local out = trim(`"`0'"')
	if bsubstr(`"`out'"',1,1)=="#" {
		local out = bsubstr(`"`out'"',2,.)
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

	Chk confirm number `out'
	local i 1
	while `i' <= e(k_cat) {
		if `out' == el(e(cat),1,`i') {
			sret local icat `i'
			exit
		}
		local i = `i' + 1
	}

	di in red `"outcome `out' not found"'
	Chk assert 0 /* return error */
end

//-------------------------------------------
// Program - Check outcome option (from ologit_p.ado)
program define Chk
	capture `0'
	if _rc {
		di in red "outcome() must either be a value of `e(depvar)'," /*
		*/ _n "or #1, #2, ..."
		exit 111
	}
end



//-------------------------------------------
// Program - header specs for table
program logitmarg_header
	version 9
	if !c(noisily) {
		exit
	}

	tempname left right
	.`left' = {}
	.`right' = {}

	local is_svy = "`e(prefix)'" == "svy"
	local is_margins = "`e(cmd)'" == "margins"
	if `is_margins' {
		local is_svy 0
	}
	local is_prefix = "`e(prefix)'" != "" 
	if `is_svy' {
		if "`rclass'" != "" {
			local 0 ", rclass"
			syntax [, NONOPTION ]
			exit 198
		}
		local e e
	}
	else {
		if "`rclass'" == "" {
			local e e
		}
		else	local e r
	}
	if "`e'" == "e" {
		is_svysum `e(cmd)'
		local is_sum `r(is_svysum)'
	}
	else {
		local is_sum 0
	}
	if `is_svy' {
		local is_tab = "`e(cmd)'" == "tabulate"
	}
	else	local is_tab 0

	if `is_sum' {
		local width 62
		local C1 _col(1)
		local c2 18
		local c3 37
		local c4 54
		local c2wfmt 7
		local c4wfmt 7
		local scheme compact
	}
	else if `is_prefix' {
		local width 78
		local C1 _col(1)
		local c2 20
		local c3 49
		local c4 68
		local c2wfmt 9
		local c4wfmt 9
		local scheme svy
	}
	else {
		local width 78
		local C1 _col(1)
		local c2 16	
		local c3 49
		local c4 67
		local c2wfmt 10
		local c4wfmt 10
		local scheme ml
	}

	if `is_svy' {
		local maxlen = `width'-`c2'-(`c2wfmt'+2)-2-(`c4'-`c3')-2
		if `maxlen' > 19 {
			local maxlen 19
		}
		local len : display %`maxlen'.0f e(N_pop)
		local len : list retok len
		local len : length local len
		local ++maxlen
		local ++len
		if `c4wfmt' <= `len' & `len' <= `maxlen' {
			local c3 = `c3' + `c4wfmt' - `len'
			local c4 = `c4' + `c4wfmt' - `len'
			local c4wfmt = `len'
		}
	}

	local C2 _col(`c2')
	local C3 _col(`c3')
	local C4 _col(`c4')
	if "`septitle'" == "" {
		local max_len_title = `c3' - 2
	}
	else {
		local max_len_title = 0
	}
	local sfmt %13s
	local ablen 14

	local c4wfmt1 = `c4wfmt' + 1
	if "`e'" == "r" & "`r(cmd)'" == "permute" {
		local is_prefix 1
	}

	if "`rules'" == "" & "`e(rules)'" == "matrix" ///
	 & inlist("`e(cmd)'","logistic","logit","probit") {
		if el(e(rules),1,1) != 0 {
			tempname rules
			matrix `rules' = e(rules)
			di
			_binperfout `rules'
		}
	}

	// display title
	local title  "Marginal effects at the average"


	// Left hand header *************************************************



	// Right hand header ************************************************

	// display N obs
//AB modify label
	if !missing(`e'(N)) {
		.`right'.Arrpush				///
			`C3' "N. of observations" `C4' "= "		///
			as res %`c4wfmt'.0f `e'(N)
	}

	
//AB modify if clause below so clusters shown as individuals/units	
	if !`is_svy' & !missing(`e'(N_clust)) { 
	 //& "`cluster'``e'(clustvar)'" == "" {
		if "`scheme'" != "svy" {
			local NumClust "N. of panel units"
		}
		else {
			local NumClust "Number of panel units"
		}
		.`right'.Arrpush				///
			`C3' "`NumClust'" `C4' "= "		///
			as res %`c4wfmt'.0f `e'(N_clust)
	}


	// number of elements in the left header
	local kl = `.`left'.arrnels'
	if `"`title'"' != "" & `kl' == 0 {
		// make title line part of the header if it fits
		local len_title : length local title
		if `"`title2'"' != "" {
			local len_title = ///
			max(`len_title',`:length local title2')
		}
		if `len_title' < `max_len_title' {
			.`left'.Arrpush `"`"`title'"'"'
			local title
			if `"`title2'"' != "" {
				.`left'.Arrpush `"`"`title2'"'"'
				local title2
			}
		}
	}
	

	Display_lg `left' `right' `"`title'"' `"`title2'"'

end

//-------------------------------------------
// Program - display header
program Display_lg
	args left right title title2

	local nl = `.`left'.arrnels'
	local nr = `.`right'.arrnels'
	local K = max(`nl',`nr')

	di
	if `"`title'"' != "" {
		di as txt `"`title'"'
		if `"`title2'"' != "" {
			di as txt `"`title2'"'
		}
		if `K' {
			di
		}
	}

	local c _c
	forval i = 1/`K' {
		di as txt `.`left'[`i']' as txt `.`right'[`i']'
	}
end


exit
