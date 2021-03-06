%macro ddlm(
   data1    = ,
   data2    = ,
   out      = ,
   nt       = ,
   wtnames  = ,
   bynames  = ,
   models   = ,
   cutoff   = 20,
   csout    = csout,
   trt      =          /* what type of data is data1 (trt=0 or 1) -- used in convg status  */ 
    );
  data _null_;
    set &models;
    call symputx( cats("model",put(tpt,8.) ), omodel );
    call symputx( cats("class",put(tpt,8.) ), oclass );
  run;  
  %do i = 1 %to &nt;
      
    %let j      = %eval(&nt-&i+1);
    %let jm1    = %eval(&j-1);
    
    %let  _deps = %scan(&&model&j,1,"=");
    %let _ideps = %scan(&&model&j,2,"=");
    %let _wt    = %scan(&wtnames,&j," ");
    
    
    %if &i = 1 %then %do;
      data tmp;
        set &data1;
        _wt = &_wt;
        if ( _wt > &cutoff ) then _wt = &cutoff;
      run;
    %end;
    %else %do;
      data tmp;
        set tmp;
        _wt =  &_wt;
        if ( _wt > &cutoff ) then _wt = &cutoff;
      run;
    %end;

    %if &j = 1 %then %do;
       data tmp;
         set tmp &data2;
       run;
    %end;

    %if &bynames ne %str() %then %do;
       proc sort data = tmp;
         by &bynames;
       run;  
    %end;
    proc genmod data = tmp;
       ods output convergenceStatus = _cstmp; 
       model &&model&j ;
       weight _wt;

       %if &bynames ne %str() %then %do;
           by &bynames;
       %end;
   
       output out = tmp
              p   = _pred&jm1;
    run;
    data _cstmp;
      set _cstmp;
      tpt = &j;
      macroType    = "TMLE";
      length model $10 modelType $10 convgMessage $200;
      model        = "Outcome";
      modelType    = "Linear";
      convgMessage = reason;
      trt          = &trt;
      drop reason;
    run;
    %if &i = 1 %then %do;
      data &csout;
         set _cstmp;
      run;
    %end;
    %else %do;
      data &csout;
         set  _cstmp &csout;
      run;
    %end;   
  %end;
  data &out;
    set tmp;
  run;  
%mend;
