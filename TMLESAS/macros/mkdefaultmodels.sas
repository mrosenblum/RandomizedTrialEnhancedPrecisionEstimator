* create default dataset for models ;
%macro mkDefaultModels(
   type    = ,       /* Type of model m or o    */
   out     = ,       /* output dataset          */
   nt      = ,       /* number of timepoints    */ 
   default = ,       /* Default variables       */
   rvars   = ,       /* rvar list               */
   ovars   = ,       /* ovar list               */
   ar      = 1
);
    
  %if %upcase(&type) = M %then %do;
    data &out; 
      length p2 p5 $1000;
      length left $100 right $900;

      rvars    = "&rvars";
      ovars    = "&ovars";
      
      p3       =  "( event = '1' )";
      p4     =  "&Default";
      do j = 2 to &nt by 1;
        tpt    =  j - 1;  
        p2     =  scan( rvars, j - 1, ' ' );
        p5     = "";
        do k = 1 to j - 1 by 1;
          if (j -  k) <= &ar then do;   
            p5   =  catx(" ",p5,scan( ovars, k, ' ' ));
          end;
        end;  
        left   =  catx(" ",p2, p3); 
        right  =  catx(" ",p4, p5);
        output;
      end;
      keep tpt left right;
    run;
  %end;
  %else %if %upcase(&type) = O %then %do;
    data &out; 
      length p2 p4 $1000;
      length left $100 right $900;

      ovars    = "&ovars";
      
      p3       =  "&Default";
      do j = 2 to &nt;
        tpt    =  j - 1;
        p4     =  "";
        do k = 1 to j - 1 by 1;
          if (j -  k) <= &ar then do;   
            p4   =  catx(" ",p4,scan( ovars, k, ' ' ));
          end;
        end;  
        if j < &nt then do;
            p2 = cats("_pred", put(j - 1, 8. ));
        end;    
        else do;
            p2 = scan( ovars, &nt, ' ' );
        end;    
        left   =  catx(" ",p2); 
        right  =  catx(" ",p3, p4);
        output;
      end;
      keep tpt left right;
    run;
  %end;
  %else %if %upcase(&type) = OL %then %do;
    data &out; 
      length p2 p5 $1000;
      length left $100 right $900;

      ovars    = "&ovars";
      
      p3       =  " ";
      p4       =  "&Default";
      do j = 2 to &nt by 1;
        tpt    =  j - 1;
        p5     =  "";
        do k = 1 to j - 1 by 1;
          if (j -  k) <= &ar then do;   
            p5   =  catx(" ",p5,scan( ovars, k, ' ' ));
          end;
        end;  
        if j < &nt then do;
            p2 = cats("_pred", put(j - 1, 8. ));
        end;    
        else do;
            p2 = scan( ovars, &nt, ' ' );
        end;    
        left   =  catx(" ",p2, p3); 
        right  =  catx(" ",p4, p5);
        output;
      end;
      keep tpt left right;
    run;
  %end;
%mend;
