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
     out            = results.model2,
     outtab         = results.tab2,
     nreps          = 10000,
     seed           = 41,
     A              = trt,
     outcomeVars    = y1-y5,
     treatmentModel = male age y1,
     dropoutModel   = male age,
     outcomeModel   = male age,
     lagdropout     = 2,  
     clevels        = 95,
     convgData      = convgData2,
     convgSummary   = results.convgSummary2);

 ods listing;
 options notes;
 proc print data = results.tab2;
 proc print data = results.convgSummary2;
 run;
    
