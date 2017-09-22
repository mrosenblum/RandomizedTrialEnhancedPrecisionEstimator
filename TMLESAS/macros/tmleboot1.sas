%macro TMLEboot1( data =, out =, nreps = 1, type = 1, seed1 = 3121, uid = _uid, outhits = ohits, strata = );

        * and unique if variable and split into treatment groups ;
/*        data d;
          set &data end = last nobs=nobs;
          &uid = _n_;
          if last then do;
            call symputx("Nobs",put(nobs,8.));
          end;
        run;
        %if ( &strata ne %str() ) %then %do;
          proc sort data = d;
            by &strata;  
        %end;  
*/  
        proc surveyselect
            data   = &data
            out    = sample1_( rename = ( replicate = sample )) 
            seed   = &seed1
            method = URS
            rate   = 1
            reps   = &nreps;
          %if ( &strata ne %str() ) %then %do;
              strata &strata;
          %end;    
        proc sort data = sample1_ out = samples_;
          by sample &uid;
        run;

        data &outhits;
          set samples_( keep = sample _uid NumberHits );
          by sample &uid;
          array X[&nobs] X1-X&nobs;
          retain X1-X&nobs;
          if first.sample then do;
            do i = 1 to &nobs;
              x[i] = 0;
            end;
          end;
          x[_uid] = NumberHits;
          if last.sample;
          keep sample X1-X&nobs;
        run;
        data &out;
          set samples_;
          do i = 1 to NumberHits;
            output;
          end;
          drop i ExpectedHits SamplingWeight ;
        run;  
%mend;
