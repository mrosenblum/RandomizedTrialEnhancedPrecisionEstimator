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
     out            = results.model3,
     outtab         = results.tab3,
     nreps          = 10000,
     seed           = 51,
     A              = trt,
     outcomeVars    = y1-y5,
     treatmentModel = male age y1,
     dropoutModel   = male age,
     outcomeModel   = male age y1,
     clevels        = 95,
     convgData      = convgData3,
     convgSummary   = results.convgSummary3);

 ods listing;
 options notes;
 proc print data = results.tab3;
 proc print data = results.convgSummary3;
 run;
    
