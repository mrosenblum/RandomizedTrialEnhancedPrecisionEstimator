options nodate nocenter nonumber ls=200 ps=100;

  libname data    "../Data";
  libname results "Results";

  filename macs "../../macros";
  options sasautos = ( sasautos macs );

  data modeldata;
     length modeltype  $12;
     length rhs        $200;
     modeltype = "dropout";  tpt = 1;  rhs  = "male age y1";       output;
     modeltype = "dropout";  tpt = 2;  rhs  = "male age aux1 y2";  output;
     modeltype = "dropout";  tpt = 3;  rhs  = "male age y3";       output;
     modeltype = "dropout";  tpt = 4;  rhs  = "male age aux2 y4";  output;
     
     modeltype = "outcome";  tpt = 2;  rhs  = "male age y1";       output;
     modeltype = "outcome";  tpt = 3;  rhs  = "male age aux1 y2";  output;
     modeltype = "outcome";  tpt = 4;  rhs  = "male age y3";       output;
     modeltype = "outcome";  tpt = 5;  rhs  = "male age aux2 y4";  output;
  run;
  proc print data = modeldata;
  run;    

  ods _all_ close;
  options nonotes;
  
  %tmle(
     data           = data.example2,
     out            = results.model6,
     outtab         = results.tab6,
     nreps          = 10000,
     seed           = 1831,
     A              = trt,
     outcomeVars    = y1-y5,
     treatmentModel = male age y1,
     dropoutModel   = male age,
     outcomeModel   = male age,
     modeldata      = modeldata,
     convgData      = convgData6,
     convgSummary   = results.convgSummary6);

 ods listing;
 options notes;
 proc print data = results.model6;
 proc print data = results.tab6;
 proc print data = results.convgSummary6;    
 run;
