options nodate nocenter nonumber ls=200 ps=100;

libname results "../Results";

proc print data = results.tab1;
run;

data tplate;
  infile "tabletplate.txt"  lrecl=400 pad;
  length line $400;
  input line $ 1-400;
proc print data = tplate;
run;

%macro plottex( data =, tplate =, out =, nreps =,
  h1 =,
  m1 =,  m2 =,  m3 =, m4 =, m5 =, m6 =, m7 =, m8 =, m9 =, m10 =, nmparm = 3,
  indentm = 1.0in,  
  fmt1 =, fmt2 =,
  note1 = %str( where Trt denotes the treatment indicator, Y$_t$ denotes the outcome at time $t$, $t = 1, 2, \ldots, 5$,
                D$_{t}$ denotes dropout at time $t+1$, for, $t < 5$,
                and, $\tilde{Y}_{5,t+1}$ denotes the predicted value of $Y_5$ from the outcome model at the next time point.),   
  note2 = ,
    );

  data tt;
    set &data;
    length txt $12;
    array vars[*] complete  bcalba  bcauba  Estimate  bcalb  bcaub  ratio;
    if label = "Treatment group 0" then do;
        do i = 1 to 6;
          txt = put( vars[i], &fmt1 );
          call symputx( cats("hashv","2","_",i), txt );
        end;
        do i = 7 to 7;  
          txt = put( vars[i], &fmt2 );
          call symputx( cats("hashv","2","_",i), txt );
        end;
    end;
    else if label = "Treatment group 1" then do;
        do i = 1 to 6;
          txt = put( vars[i], &fmt1 );
          call symputx( cats("hashv","3","_",i), txt );
        end;
        do i = 7 to 7;  
          txt = put( vars[i], &fmt2 );
          call symputx( cats("hashv","3","_",i), txt );
        end;
    end;
    else if label = "Difference (group 1 - group 0)" then do;
       do i = 1 to 6;
          txt = put( vars[i], &fmt1 );
          call symputx( cats("hashv","1","_",i), txt );
        end;
        do i = 7 to 7;  
          txt = put( vars[i], &fmt2 );
          call symputx( cats("hashv","1","_",i), txt );
        end;
    end;

    data tmp;
    set &tplate;   
    file "&out";

    if line = "##m1" then do;
         %do j = 1 %to &nmparm;
            line = "&&m&j";
            put line;
         %end;
    end;
    else do;
      if line = "##m2" then line = "&m2";
      if line = "##m3" then line = "&m3";
      if line =  "##H" then line = "&h1";

      if line =  "##note1" and "&note1" ne "" then line = "&note1";
      if line =  "##note2" and "&note2" ne "" then line = "&note2";
      
      if index(line,"##N") > 0 then do;
         line = tranwrd( line, "##N", put( &Nreps, comma9. ));
      end;

      if substr(line,1,22) = "{\ }\hspace{##indentm}" then do;
          line = cats("{\ }\hspace{", "&indentm", "}\begin{minipage}[t]{5.6in}");
      end;
  
      if substr(line,1,10) = "Difference" then do;
         line = tranwrd( line, "##1", "&hashv1_1");
         line = tranwrd( line, "##2", "&hashv1_2");
         line = tranwrd( line, "##3", "&hashv1_3");
         line = tranwrd( line, "##4", "&hashv1_4");
         line = tranwrd( line, "##5", "&hashv1_5");
         line = tranwrd( line, "##6", "&hashv1_6");
         line = tranwrd( line, "##7", "&hashv1_7");
      end;    
      if substr(line,1,18) = "Treatment group 0" then do;
         line = tranwrd( line, "##1", "&hashv2_1");
         line = tranwrd( line, "##2", "&hashv2_2");
         line = tranwrd( line, "##3", "&hashv2_3");
         line = tranwrd( line, "##4", "&hashv2_4");
         line = tranwrd( line, "##5", "&hashv2_5");
         line = tranwrd( line, "##6", "&hashv2_6");
         line = tranwrd( line, "##7", "&hashv2_7");
      end;    
      if substr(line,1,18) = "Treatment group 1" then do;
         line = tranwrd( line, "##1", "&hashv3_1");
         line = tranwrd( line, "##2", "&hashv3_2");
         line = tranwrd( line, "##3", "&hashv3_3");
         line = tranwrd( line, "##4", "&hashv3_4");
         line = tranwrd( line, "##5", "&hashv3_5");
         line = tranwrd( line, "##6", "&hashv3_6");
         line = tranwrd( line, "##7", "&hashv3_7");
      end;
      if substr(line,1,2) ne "##" then put line;
    end;
  run;
