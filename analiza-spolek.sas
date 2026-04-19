/*tworzenie biblioteki*/
LIBNAME PROJ '/sciezka/do/folderu/'; /*sciezka do folderu z danymi*/
%web_drop_table(WORK.IMPORT);
FILENAME REFFILE '/sciezka/do/folderu/lpp_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ.LPP;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ.LPP;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/ale_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ.ALE;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ.ALE;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/dnp_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ.DNP;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ.DNP;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/mdv_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ.MDV;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ.MDV;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/pco_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ.PCO;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ.PCO;
RUN;

/*wybor odpowiednich kolumn*/
DATA proj.ale;
	SET proj.ale;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj.dnp;
	SET proj.dnp;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj.lpp;
	SET proj.lpp;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj.mdv;
	SET proj.mdv;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj.pco;
	SET proj.pco;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

/*sortowanie po dacie*/
PROC SORT DATA=proj.ale;
	BY data;
RUN;

PROC SORT DATA=proj.dnp;
	BY data;
RUN;

PROC SORT DATA=proj.lpp;
	BY data;
RUN;

PROC SORT DATA=proj.mdv;
	BY data;
RUN;

PROC SORT DATA=proj.pco;
	BY data;
RUN;

/*zmiana nazw*/
DATA proj.cenaclose5;
	MERGE proj.ale(RENAME=(CenaClose=CenaClose_ALE)) 
		proj.dnp(RENAME=(CenaClose=CenaClose_DNP)) 
		proj.lpp(RENAME=(CenaClose=CenaClose_LPP)) 
		proj.mdv(RENAME=(CenaClose=CenaClose_MDV)) 
		proj.pco(RENAME=(CenaClose=CenaClose_PCO));
	BY data;
RUN;

/*sprawdzanie jakosci danych*/
ods pdf file="/sciezka/do/folderu/jakoscdanych.pdf";

PROC MEANS DATA=proj.cenaclose5 NMISS MIN MAX MEAN;
	TITLE "Jakość danych i statystyki cen";
RUN;

ods pdf close;

/*liczenie log st zwrotu*/
DATA proj.log_st_zwr;
	SET proj.cenaclose5;
	log_ALE=log(CenaClose_ALE / lag(CenaClose_ALE));
	log_DNP=log(CenaClose_DNP / lag(CenaClose_DNP));
	log_LPP=log(CenaClose_LPP / lag(CenaClose_LPP));
	log_MDV=log(CenaClose_MDV / lag(CenaClose_MDV));
	log_PCO=log(CenaClose_PCO / lag(CenaClose_PCO));

	IF _N_ > 1;
RUN;

/* tworzenie wykresow z cenami zamkniecia spolek*/
ods pdf file="/sciezka/do/folderu/cenyzspolek.pdf";
ods graphics /imagemap=on;
PROC SGPLOT data=proj.cenaclose5;
	title "Ceny zamknięcia wybranych spółek (2024-2026)";
	series x=data y=CenaClose_ALE / curvelabel="Allegro";
	series x=data y=CenaClose_DNP / curvelabel="Dino";
	series x=data y=CenaClose_MDV / curvelabel="Modivo";
	series x=data y=CenaClose_PCO / curvelabel="Pepco";
	yaxis label="Cena zamknięcia (PLN)";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/cenyzlpp.pdf";

PROC SGPLOT data=proj.cenaclose5;
	title "Ceny zamknięcia spółki LPP (2024-2026)";
	series x=data y=CenaClose_LPP / curvelabel="LPP";
	yaxis label="Cena zamknięcia (PLN)";
	keylegend / title="Spółka:";
RUN;

ods pdf close;

/*Badanie współzależności stóp zwrotu*/
ods pdf file="/sciezka/do/folderu/logarytm_st.pdf";

PROC CORR data=proj.log_st_zwr plots=matrix(histogram);
	var log_ALE log_DNP log_LPP log_MDV log_PCO;
	title "Badanie współzależności stóp zwrotu";
RUN;

ods pdf close;

/* wykesy log stop zwrotu*/
ods pdf file="/sciezka/do/folderu/log_lpp.pdf";

PROC SGPLOT data=proj.log_st_zwr;
	title "Logarytmiczna stopa zwrotu LPP (2024-2026)";
	series x=data y=log_LPP / curvelabel="LPP";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_ale.pdf";

PROC SGPLOT data=proj.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Allegro (2024-2026)";
	series x=data y=log_ALE / curvelabel="Allegro";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_dnp.pdf";

PROC SGPLOT data=proj.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Dino Polska (2024-2026)";
	series x=data y=log_DNP / curvelabel="Dino";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_mdv.pdf";

PROC SGPLOT data=proj.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Modivo (2024-2026)";
	series x=data y=log_MDV / curvelabel="Modivo";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_pco.pdf";

PROC SGPLOT data=proj.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Pepco (2024-2026)";
	series x=data y=log_PCO / curvelabel="Pepco";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;