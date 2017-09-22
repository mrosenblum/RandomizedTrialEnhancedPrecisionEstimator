%macro TMLE(
    data           =,              /* names the input dataset                                      */
    out            =,              /* names the output dataset                                     */
    outtab         = tmleout,      /* tabular output dataset suitable for printing                 */
    nreps          = 1,            /* Number of replicate samples                                  */
    seed           = 3121,         /* Seed to use for sampling                                     */
    A              = A,            /* name of treatment variable coded as 0/1                      */
    strata         = &A,           /* stratified sampling (default is by treatment)                */
    outcomeVars    = ,             /* List of outcome variables in time order
                                      Determines nt and the outcome at baseline variable           */
    treatmentModel = ,             /* treatment model                                              */
    dropoutModel   = ,             /* dropout model                                                */
    outcomeModel   = ,             /* outcome model                                                */
    outcomeModelType = lm,         /* type of outcome -- linear model or logistic model            */
    lag            = 1,            /* number of previous outcomes to include in each model         */ 
    lagdropout     = 1,            /* number of previous outcomes to include in each dropout model */ 
    lagoutcome     = 1,            /* number of previous outcomes to include in each outcome model */ 
    modeldata      =,              /* dataset with model information                               */
    cutoff         = 20,           /* weights above this are set to cutoff                         */
    clevels        = 95,           /* level for confidence intervals                               */
    sampleOut      =,              /* Output sample                                                */
    convgData      = convgData,    /* Data set with full convergence status                        */
    convgSummary   = convgSummary  /* Convergence summary                                          */
    )  / parmbuff;
    
  /* the buffer */ 
  %global _lenbuf _lenpart _nterms;
  %let _lenbuf = %length(&syspbuff);
  %buf2data( buf = %str( &syspbuff ), out = buffdata );

  * the parameters;
  data _null_;
    length onevar $32;
    length baselinevar $32;
    length rlist wtlist oclist $2000;
    length fulloclist $2000;

    array _varr[*] &outcomeVars;
    nt           = dim(_varr);
    baselineVar  = vname( _varr[1] );

    oclist = "";
    rlist  = "_r0";
    wtlist = "_wt0";
    
    fulloclist = baselineVar;
    do t = 2 to nt by 1;
     onevar = vname( _varr[t] );
     if t = 2 then oclist = trim(left(onevar));
     else do;
        oclist = catx(" ",oclist,onevar);
     end;   
     fulloclist = catx(" ",fulloclist,onevar);

     if t < nt then do;
       rlist  = catx(" ", rlist, cats( "_r" , put(t-1, 8. ) ));
       wtlist = catx(" ",wtlist, cats( "_wt", put(t-1, 8. ) ));
     end;    
    end;
    call symputx("nt",          put(nt - 1,     8.     ));
    call symputx("oclist",      put(oclist,     $1000. ));
    call symputx("fulloclist",  put(fulloclist, $1000. ));
    call symputx("baselineVar", put(baselineVar,$32.   ));
    call symputx("rlist",       put(rlist,      $1000. ));
    call symputx("wtlist",      put(wtlist,     $1000. ));
  run;

  %if &modeldata ne %str() %then %do;
     data dmodeldata omodeldata;
       set &modeldata;
       if lowcase(modelType) = "dropout" then output dmodeldata;
       if lowcase(modelType) = "outcome" then do;
           tpt = tpt - 1;  /* this is to conform with R */
           output omodeldata;
       end;    
     run;
     proc sort data = dmodeldata;
         by tpt;
     proc sort data = omodeldata;
         by tpt;
     run;         
  %end;
  %else %do;
     data dmodeldata omodeldata;
       length modelType $10;
       length rhs       $200;
       length tpt       8;
       stop;
     run;
  %end;

  %let bvars = ;
  %let mvars = ;
  %let ovars = ;
  %if  &treatmentModel ne %str() %then %let bvars = &treatmentModel ;
  %if  &dropoutModel   ne %str() %then %let mvars = &dropoutModel ;
  %if  &outcomeModel   ne %str() %then %let ovars = &outcomeModel ;

  %if &lag ne %str() %then %do;
    %if &lagdropout = %str() %then %let lagdropout = &lag;
    %if &lagoutcome = %str() %then %let lagoutcome = &lag;
  %end;  

  %global _nm _no _nmc _noc;

  data buffdatax;
      set buffdata;
      where find(part, "outcomemodeltype", "i" ) = 0;
  run;
  
  %modelFind( data = buffdatax, out = mmodels, n = _nm,   match = dropoutmodel ) ;
  %modelFind( data = buffdatax, out =  mclass, n = _nmc,  match = dropoutclass ) ;
  %modelFind( data = buffdatax, out = omodels, n = _no,   match = outcomemodel ) ;
  %modelFind( data = buffdatax, out =  oclass, n = _noc,  match = outcomeclass ) ;
  
  %let ntx = %eval(&nt + 1 );
  %mkDefaultModels( type = m, out = _mm, nt = &ntx, default = &mvars, rvars = &rlist, ovars = &fulloclist, ar = &lagdropout);
  data _mm;
    length macvarname $20;
    length mmodel     $1000;
    length mclass     $1000;
    merge _mm ( in = in1 ) mmodels ( in = in2 ) dmodeldata ( in = in3 );
    by tpt;

    mmodel = catx(" ",left," = ",right);
    mclass = "";
    if ( in2 = 1 ) then do;
        if ( opts ~= "" ) then mmodel = catx(" ",left," = ", vlist, " / ", opts);
        else mmodel = catx(" ",left," = ", vlist);
    end;    
    if ( in3 = 1 ) then do;
        mmodel = catx(" ",left," = ", rhs);
    end;    
    macvarname = cats("MModel",put(tpt,8.));
    keep tpt macvarname mmodel mclass;
  run;

  %if %upcase(&outcomeModelType) = LM %then %do;   
    %mkDefaultModels( type = o, out = _om, nt = &ntx, default = &ovars, rvars = &rlist, ovars = &fulloclist, ar = &lagoutcome);
  %end;
  %else %do;
    %mkDefaultModels( type = ol, out = _om, nt = &ntx, default = &ovars, rvars = &rlist, ovars = &fulloclist, ar = &lagoutcome);
  %end;
      
  data _om;
    length macvarname $20;
    length omodel     $1000;
    length oclass     $1000;
    length ovars      $1000;
    merge _om ( in = in1 ) omodels ( in = in2 ) omodeldata ( in = in3 );
    by tpt;

    omodel = catx(" ",left," = ",right);
    ovars  = right;
    oclass = "";
    if ( in2 = 1 ) then do;
        if ( opts ~= "" ) then omodel = catx(" ",left," = ", vlist, " / ", opts);
        else omodel = catx(" ",left," = ", vlist);
        ovars = vlist;
    end;    
    if ( in3 = 1 ) then do;
        omodel = catx(" ",left," = ", rhs);
        ovars  = rhs;
    end;    
    macvarname = cats("OModel",put(tpt,8.));

    call symputx("ovars",put(ovars,$1000.));
    keep tpt macvarname omodel oclass;
  run;
  
  /* ---------------------------------------------------------- */
   
  proc sort data = _mm;
    by tpt;
  proc sort data = _om;
    by tpt;
  run;
  
  * ---------------------------------------------------------- ;
  * add unique id variable                ;
  * test for intermittent missing pattern ;
  * split into treatment groups           ;
  data d;
    set &data end = last nobs=nobs;
    _uid = _n_;

    array _varr[*] &fulloclist;
    array _rarr[*] &rlist _dd;
    _lastt = 0;
    do i = 1 to dim(_varr);
     if _varr[i] ne . then _lastt = i;
    end;  
    do i = 1 to _lastt;
     _rarr[i] = 1;
     if i = _lastt then _rarr[i] = 0;
   end;
   drop i;
   _nvalues = N( of _varr[*] );
   _ninter  = _lastt - _nvalues;
     
   if last then do;
     call symputx("Nobs",put(nobs,8.));
   end;
   proc sort data = d;
      by &A;
   run;

   proc means data = d noprint;
      var &baselinevar;
      by &A;
      output out  = _stats
             n    = nobs;
   data _stats;
      set _stats ( where = ( &A = 0 )  rename = ( nobs = nobs0 ));
      set _stats ( where = ( &A = 1 )  rename = ( nobs = nobs1 ));
      keep nobs0 nobs1;
   run;      
   proc means data = d noprint;
      var _ninter;
      output out  = _ninter
             sum  = _ninter;
   data _ninter;
      set _ninter;
      if _ninter > 0 then do;
         call symputx("Ninter", "yes" );
      end;
      else do;  
         call symputx("Ninter", "no" );
      end;
   run;
   %if &ninter = yes %then %do;
     %goto efin;
   %end;

   %TMLEboot1( data = d, out = samples, nreps = &nreps, outhits = ohits, seed1 = &seed, strata = &strata );
   
   %if &sampleout ne %str() %then %do;
     data &sampleout;
       set samples;
     run;
   %end;    
   * ---------------------------------- ;

   %q( data = d,        out  = dq,       depvar = &A, event  = 1, qmodel = %str( &A (event = "1" ) = &bvars ), qname = qp, csout = _csM );

   proc sort data = samples out = samples;
     by sample &A;
   run;  
  
   %q( data = samples,  out  = samplesq, depvar = &A, event  = 1, qmodel = %str( &A (event = "1") =  &bvars ), qname = qp, byvars = sample, csout = _csS );

   * ---------------------------------------------------------- ;
   * dropout models ;
   %ddwt( data = dq( where = ( &A = 0 )), out = p1, nt = &nt, wtnames = &wtlist, rnames = &rlist,  byvars = &A, qa = qp, models = _mm, csout = _csMwt0 );
   %ddwt( data = dq( where = ( &A = 1 )), out = p2, nt = &nt, wtnames = &wtlist, rnames = &rlist,  byvars = &A, qa = qp, models = _mm, csout = _csMwt1 );

   data dwts;
     set p1 p2;
   run;

   %ddwt( data = samplesq( where = ( &A = 0 )), out = s1, nt = &nt, wtnames = &wtlist, rnames = &rlist, byvars = &A sample, qa = qp, models = _mm, csout = _csSwt0 );
   %ddwt( data = samplesq( where = ( &A = 1 )), out = s2, nt = &nt, wtnames = &wtlist, rnames = &rlist, byvars = &A sample, qa = qp, models = _mm, csout = _csSwt1 );

   data sampleswts;
     set s1 s2;
   run;

   * ---------------------------------------------------------- ;
   * Outcome models ;
   data p1;  set dwts;  where &A = 0;
   data t2;  set dwts;  where &A = 1;  keep &baselinevar &ovars &A;
   data p2;  set dwts;  where &A = 1;
   data t1;  set dwts;  where &A = 0;  keep &baselinevar &ovars &A;
   run;

   %if %upcase(&outcomeModelType) = LM %then %do;   
     %ddlm( data1 = p1, data2 = t2, out = preds1,  nt = &nt, wtnames = &wtlist, models = _om, cutoff = &cutoff, csout = _csMlm0, trt = 0 );
     %ddlm( data1 = p2, data2 = t1, out = preds2,  nt = &nt, wtnames = &wtlist, models = _om, cutoff = &cutoff, csout = _csMlm1, trt = 1 );
   %end;
   %else %do;
     %ddlg( data1 = p1, data2 = t2, out = preds1,  nt = &nt, wtnames = &wtlist, models = _om, cutoff = &cutoff, csout = _csMlg0, trt = 0 );
     %ddlg( data1 = p2, data2 = t1, out = preds2,  nt = &nt, wtnames = &wtlist, models = _om, cutoff = &cutoff, csout = _csMlg1, trt = 1 );
   %end;

   proc means data = preds1 noprint;
      var %scan( &oclist, &nt, " ") _pred0;
      output  out  = one ( drop = _: )
              mean = meana1 meanp1;
   proc means data = preds2 noprint;
      var %scan( &oclist, &nt, " ") _pred0;
      output  out  = two (drop = _: )
              mean = meana2 meanp2;
   run;
   
   data onetwo;
      merge one two;
      diff  = meanp2 - meanp1;
      diffa = meana2 - meana1;
   run;

