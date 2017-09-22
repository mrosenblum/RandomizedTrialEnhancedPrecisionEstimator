options nodate nocenter nonumber ls=200 ps=100;

  libname data    "../Data";
  libname results "Results";

  filename macs "../../macros";
  options sasautos = ( sasautos macs );

  data example1;
    set data.example1;
    array y[5] y1-y5;
    do i = 1 to 5;
      y[i] = y[i] / 100;   
    end;
    keep male age y1-y5 trt; 
  proc print data = example1(obs=20);
  run;

 ods _all_ close;
 options nonotes;
 %tmle(
     data             = example1,
     out              = results.model4,
     outtab           = results.tab4,
     nreps            = 10000,
     seed             = 831,
     A                = trt,
     outcomeVars      = y1-y5,
     treatmentModel   = male age y1,
     dropoutModel     = male age,
     outcomeModel     = male age,
     outcomeModelType = lg,  
     clevels          = 95,
     convgData        = convgData4,
     convgSummary     = results.convgSummary4);

 ods listing;
 options notes;
 proc print data = results.tab4;
 proc print data = results.convgSummary4;
 run;
