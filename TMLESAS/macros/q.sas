%macro q(
  data    = ,         /* input dataset          */
  out     = ,         /* output dataset         */
  depvar  = ,         /* numeric dependent var  */
  event   = ,         /* event value            */
  qmodel  = ,         /* qa model               */
  qclass  = ,         /* class variables        */
  qname   = ,         /* name to call the q var */
  byvars  = ,         /* by variables           */
  logconv = absfconv=0.00000001 fconv=0.000000001 gconv=0.000000001 xconv=0.000000001 maxiter=50,
  csout   = csout     /* output converge status */    
        );

/* %let logconv = absfconv=0.00000001 fconv=0.000000001 gconv=0.000000001 xconv=0.000000001 maxiter=50; */

    proc logistic data = &data /*noprint*/;
       ods output convergencestatus = &csout; 
       class &qclass; 
       model &qmodel  /  &logconv;

       %if "&byvars" ne " " %then %do;
           by &byvars ;
       %end;
   
       output out = &out( drop = _level_ )
              p   = &qname;
    run;
    data &csout;
      set &csout;
      macroType    = "TMLE";
      length model $10 modelType $10 convgMessage $200;
      model      = "Treatment";
      modelType  = "Logistic";
      convgMessage = reason;
      drop reason;
    data &out;
      set &out;
      if &depvar ne &event then &qname = 1 - &qname;
    run;
%mend;

