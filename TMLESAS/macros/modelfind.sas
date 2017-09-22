* given a dataset from buf2data, find match in arguments ;
%macro modelFind(
    data     =,       /* input dataset   */
    out      =,       /* output dataset  */
    n        =,       /* global macro variable name to store nobs */
    match    =        /* match string    */
    ) ;
  data &out;
    set &data;
    where find(part,"&match","i") > 0 and index(part,"=") > 0;
      
    length fpart spart vlist opts $200;

    part  = compbl(part);
    rfind = find(part,"&match","i");
    part  = substr(part,rfind);
    rfind = find(part,"&match","i");
    efind = find(part,"=","i");

    if ( rfind > 0 and efind > rfind ) then do;
     fpart = substr(part,1,efind-1);
     spart = substr(part,efind+1);
       
     rfind = find(fpart,"&match","i");
     tpt = input( substr(fpart,rfind+length("&match")),best32.);
     if tpt = . then delete;
     if ( tpt ne . ) then do;
       breakpt = find(spart,"/","i");
       if breakpt > 0 then do;
         vlist = trim(left(substr(spart,1,breakpt-1)));
         opts  = trim(left(substr(spart,breakpt+1  )));
       end;
       else do;
         vlist = spart;
         opts  = "";
       end;
     end;
    end;
    keep fpart spart part vlist opts tpt;
    data _null_;
      call symputx("&n",put(nobs,best32.));
      set &out nobs = nobs;
      stop;
    run;  
   run;
%mend;
