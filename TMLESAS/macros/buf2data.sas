* convert buffer to dataset ;
%macro buf2data( buf =,      /* macro buffer to convert  */
                 out =       /* the dataset to create    */
    );
  %let buflen = %length(&buf);
  data _slurp;
    length char $1;
    length buf  $  &buflen;
    length part $  &buflen;

    %do i = 1 %to &buflen;
      i    = &i;  
      substr(buf,i,1) = "%qsubstr(&buf,&i,1)";
    %end;
    buf    = compbl(buf);
    lenbuf = length(buf);  * reduced version;

    inside = 0;
    start  = 0;
    end    = 0;
    j      = 0;
    part   = "";
    do i = 1 to lenbuf;
      char = substr(buf,i,1);  
      if substr(buf,i,1) = "(" then inside = inside + 1;
      if substr(buf,i,1) = ")" then inside = inside - 1;
      if start = 0 and inside = 1 then start = 1;
      if start = 1 and inside = 1 and substr(buf,i,1) = "," then end = 1;
      if start = 1 and inside = 0 and substr(buf,i,1) = ")" then end = 1;
      if ( inside = 1 and char = "(" ) then i = i + 1;
        if end = 0 and start = 1 then do;
          j = j + 1;
          substr(part,j,1) = substr(buf,i,1);
        end;
        else if end = 1 and start = 1 then do;
          part = trim(left(part));  
          lenpart = length(part);  
          output;
          part = "";
          end = 0;
          j = 0;
        end;   
    end;
  run;
  proc means data = _slurp noprint;
    var lenpart;
    output out = lenpart( drop = _: )
           n   = nterms
           max = lenpart;
  run;
  data _null_;
    set lenpart;
    call symputx("_nterms", put(nterms, 8.));
    call symputx("_lenpart",put(lenpart,8.));
  run;
  data &out( rename = ( part2 = part ) );
    length part2 $ &_lenpart;
    set _slurp;
    part2   = substr( part, 1, &_lenpart );
    lenpart = &_lenpart;
    nterms  = &_nterms;
    keep part2 lenpart nterms;
  run;
%mend;
