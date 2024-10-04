{smcl}
{* *! version 1.0.0  01September2018}{...}
{vieweralsosee "feologit postestimation" "help feologit postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[MI] Estimation" "help mi estimation"}{...}
{vieweralsosee "[R] logistic" "help logistic"}{...}
{vieweralsosee "[R] mlogit" "help mlogit"}{...}
{vieweralsosee "[R] nlogit" "help nlogit"}{...}
{vieweralsosee "[R] ologit" "help ologit"}{...}
{vieweralsosee "[R] scobit" "help scobit"}{...}
{vieweralsosee "[SVY] svy estimation" "help svy_estimation"}{...}
{vieweralsosee "[XT] xtgee" "help xtgee"}{...}
{vieweralsosee "[XT] xtlogit" "help xtlogit"}{...}
{viewerjumpto "Title" "feologit##title"}{...}
{viewerjumpto "Syntax" "feologit##syntax"}{...}
{viewerjumpto "Description" "feologit##description"}{...}
{viewerjumpto "Options" "feologit##options"}{...}
{viewerjumpto "Examples" "feologit##examples"}{...}
{viewerjumpto "Stored results" "feologit##results"}{...}
{viewerjumpto "References" "feologit##references"}{...}
{viewerjumpto "Authors" "feologit##authors"}{...}
{viewerjumpto "Also see" "feologit##alsosee"}{...}
{cmd:help feologit}{right: ({browse "https://doi.org/10.1177/1536867X20930984":SJ20-2: st0596})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{cmd:feologit} {hline 2}}Fixed-effects (conditional) ordered logistic
regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:feologit} 
{depvar} 
{indepvars}
{ifin}
[{it:{help feologit##weight:weight}}]{cmd:,} 
{cmdab:gr:oup:(}{varname}{cmd:)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent :* {opth gr:oup(varname)}}matched group variable{p_end}
{synopt :{opt th:resholds}}use alternative estimator that includes estimates of thresholds{p_end}
{synopt :{opt clon:es(#)}}specify number of clones used in thresholds estimation; default is {cmd:clones(10)}{p_end}
{synopt :{opt keep:sample}}specifies that the estimation sample be kept; estimation sample includes the original data as well as additional observations consisting of copies of the original data{p_end}
{synopt :{opt seed(#)}}specify random-number seed used in thresholds estimation; default is {cmd:seed(79846512)}{p_end}
{synopt :{opth off:set(varname)}}include {it:varname} in model with coefficient
constrained to 1{p_end}
{synopt :{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synopt:{opt col:linear}}keep collinear variables{p_end}

{syntab:SE/Robust}
{synopt :{opth cl:uster(clustvar)}}set the identifier variable for clustering standard errors{p_end}
{synopt :{opt nonest}}do not check that panels are nested within clusters{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is
{cmd:level(95)}{p_end}
{synopt :{opt or}}report odds ratios{p_end}
{synopt :{opt nocnsr:eport}}do not display constraints{p_end}
{synopt :{it:{help feologit##display_options:display_options}}}control
INCLUDE help shortdes-displayoptall

{syntab:Maximization}
{synopt :{it:{help feologit##maximize_options:maximize_options}}}control the maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt group(varname)} is required if {cmd:xtset} {it:panelvar} has not been specified.{p_end}
INCLUDE help fvvarlist
{p 4 6 2}
{opt bootstrap}, {opt by}, {opt jackknife}, 
{opt mi estimate}, {opt nestreg}, and {opt statsby}
are allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with the {helpb bootstrap} prefix.{p_end}
{marker weight}{...}
{p 4 6 2}
{opt fweight}s, {opt iweight}s, and {opt pweight}s are allowed
(see {help weight}), but
they are interpreted to apply to groups as a whole, not to individual
observations.{p_end}
{p 4 6 2}
See {help feologit postestimation} for features available after
estimation.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:feologit} fits a fixed-effects ordered logit model for panel data with an
ordinal variable {it:depvar} using the "blow-up and cluster" (BUC) estimator
from {help feologit##BSW2015:Baetschmann, Staub, and Winkelmann (2015)}.  This
can be considered an ordinal equivalent of the {helpb clogit} command.
The actual values taken on by the dependent variable are irrelevant, except
that larger values are assumed to correspond to "higher" outcomes.
{cmd:feologit} can also estimate the relative thresholds between categories
using the estimator from {help feologit##B2012:Baetschmann (2012)}.  Marginal
effects at the average of the dependent variable can be obtained after
estimation using the postestimation command {cmd:logitmarg}; see
{help feologit postestimation}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth group(varname)} is required if {cmd:xtset} {it:panelvar} has not been
specified; it specifies an identifier variable (numeric or string) for the
matched groups.  If a panel identifier has been set with {cmd:xtset}, the
option {opt group(varname)} may be omitted; in this case, {cmd:feologit} will
use the panel identifier and provide a warning.  {opt strata(varname)} is a
synonym for {opt group()}.

{phang}
{opt thresholds} uses an estimator that includes estimates of the relative
thresholds between categories.  The first threshold is constrained to be zero,
so all other thresholds are relative.  An estimate of the true first threshold
is contained in {cmd:e()}, but this estimate is inconsistent in general.
(Note: This option can increase the computational burden substantially.)

{phang}
{opt clones(#)} specifies the number of clones used in the
estimation when {cmd:thresholds} has been specified.  The default is
{cmd:clones(10)}.  A clone is a copy of all observations of a panel unit.

{phang}
{opt keepsample} specifies that the estimation sample be kept.  The estimation
sample includes the original data as well as additional observations
consisting of copies of the original data.  The option {opt keepsample}
generates the following new variables: 

{phang2}
{cmd:dkdepvar}, the dichotomized dependent variable used in the {cmd:clogit}
estimation step; 

{phang2}
{cmd:dkthreshold}, a variable that indicates at which cutoff point each
observation of the ordered dependent variable was dichotomized (to result in
{cmd:dkdepvar});

{phang2}
{cmd:bucsample}, a binary
variable that indicates whether the observation forms part of the estimation
sample of the BUC estimator (this variable exhibits variation only if the
option {cmd:thresholds} has been specified); 

{phang2}
{cmd:clonegroup}, an integer-valued variable
that identifies observations corresponding to each panel unit and clone in
the estimation sample; and

{phang2}
{cmd:clone}, a binary variable that indicates whether an observation is part
of the original sample ({cmd:clone}=0) or a copy ({cmd:clone}=1).

{pmore}
For instance, after BUC-tau estimation of {cmd:feologit} with the option
{cmd:keepsample}, the corresponding BUC estimates can be obtained by issuing
the following command: {cmd:clogit dkdepvar} {it:indepvars} {cmd:if}
{cmd:bucsample==1,} {cmd:group(clonegroup)}
{cmd:cluster(}{it:clustvar}{cmd:)}, where {it:indepvars} and {it:clustvar} are
the variables that were used in the BUC-tau estimation.

{phang}
{opt seed(#)} specifies the pseudo-random-number seed used in the
estimation when {cmd:thresholds} has been specified.  The default is
{cmd:seed(79846512)}.

{phang}
{opth offset(varname)},
{opt constraints(constraints)},
{opt collinear}; see
{helpb estimation options:[R] Estimation options}.

{dlgtab:SE/Robust}

{phang}
{opt cluster(clustvar)} sets the identifier variable for clustering standard
errors.  Standard errors are always clustered; specifying this option overrides
the default clustering variable, which is the group identifier.

{phang}
{opt nonest} prevents checking that matched groups are nested within clusters.
It is the user's responsibility to verify that the standard errors are
theoretically correct.

{dlgtab:Reporting}

{phang}
{opt level(#)}; see
{helpb estimation options##level():[R] Estimation options}.

{phang}
{opt or} reports the estimated coefficients transformed to odds ratios,
that is, exp(b) rather than b.  Standard errors and confidence intervals are
similarly transformed.  This option affects how results are displayed, not how
they are estimated.  {opt or} may be specified at estimation or when
replaying previously estimated results.

{phang}
{cmd:nocnsreport}; see
{helpb estimation options##nocnsreport:[R] Estimation options}.

INCLUDE help displayopts_list

{marker maximize_options}{...}
{dlgtab:Maximization}

{phang}
{it:maximize_options}:
{opt dif:ficult},
{opth tech:nique(maximize##algorithm_spec:algorithm_spec)},
{opt iter:ate(#)}, [{cmd:no}]{opt log}, {opt tr:ace}, 
{opt grad:ient}, {opt showstep},
{opt hess:ian},
{opt showtol:erance},
{opt tol:erance(#)},
{opt ltol:erance(#)}, {opt nrtol:erance(#)},
{opt nonrtol:erance}, and
{opt from(init_specs)}; see {helpb maximize:[R] Maximize}.
These options are seldom used.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nhanes2f}{p_end}
{phang2}{cmd:. sample 20}{p_end}

{pstd}Fit fixed-effects ordered logistic regression controlling for location fixed effects{p_end}
{phang2}{cmd:. feologit health age age2 sex race weight iron diabetes, group(location)}{p_end}

{pstd}Replay results, reporting odds ratios rather than coefficients{p_end}
{phang2}{cmd:. feologit, or}{p_end}

{pstd}Fit threshold regression specification {p_end}
{phang2}{cmd:. feologit health age age2 sex race weight iron diabetes, group(location) thresholds}{p_end}

    {hline}
{pstd}Setup{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}

{pstd}Recode hours for less than 1 day, part-time and full-time work{p_end}
{phang2}{cmd:. recode hours (0/6 = 1) (7/29 = 2) (30/186 = 3), gen(hourscat)}{p_end}

{pstd}Fit fixed-effects ordered logistic regression (panel data){p_end}
{phang2}{cmd:. feologit hourscat age union msp nev_mar tenure ln_wage, group(idcode)}{p_end}
    {hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:feologit} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations including observations of clones{p_end}
{synopt:{cmd:e(N_true)}}number of authentic observations (without observations
of clones){p_end}
{synopt:{cmd:e(N_group)}}number of panel units specified by {cmd:group()}{p_end}
{synopt:{cmd:e(N_drop)}}number of observations dropped because of all positive
   or all negative outcomes{p_end}
{synopt:{cmd:e(N_group_drop)}}number of groups dropped because of all positive
   or all negative outcomes{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(k_cat)}}number of categories{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(r2_p)}}pseudo-R-squared{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(ll_0)}}log likelihood, constant-only model{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}
{synopt:{cmd:e(cut1)}}rescaling factor used for {cmd:predict} and {cmd:margins}
postestimation commands (if option {cmd:thresholds} is specified){p_end}
{synopt:{cmd:e(clones)}}number of clones (additional to dichotomized sample){p_end}
{synopt:{cmd:e(seed)}}seed for random-number generator{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:feologit}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(estopt)}}estimation type option ({cmd:basic} or {cmd:thresholds}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(group)}}name of {cmd:group()} variable{p_end}
{synopt:{cmd:e(multiple)}}{cmd:multiple} if multiple positive outcomes within group{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(offset)}}linear offset variable{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(vce)}}{cmd:cluster}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform
                         maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsdefault)}}default predict() specification for {cmd:margins}{p_end}
{synopt:{cmd:e(asbalanced)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}constraints matrix{p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(cat)}}category values{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{marker B2012}{...}
{phang}
Baetschmann, G. 2012. Identification and estimation of thresholds in the fixed
effects ordered logit model. {it:Economics Letters} 115: 416-418.
{browse "https://doi.org/10.1016/j.econlet.2011.12.100"}.

{marker BSW2015}{...}
{phang}
Baetschmann, G., K. E. Staub, and R. Winkelmann 2015. Consistent estimation of
the fixed effects ordered logit model.
{it:Journal of the Royal Statistical Society, Series A} 178: 685-703.
{browse "https://doi.org/10.1111/rssa.12090"}.


{marker authors}{...}
{title:Authors}

{pstd}
Gregori Baetschmann{break}
University of Bern{break}
Bern, Switzerland{break}
gregori.baetschmann@soz.unibe.ch

{pstd}
Alexander Ballantyne{break}
University of Melbourne{break}
Melbourne, Australia{break}
ballantynea@student.unimelb.edu.au

{pstd}
Kevin E. Staub{break}
University of Melbourne{break}
Melbourne, Australia{break}
kevin.staub@unimelb.edu.au

{pstd}
Rainer Winkelmann{break}
University of Zurich{break}
Zurich, Switzerland{break}
rainer.winkelmann@econ.uzh.ch


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 20, number 2: {browse "https://doi.org/10.1177/1536867X20930984":st0596}{p_end}

{p 7 14 2}
Help:  {help feologit postestimation}{p_end}
