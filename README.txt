Estimator for Randomized Trials using Targeted Maximum Likelihood Estimation (TMLE) README file.
Authors: Michael Rosenblum, Elizabeth Colantuoni, Aidan McDermott

The SAS and R code implement the longitudinal targeted maximum likelihood estimation for randomized trials from van der Laan and Gruber (2012).

In this Github repository, you will find:
-- Docs: containing TMLEdoc.pdf which provides a complete description of and worked examples implementing the longitudinal TMLE using both our SAS and R code.
-- TMLESAS:  contains two folders (Macros and Examples).  The Macros folder contains all the required SAS macros to run the SAS TMLE code (key macro: TMLE).  The Examples folder contains two example datasets as well as the output files generated from the worked examples from the TMLEdoc.pdf.
-- TMLER:  contains two folders (Functions and Examples).  The Functions folder contains the source code required to run the TMLE R function (TMLEfunctions.R).  The TMLEexamples.R contains all the R commands to replicate the worked examples from the TMLEdoc.pdf. The Examples folder contains two example datasets as well as the output files generated from the worked examples from the TMLEdoc.pdf

M.J. van der Laan and S. Gruber. Targeted minimum loss based estimation of causal effects of multiple time point interventions. The International Journal of Biostatistics, 8(1), 2012.