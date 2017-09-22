%macro tmlepdf( data =, out =, dformat = 10.4, dformatR = 10.4,
                text1 =, text2 =, text3 =, text4 =, fnote1 =, fnote2 =, fnote3 =, fnote4 =, clevel = 95 );  
  options missing=" ";
  ods pdf file = "&out" style=journal notoc startpage=never dpi=600;
  ods escapechar='^';
  title;

  ods pdf text="                                                              ";
  ods pdf text="                                                              ";
  %if "&text1" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial paddingtop=12px paddingbottom=12px}&text1";
  %end;    
  %if "&text2" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial paddingtop=12px paddingbottom=12px}&text2";
  %end;
  %if "&text3" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial paddingtop=12px paddingbottom=12px}&text3";
  %end;    
  %if "&text4" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial paddingtop=12px paddingbottom=12px}&text4";
  %end;    

  proc report data = &data nowd
      style(report)=[cellpadding=35px cellspacing=1px borderwidth=1px bordercolor=CX444444];
    label bcalb    = "Lower";
    label bcaub    = "Upper";
    label bcalba   = "Lower";
    label bcauba   = "Upper";
    label complete = "Estimate";
    label Estimate = "Estimate";
    label ratio    = "Efficiency";

    column label gap ( '^S={borderbottomcolor=black borderbottomwidth=1 } Complete Case' complete ( "BCA &clevel-% CI" bcalba bcauba ))
                 gap ( '^S={borderbottomcolor=black borderbottomwidth=1 } TMLE' estimate ( "BCA &cLevel-% CI" bcalb bcaub ))
                 gap ( "Relative" ratio );
    define label   / group " ";    
    define complete / mean f=&dformat   style(column)={width=0.7in} style(header)={just=right cellpadding=3}; /*style(column)={font_weight=bold}*/
    define estimate / mean f=&dformat   style(column)={width=0.7in} style(header)={just=right cellpadding=3}; /*style(column)={font_weight=bold}*/
    define bcalba   / mean f=&dformat   style(column)={width=0.6in} style(header)={just=right cellpadding=3};
    define bcauba   / mean f=&dformat   style(column)={width=0.6in} style(header)={just=right cellpadding=3};
    define bcalb    / mean f=&dformat   style(column)={width=0.6in} style(header)={just=right cellpadding=3};
    define bcaub    / mean f=&dformat   style(column)={width=0.6in} style(header)={just=right cellpadding=3};
    define ratio    / mean f=&dformatr  style(column)={width=0.7in} style(header)={just=right cellpadding=3};
    define gap      / ' '               style(column)={width=0.1in};
  run;
  %if "&fnote1" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial}&fnote1";
  %end;    
  %if "&fnote2" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial}&fnote2";
  %end;
  %if "&fnote3" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial}&fnote3";
  %end;    
  %if "&fnote4" ne "" %then %do;
      ods pdf text="(*ESC*)S={just=l font_size=10pt font_face=Arial}&fnote4";
  %end;

  options missing=" ";
  ods pdf close;
%mend;
