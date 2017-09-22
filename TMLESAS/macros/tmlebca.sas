%macro tmlebca( ohits =,  sampresults = , main = , t0 =, t =, out =, nobs =, sample = sample, tile = .95);

data both;
  merge &ohits &sampresults;
  by &sample;
  _ww = ( &t < &t0 );
proc means data = both noprint;
  var _ww;
  output   out   = tvals(drop = _freq_ _type_ )
           mean  = meanww;
proc reg data = both;
  ods output parameterestimates = pe;
  model &t = x2-x&nobs;
run;
data pe;
  set pe ( where = (df ne 0 or variable = "Intercept" ));
  if variable = "Intercept" then beta = 0;
  else beta = Estimate;
proc means data = pe noprint;
    var beta;
    output  out =  meanpe
            mean = meanbeta;
run;

data pe;
    set pe;
    if _n_ = 1 then do;
        set meanpe;
    end;
    L  = beta - meanbeta;
    L2 = L * L;
    L3 = L * L * L;
proc means data = pe noprint;
  var L2 L3;
  output out = sumL
         sum = sumL2 sumL3;
run;

data results;
  set &main;
  if _n_ = 1 then do;
     set sumL;
     set tvals;
  end;

  a  = sumL3  / ( 6.0 * ( sumL2 ** 1.5 ) );
  w  = quantile("normal", meanww, 0, 1 );

  tile = &tile;

  qtileL = quantile("normal", (1-tile)/2,0,1);
  qtileU = quantile("normal", (1+tile)/2,0,1);
  adjaL  = cdf("normal", w + ( w + qtileL ) / ( 1 - a * ( w + qtileL )), 0, 1 );
  adjaU  = cdf("normal", w + ( w + qtileU ) / ( 1 - a * ( w + qtileU )), 0, 1 );
run;
proc sort data = &sampresults out = sampr(keep = &t);
   by &t;
data &out;
   set sampr end=last nobs=nsamples;
   indx = _n_;
   retain pickLow pickHigh;
   retain bcaLB bcaUB;
   
   if _n_ = 1 then do;
      set  results( keep = adjaL adjaU );
      pickLow  = floor(adjaL * nsamples);
      pickHigh = ceil (adjaU * nsamples);
   end;
   if indx = pickLow  then bcaLB = &t;
   if indx = pickHigh then bcaUB = &t;

   if last;
   keep bcaLB bcaUB; 
run;
%mend;
