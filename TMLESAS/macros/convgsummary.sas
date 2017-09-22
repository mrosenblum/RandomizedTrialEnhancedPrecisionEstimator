%macro convgSummary(
  M     = ,     /* main data                 */
  Mwt0  = ,     /* main dropout trt = 0      */  
  Mwt1  = ,     /* main dropout trt = 1      */
  Mout0 = ,     /* main output trt = 0       */
  Mout1 = ,     /* main output trt = 1       */
  S     = ,     /* bootstrap data            */
  Swt0  = ,     /* bootstrap dropout trt = 0 */  
  Swt1  = ,     /* bootstrap dropout trt = 1 */
  Sout0 = ,     /* bootstrap output trt = 0  */
  Sout1 = ,     /* bootstarp output trt = 1  */
  out   = ,     /* output dataset            */
  full  = ,     /* output dataset full convg */
  trt   = ,     /* treatment name            */
  nt    = ,
  omtyp = ,     /* outcome type LM/LG        */
  nsamp =       /* number of bootstraps      */     
);  

  data &full;
    set &M ( in = in1 )    &Mwt0 ( in = in2 )   &Mwt1 ( in = in3 )   &Mout0 ( in = in4 )  &Mout1 ( in = in5  )
        &S ( in = in6 )    &Swt0 ( in = in7 )   &Swt1 ( in = in8 )   &Sout0 ( in = in9 )  &Sout1 ( in = in10 );
    length dataType $10;
    if ( in1 or in2 or in3 or in4 or in5 ) then dataType = "Main";
    else dataType = "Sample";
  run;

 data dummyconvg;
     length macroType      $8;
     length model          $10;
     length modelType      $10;
     length dataType       $10;
     length &trt tpt sample 8;

     macroType = "TMLE";
     dataType  = "Main";
     model     = "Treatment";
     modelType = "Logistic";
     &trt      = .;
     tpt       = .;
     sample    = .;
     output;

     model     = "Dropout";
     modelType = "Logistic";
     do &trt = 0 to 1;
     do tpt = 1 to &nt;
       output;
     end;
     end; 
     
     model = "Outcome";
     if upcase("&omtyp") = "LM" then modelType = "Linear";
     else modelType = "Logistic";
     do &trt = 0 to 1;
     do tpt = 1 to &nt;
       output;
     end;
     end; 

     dataType  = "Sample";
     do sample = 1 to &nsamp;
         
     model     = "Treatment";
     modelType = "Logistic";
     &trt      = .;
     tpt       = .;
     output;

     model     = "Dropout";
     modelType = "Logistic";
     do &trt = 0 to 1;
     do tpt = 1 to &nt;
       output;
     end;
     end; 
     
     model = "Outcome";
     if upcase("&omtyp") = "LM" then modelType = "Linear";
     else modelType = "Logistic";
     do &trt = 0 to 1;
     do tpt = 1 to &nt;
       output;
     end;
     end; 
     end;
 run;

 proc sort data = dummyconvg;
   by macroType dataType model trt tpt sample;   
 proc sort data = &full;
   by macroType dataType model trt tpt sample;   
 run;

 data &full;
   merge dummyconvg(in=in1) &full(in=in2);  
   by macroType dataType model trt tpt sample;
   source = in1 + 2 * in2;
   if in1 = 1 and in2 = 0 then do;
      status = 9; 
      convgMessage = cats("Not Run (mean used)", convgMessage);
   end;
 run;
 proc freq data = &full noprint;
   table status * convgMessage / missing out = &out(drop=percent rename=(count = n));  
   by macroType dataType model modelType trt tpt;
 run;  
%mend;
