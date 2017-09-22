%macro ddwt( 
  data      = ,
  out       = ,
  nt        = ,       /* Number of time-points */
  wtnames   = ,
  rnames    = ,
  qa        = ,
  byvars    = ,
  models    = ,
  class10   = ,
  logconv   = absfconv=0.00000001 fconv=0.000000001 gconv=0.000000001 xconv=0.000000001 maxiter=50,
  csout     = cs  
    );

  data _null_;
    set &models;
    call symputx( cats("model",put(tpt,8.) ), mmodel );
    call symputx( cats("class",put(tpt,8.) ), mclass );
  run;  
  %do i = 1 %to &nt;
    proc means data = &data noprint;
      var %scan(&rnames,&i," ") ;
      %if &byvars ne %str() %then %do;
         by &byvars ;
      %end;
      output out  = _means( drop = _freq_ _type_ )
             mean = _mean;
    run;  
      
    %if &i = 1 %then %do;
       data &out;
         set &data;
       run;
    %end;

    data &out;
       merge &out _means;
      %if &byvars ne %str() %then %do;
         by &byvars ;
      %end;
    run;
       
    proc logistic data = &out /*noprint*/;
       ods output convergenceStatus = _cstmp; 
       class &&class&i; 
       model &&model&i / &logconv;

       %if "&byvars" ne " " %then %do;
           by &byvars ;
       %end;
   
       output out = &out( drop = _level_ )
              p   = _p&i;
    data &out;
      set &out;
      array _rnames[*]  &rnames;
      if _rnames[&i] ne . and _p&i = . then _p&i = _mean;
      
*      if . < _p&i < 0.0001 then _p&i =     0.0001;
*      if _p&i > 1 - 0.0001 then _p&i = 1 - 0.0001;

      drop _mean;
    run;
    data _cstmp;
      set _cstmp;
      tpt = &i;
      macroType  = "TMLE";
      length model $10 modelType $10 convgMessage $200;
      model      = "Dropout";
      modelType  = "Logistic";
      convgMessage = reason;
      drop reason;
    run;  
    %if &i = 1 %then %do;
      data &csout;
        set _cstmp;
      run;
    %end;
    %else %do;
      data &csout;
        set &csout _cstmp;
      run;
    %end;
  %end;
  data &out;
    set &out;
    array _parr[*]    _p1-_p&nt;
    array _wtarr[*]    &wtnames;
    array _wtprod[*]   _wtp1-_wtp&nt;
    do i = 1 to &nt;
      if i = 1 then _wtprod[i] = &qa * _parr[i];
      else _wtprod[i] = _parr[i] * _wtprod[i-1];

      if _wtprod[i] > 0 then _wtarr[i] = 1 / _wtprod[i];
    end;
    drop i;
  run;
%mend;