/* ---------------------------------------------------------- */

   data p1; set sampleswts; where &A = 0;
   data t2; set sampleswts; where &A = 1;  keep sample &baselinevar &ovars &A;
   data p2; set sampleswts; where &A = 1;
   data t1; set sampleswts; where &A = 0;  keep sample &baselinevar &ovars &A;
  
   %if %upcase(&outcomeModelType) = LM %then %do;   
     %ddlm( data1 = p1, data2 = t2, out = preds1, nt = &nt, wtnames = &wtlist, bynames = sample, models = _om, cutoff = &cutoff, csout = _csSlm0, trt = 0 );
     %ddlm( data1 = p2, data2 = t1, out = preds2, nt = &nt, wtnames = &wtlist, bynames = sample, models = _om, cutoff = &cutoff, csout = _csSlm1, trt = 1 );
   %end;
   %else %do;
     %ddlg( data1 = p1, data2 = t2, out = preds1, nt = &nt, wtnames = &wtlist, bynames = sample, models = _om, cutoff = &cutoff, csout = _csSlg0, trt = 0 );
     %ddlg( data1 = p2, data2 = t1, out = preds2, nt = &nt, wtnames = &wtlist, bynames = sample, models = _om, cutoff = &cutoff, csout = _csSlg1, trt = 1 );
   %end;

   %if %upcase(&outcomeModelType) = LM %then %do;   
      %convgSummary(
         M     = _csm,           /* main data                 */
         Mwt0  = _csmwt0,        /* main dropout trt = 0      */  
         Mwt1  = _csmwt1,        /* main dropout trt = 1      */
         Mout0 = _csmlm0,        /* main output trt = 0       */
         Mout1 = _csmlm1,        /* main output trt = 1       */
         S     = _css,           /* bootstrap data            */
         Swt0  = _csswt0,        /* bootstrap dropout trt = 0 */  
         Swt1  = _csswt1,        /* bootstrap dropout trt = 1 */
         Sout0 = _csslm0,        /* bootstrap output trt = 0  */
         Sout1 = _csslm1,        /* bootstarp output trt = 1  */
         out   = &convgsummary,  /* output dataset            */
         full  = &convgData,     /* output dataset full convg */
         trt   = &A,
         nt    = &nt, 
         omtyp = &outcomeModelType,
         nsamp = &nreps
      );  
   %end;
   %else %do;
      %convgSummary(
         M     = _csm,           /* main data                 */
         Mwt0  = _csmwt0,        /* main dropout trt = 0      */  
         Mwt1  = _csmwt1,        /* main dropout trt = 1      */
         Mout0 = _csmlg0,        /* main output trt = 0       */
         Mout1 = _csmlg1,        /* main output trt = 1       */
         S     = _css,           /* bootstrap data            */
         Swt0  = _csswt0,        /* bootstrap dropout trt = 0 */  
         Swt1  = _csswt1,        /* bootstrap dropout trt = 1 */
         Sout0 = _csslg0,        /* bootstrap output trt = 0  */
         Sout1 = _csslg1,        /* bootstarp output trt = 1  */
         out   = &convgsummary,  /* output dataset            */          
         full  = &convgData,     /* output dataset full convg */
         trt   = &A,
         nt    = &nt,
         omtyp = &outcomeModelType, 
         nsamp = &nreps
      );  
   %end;


   proc means data = preds1 noprint;
      var %scan( &oclist, &nt, " ") _pred0;
      by sample;
      output out  = pp1 ( drop = _freq_ _type_ )
             mean = meana0 mean0; 
   proc means data = preds2 noprint;
      var %scan( &oclist, &nt, " ") _pred0;
      by sample;
      output out  = pp2 ( drop = _freq_ _type_ )
             mean = meana1 mean1;
       
   data diff;
      merge pp1 pp2;
      by sample;
      difference = mean1  - mean0;
      diffa      = meana1 - meana0;
   run;

   %clevels( clevels = &clevels );
   proc univariate data = pp1 noprint;
      var mean0;
      output out  = ptl1
            mean  = meanS0     std  = stdS0     pctlpre = mean0  pctlpts = &ptilelist;
   proc univariate data = pp2 noprint;
      var mean1;
      output out  = ptl2
             mean = meanS1     std  = stdS1     pctlpre = mean1  pctlpts = &ptilelist;
   proc univariate data = diff noprint;
      var difference;
      output out  = ptldiff
             mean = meanSdiff  std  = stdSdiff  pctlpre = diff   pctlpts = &ptilelist;
   run;

   proc univariate data = pp1 noprint;
      var meana0;
      output out  = ptl1a
            mean  = meanS0a     std  = stdS0a     pctlpre = mean0a  pctlpts = &ptilelist;
   proc univariate data = pp2 noprint;
      var meana1;
      output out  = ptl2a
             mean = meanS1a     std  = stdS1a     pctlpre = mean1a  pctlpts = &ptilelist;
   proc univariate data = diff noprint;
      var diffa;
      output out  = ptldiffa
             mean = meanSdiffa  std  = stdSdiffa  pctlpre = diffa   pctlpts = &ptilelist;
   run;
   
   data mainr;
      set onetwo;
      if _n_ = 1 then do;
         set _stats; 
         set ptl1;
         set ptl2;
         set ptldiff;
         set ptl1a;
         set ptl2a;
         set ptldiffa;    
      end;
   run;

   * For bca: ;
   data sampler;
     set diff;
     if _n_ = 1 then do;
       set onetwo ( rename = ( meana1 = maina1 meanp1 = mainp1 meana2 = maina2 meanp2 = mainp2 diff = maindiff diffa = mainadiff ) );
     end;
   run;  

   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 =    mainp1, t =      mean0,  nobs = &nobs,  out =  CI0, tile = &fclevel );
   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 =    mainp2, t =      mean1,  nobs = &nobs,  out =  CI1, tile = &fclevel );
   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 =  maindiff, t = difference,  nobs = &nobs,  out =  CID, tile = &fclevel );

   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 =    maina1, t =     meana0,  nobs = &nobs,  out = CI0a, tile = &fclevel );
   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 =    maina2, t =     meana1,  nobs = &nobs,  out = CI1a, tile = &fclevel );
   %tmlebca( ohits = ohits, sampresults = sampler, main = mainr, t0 = mainadiff, t =      diffa,  nobs = &nobs,  out = CIDa, tile = &fclevel );

   data &out;
     set mainr;
     set CI0 ( rename = ( bcaLB = bcaLB0  bcaUB = bcaUB0 ));
     set CI1 ( rename = ( bcaLB = bcaLB1  bcaUB = bcaUB1 ));
     set CID ( rename = ( bcaLB = bcaLBD  bcaUB = bcaUBD ));
     set CI0a( rename = ( bcaLB = bcaLB0a bcaUB = bcaUB0a ));
     set CI1a( rename = ( bcaLB = bcaLB1a bcaUB = bcaUB1a ));
     set CIDa( rename = ( bcaLB = bcaLBDa bcaUB = bcaUBDa ));
   run;
 
   %tmlelongtab( data = &out,  out = &outtab, nreps = &nreps, dname = &data  );

%goto fin;
%efin: ;
   %put Error in tmle macro (intermittent missing data?);
%fin: ;
%mend;