%mend;

options mprint symbolgen;
%plottex( data = results.tab1, tplate = tplate, out = tab1.txt, Nreps = 10000, fmt1 = 8.3, fmt2 = 10.4,
 h1 = %str(TMLE results from sample code 1.1.\\),
 indentm = 0.3in, nmparm = 4,   
 m1 = %str(Treatment (logit): & Trt $\sim$ male, age, $Y_1$\\),
 m2 = %str(Dropout (logit):   & D$_{t}$ $\sim$ male, age, $Y_t$, & $t = 1,2,3,4$\\),
 m3 = %str(Outcome (linear):  & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$ & when $t = 1,2,3$ \\),
 m4 = %str(                   & Y$_{5}$ $\sim$ male, age, $Y_4$\\)
);

%plottex( data = results.tab2, tplate = tplate, out = tab2.txt, Nreps = 10000, fmt1 = 8.3, fmt2 = 10.4,
 h1 = %str(TMLE results from sample code 1.2.\\),
 indentm = 0.3in, nmparm = 6,   
 m1 = %str(Treatment (logit): & Trt $\sim$ male, age, $Y_1$\\),
 m2 = %str(Dropout (logit):   & D$_{1}$ $\sim$ male, age, $Y_1$ & \\),
 m3 = %str(                   & D$_{t}$ $\sim$ male, age, $Y_t$, $Y_{t-1}$ & for $t = 2,3,4$ \\),
 m4 = %str(Outcome (linear):  & $\tilde{Y}_{5,2}$ $\sim$ male, age, $Y_1$ &\\),
 m5 = %str(                   & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$, $Y_{t-1}$ & when $t = 2,3$\\),
 m6 = %str(                   & Y$_{5}$ $\sim$ male, age, $Y_4$, $Y_{3}$ &\\)
);
    
%plottex( data = results.tab3, tplate = tplate, out = tab3.txt, Nreps = 10000, fmt1 = 8.3, fmt2 = 10.4,
 h1 = %str(TMLE results from sample code 1.3.\\),
 indentm = 0.3in, nmparm = 5,   
 m1 = %str(Treatment (logit): & Trt $\sim$ male, age, $Y_1$\\),
 m2 = %str(Dropout (logit):   & D$_{1}$ $\sim$ male, age, $Y_{1}$, & \\),
 m3 = %str(                   & D$_{t}$ $\sim$ male, age, $Y_t$, $Y_{1}$ & when $t = 2,3,4$\\),
 m4 = %str(Outcome (linear):  & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$, $Y_{1}$ & when $t = 1,2,3$\\),
 m5 = %str(                   & Y$_{5}$ $\sim$ male, age, $Y_4$, $Y_{1}$\\)
);
    
%plottex( data = results.tab4, tplate = tplate, out = tab4.txt, Nreps = 10000, fmt1 = 8.3, fmt2 = 10.4,
 h1 = %str(TMLE results from sample code 1.4.\\),
 indentm = 0.3in, nmparm = 4,   
 m1 = %str(Treatment (logit): & Trt $\sim$ male, age, $Y_1$\\),
 m2 = %str(Dropout (logit):   & D$_{t}$ $\sim$ male, age, $Y_t$ & for $t=1,2,3,4$\\),
 m3 = %str(Outcome (logit):   & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$ & for $t = 1,2,3$ \\),
 m4 = %str(                   & Y$_{5}$ $\sim$ male, age, $Y_4$ & \\)
);

%plottex( data = results.tab5, tplate = tplate, out = tab5.txt, Nreps = 10000, fmt1 = 8.3, fmt2 = 10.4,
 h1 = %str(TMLE results from sample code 1.5.\\),
 indentm = 0.3in, nmparm = 7,   
 m1 = %str(Treatment (logit): & Trt $\sim$ male, age, $Y_1$\\),
 m2 = %str(Dropout (logit):   & D$_{t}$ $\sim$ male, age, $Y_t$ & when $t=1,3$\\),
 m3 = %str(                   & D$_{t}$ $\sim$ male, age, $Y_t$, Aux1 & when $t=2$\\),
 m4 = %str(                   & D$_{t}$ $\sim$ male, age, $Y_t$, Aux2 & when $t=4$\\),
 m5 = %str(Outcome (linear):  & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$ & when $t=1,3$\\),
 m6 = %str(                   & $\tilde{Y}_{5,t+1}$ $\sim$ male, age, $Y_t$, Aux1 & when $t=2$\\),
 m7 = %str(                   & Y$_{5}$ $\sim$ male, age, $Y_4$, Aux2 & \\)
);


    

 
