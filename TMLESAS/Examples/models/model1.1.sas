 options nodate nocenter nonumber ls=200 ps=100;

 libname data    "../Data";
 libname results "Results";

 filename macs "../../macros";
 options sasautos = ( sasautos macs );

 data example1;
   set data.example1;
   keep male age y1-y5 trt; 
 proc print data = example1(obs=20);
 run;

 ods _all_ close;
 options nonotes;
 %tmle(
   data           = example1,
   out            = results.model1,
   outtab         = results.tab1,
   nreps          = 10000,
   seed           = 31,
   A              = trt,
   outcomeVars    = y1-y5,
   treatmentModel = male age y1,
   dropoutModel   = male age,
   outcomeModel   = male age,
   clevels        = 95,
   convgData      = convgData1,
   convgSummary   = results.convgSummary1,
   sampleout      = sample1);

 ods listing;
 options notes;
 proc print data = results.tab1;
 proc print data = results.convgSummary1;
 proc print data = sample1(obs=25);
 proc print data = convgData1(obs=25);
 run;
