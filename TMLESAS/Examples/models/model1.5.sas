options nodate nocenter nonumber ls=200 ps=100;

 libname data    "../Data";
 libname results "Results";

 filename macs "../../macros";
 options sasautos = ( sasautos macs );

 ods _all_ close;
 options nonotes;
 %tmle(
    data           = data.example2,
    out            = results.model5,
    outtab         = results.tab5,
    nreps          = 10000,
    seed           = 1831,
    A              = trt,
    outcomeVars    = y1-y5,
    treatmentModel = male age y1,
    dropoutModel   = male age,
    outcomeModel   = male age,
    dropoutmodel2  = male age aux1 y2,
    dropoutmodel4  = male age aux2 y4,
    outcomemodel2  = male age aux1 y2,
    outcomemodel4  = male age aux2 y4,
    convgData      = convgData5,
    convgSummary   = results.convgSummary5);

 ods listing;
 options notes;
 proc print data = results.model5;
 proc print data = results.tab5;
 proc print data = results.convgSummary5;    
 run;
