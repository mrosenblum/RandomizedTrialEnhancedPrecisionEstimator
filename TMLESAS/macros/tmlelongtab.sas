%macro tmlelongtab( data =, out =, nreps =, dname = ); 
data &out;
  set &data;

  length label $50;
  length dname $50;

  Nreps    = &Nreps;
  dname    = "&dname";

  label = "Treatment group 0";
  complete = meana1;
  bcalba   = bcalb0a;
  bcauba   = bcaub0a;
  Estimate = meanp1;
  bcalb    = bcalb0;
  bcaub    = bcaub0;
  ratio    = (stdS0 ** 2) / ( stdS0a ** 2);
  output;

  label = "Treatment group 1";
  complete = meana2;
  bcalba   = bcalb1a;
  bcauba   = bcaub1a;
  Estimate = meanp2;
  bcalb    = bcalb1;
  bcaub    = bcaub1;
  ratio    = (stdS1 ** 2) / ( stdS1a ** 2);
  output;

  label = "Difference (group 1 - group 0)";
  complete = meana2 - meana1 ;
  bcalba   = bcalbda;
  bcauba   = bcaubda;
  Estimate = diff;
  bcalb    = bcalbD;
  bcaub    = bcaubD;
  ratio    = (stdSdiff ** 2) / ( stdSdiffa ** 2);
  output;

  label complete = "Complete Case";
  label bcalba   = "BCA lower CL (complete case)";
  label bcauba   = "BCA upper CL (complete case)";    
  
  label Estimate = "TML Estimate";
  label bcalb    = "BCA lower CL";
  label bcaub    = "BCA upper CL";
  label ratio    = "Relative Efficiency";
  
  keep label complete bcalba bcauba Estimate bcalb bcaub ratio nobs0 nobs1 nreps dname;
run;
%mend;
