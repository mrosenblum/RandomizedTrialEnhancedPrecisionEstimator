%macro clevels(clevels = );
  %global ptilelist fclevel fcleveltxt;  

  data _null_;
    clevels = "&clevels";
    words   = countw(clevels," ");

    length ptilelist $ 200;
    do i = 1 to words;
      clevel = input( scan(clevels,i," "), best32. );  
      if clevel > 1 then clevel = clevel / 100;

      if i = 1 then do;
        call symputx("Fclevel",    put(clevel,     best12. ) );
        call symputx("Fcleveltxt", put(100*clevel, best12. ) );
      end;        
     
      ptile2low  = 100 * ( 1.0 - clevel ) / 2;
      ptile2high = 100 * ( 1.0 + clevel ) / 2;

      ptilelist = cat( cats(ptilelist), " ", cats( put(ptile2low, 9.1) ), " ", cats( put(ptile2high, 9.1) ) ); 
    end;
    call symputx("ptilelist",put(ptilelist,$80.));
  run;
%mend;
