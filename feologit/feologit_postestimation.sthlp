{smcl}
{* *! version 1.0.0  01September2018}{...}
{vieweralsosee "feologit" "help feologit"}{...}
{viewerjumpto "Postestimation commands" "feologit postestimation##description"}{...}
{viewerjumpto "logitmarg" "feologit postestimation##syntax_logitmarg"}{...}
{viewerjumpto "predict" "feologit postestimation##syntax_predict"}{...}
{viewerjumpto "margins" "feologit postestimation##syntax_margins"}{...}
{viewerjumpto "Examples" "feologit postestimation##examples"}{...}
{cmd:help feologit postestimation}{right: ({browse "https://doi.org/10.1177/1536867X20930984":SJ20-2: st0596})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 32 34 2}{...}
{p2col :{cmd:feologit postestimation} {hline 2}}Postestimation tools for 
feologit{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {cmd:feologit}:

{synoptset 17 tabbed}{...}
{p2coldent :*Command}Description{p_end}
{synoptline}
{synopt:{helpb feologit_postestimation##logitmarg:logitmarg}}marginal effects at the average of the dependent variable{p_end}
{p2coldent :^ {helpb feologit postestimation##predict:predict}}predictions{p_end}
{p2coldent :^ {helpb feologit_postestimation##margins:margins}}marginal
	means, predictive margins, marginal effects, and average marginal
	effects{p_end}
{p2coldent :{c 134} {helpb test}}Wald tests of simple and composite linear hypotheses{p_end}
{p2coldent :{c 134} {helpb testnl}}Wald tests of nonlinear hypotheses{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* Other postestimation commands might function with {cmd:feologit} but are currently untested.{p_end}
{p 4 6 2}
^ {cmd:predict} and {cmd:margins} contain assumptions about the fixed effects and will produce inconsistent estimates
when these assumptions do not hold.{p_end}
{p 4 6 2}
{c 134} These commands cannot be used on estimates of the first threshold.


{marker syntax_logitmarg}{...}
{marker logitmarg}{...}
{title:Syntax for logitmarg}

{p 8 16 2}
{cmd:logitmarg} 
{ifin}
[{cmd:,} {it:options}]

{synoptset 20}{...}
{synopthdr}
{synoptline}
{synopt :{opt o:utcome(outcome)}}display estimated marginal effects only for
category {it:outcome}{p_end}
{synopt :{opth dydx(varlist)}}estimate estimated marginal effects only for variables {it:varlist}{p_end}
{synopt :{opt eretstore}}store estimates in {cmd:e()} instead of {cmd:r()}{p_end}
{synoptline}


{marker des_logitmarg}{...}
{title:Description for logitmarg}

{pstd}
{cmd:logitmarg} presents marginal effects calculated at the sample average of
the dependent variable, as well as standard errors and confidence intervals
for these marginal effects.  Results are stored in {cmd:r()} by default.  
Note: The reported standard errors are for effects at the sample average and
not for effects at the population average because they do not account for the
uncertainty in the sample average.


{marker options_logitmarg}{...}
{title:Options for logitmarg}

{phang}
{opt outcome(outcome)} displays estimated marginal effects only for the
category selected by {it:outcome}.  {cmd:outcome()} should contain either one
value of the dependent variable or one of {cmd:#1}, {cmd:#2}, ..., with
{cmd:#1} meaning the first category of the dependent variable, {cmd:#2}
meaning the second category, etc.

{phang}
{opth dydx(varlist)} displays estimated marginal effects only for the variables
listed by {it:varlist}.

{phang}
{opt eretstore} stores estimates in {cmd:e()} instead of {cmd:r()}.  Existing
{cmd:e()} results will be lost.


{marker syntax_predict}{...}
{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict} 
{dtype}
{newvar}
{ifin}
[{cmd:,} {it:statistic} {opt o:utcome(outcome)} {opt nooff:set}]

{synoptset 17}{...}
{synopthdr:statistic}
{synoptline}
{synopt :{opt pu0}}probability of a positive outcome, assuming
fixed effect is zero (or constant) (available after thresholds estimation only){p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
If you do not specify {cmd:outcome()}, {cmd:pu0} assumes {cmd:outcome(#1)}.{p_end}
INCLUDE help esample


{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions of probabilities
or linear predictions.  Predictions of probabilities are available only after
estimation with the option {opt thresholds}.  Predictions of probabilities
assume fixed effects are all zero.


{marker options_predict}{...}
{title:Options for predict}

{phang}
{opt pu0} calculates the probability of a positive outcome, assuming that
the fixed effect is zero (or constant).  This option is available only after
estimation with the option {opt thresholds}.

{phang}
{opt xb} calculates the linear prediction.

{phang}
{opt outcome(outcome)} specifies for which outcome the predicted probabilities
are to be calculated.  {opt outcome()} should contain either one value of
the dependent variable or one of {opt #1}, {opt #2}, {it:...}, with {opt #1}
meaning the first category of the dependent variable, {opt #2} meaning the
second category, etc.

{phang}
{opt nooffset} is relevant only if you specified {opt offset(varname)} for
{cmd:feologit}.  It modifies the calculations made by {cmd:predict} so that
they ignore the offset variable; the linear prediction is treated as xb rather
than as xb + offset.


INCLUDE help syntax_margins

{synoptset 17}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt pu0}}probability of a positive outcome, assuming
fixed effect is zero; only available after estimation with the option {opt thresholds}{p_end}
{synopt :{opt xb}}linear prediction{p_end}
{synoptline}
{p2colreset}{...}

INCLUDE help notes_margins


{marker des_margins}{...}
{title:Description for margins}

{pstd}
{cmd:margins} estimates margins of response for probabilities and linear
predictions.  Note that margins of response for probabilities are conditional
on zero (or constant) fixed effects.


{marker examples}{...}
{title:Examples}

{pstd}
Setup{p_end}
{phang2}{cmd:. webuse nhanes2f}{p_end}
{phang2}{cmd:. sample 20}{p_end}

{pstd}
Fit fixed-effects ordered logistic regression{p_end}
{phang2}{cmd:. feologit health age age2 sex race weight iron diabetes, group(location)}{p_end}

{pstd}
Test that the coefficient on {cmd:sex} equals the coefficient on
{cmd:race}{p_end}
{phang2}{cmd:. test sex = race}{p_end}

{pstd}
Fit previous regression but also estimate thresholds{p_end}
{phang2}{cmd:. feologit health age age2 sex race weight iron diabetes, group(location) thresholds}{p_end}

{pstd}
Predict the probability of a positive outcome for category 2 {cmd:fair}
{cmd:health}, assuming that the fixed effect is zero{p_end}
{phang2}{cmd:. predict pred2, pu0 outcome(#2)}{p_end}

{pstd}
Marginal effects at the average of having {cmd:diabetes} on health
outcomes{p_end}
{phang2}{cmd:. logitmarg, dydx(diabetes)}{p_end}


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
Help:  {helpb feologit}{p_end}
