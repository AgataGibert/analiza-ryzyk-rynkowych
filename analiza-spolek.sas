/*1.Analiza Ryzyk i Przygotowanie Danych Rynkowych*/

/*tworzenie biblioteki*/
LIBNAME PROJ1 '/sciezka/do/folderu/'; /*sciezka do folderu z danymi*/
%web_drop_table(WORK.IMPORT);
FILENAME REFFILE '/sciezka/do/folderu/lpp_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ1.LPP;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ1.LPP;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/ale_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ1.ALE;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ1.ALE;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/dnp_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ1.DNP;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ1.DNP;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/mdv_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ1.MDV;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ1.MDV;
RUN;

FILENAME REFFILE '/sciezka/do/folderu/pco_d.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=PROJ1.PCO;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=PROJ1.PCO;
RUN;

/*wybor odpowiednich kolumn*/
DATA proj1.ale;
	SET proj1.ale;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj1.dnp;
	SET proj1.dnp;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj1.lpp;
	SET proj1.lpp;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj1.mdv;
	SET proj1.mdv;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

DATA proj1.pco;
	SET proj1.pco;
	KEEP data zamkniecie;
	RENAME zamkniecie=CenaClose;
RUN;

/*sortowanie po dacie*/
PROC SORT DATA=proj1.ale;
	BY data;
RUN;

PROC SORT DATA=proj1.dnp;
	BY data;
RUN;

PROC SORT DATA=proj1.lpp;
	BY data;
RUN;

PROC SORT DATA=proj1.mdv;
	BY data;
RUN;

PROC SORT DATA=proj1.pco;
	BY data;
RUN;

/*zmiana nazw i laczenie tabel*/
DATA proj1.cenaclose5;
	MERGE proj1.ale(RENAME=(CenaClose=CenaClose_ALE)) 
		proj1.dnp(RENAME=(CenaClose=CenaClose_DNP)) 
		proj1.lpp(RENAME=(CenaClose=CenaClose_LPP)) 
		proj1.mdv(RENAME=(CenaClose=CenaClose_MDV)) 
		proj1.pco(RENAME=(CenaClose=CenaClose_PCO));
	BY data;
RUN;

/*sprawdzanie jakosci danych*/
ods pdf file="/sciezka/do/folderu/jakoscdanych.pdf";

PROC MEANS DATA=proj1.cenaclose5 NMISS MIN MAX MEAN;
	TITLE "Jakość danych i statystyki cen";
RUN;

ods pdf close;

/*liczenie log st zwrotu*/
DATA proj1.log_st_zwr;
	SET proj1.cenaclose5;
	log_ALE=log(CenaClose_ALE / lag(CenaClose_ALE));
	log_DNP=log(CenaClose_DNP / lag(CenaClose_DNP));
	log_LPP=log(CenaClose_LPP / lag(CenaClose_LPP));
	log_MDV=log(CenaClose_MDV / lag(CenaClose_MDV));
	log_PCO=log(CenaClose_PCO / lag(CenaClose_PCO));
KEEP data log_ALE log_DNP log_LPP log_MDV log_PCO;
	IF _N_ > 1;
RUN;

/* tworzenie wykresow z cenami zamkniecia spolek*/
ods pdf file="/sciezka/do/folderu/cenyzspolek.pdf";
ods graphics /imagemap=on;
PROC SGPLOT data=proj1.cenaclose5;
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

PROC SGPLOT data=proj1.cenaclose5;
	title "Ceny zamknięcia spółki LPP (2024-2026)";
	series x=data y=CenaClose_LPP / curvelabel="LPP";
	yaxis label="Cena zamknięcia (PLN)";
	keylegend / title="Spółka:";
RUN;

ods pdf close;

/* wartości odstajace LPP*/
ods pdf file="/sciezka/do/folderu/outlieryLPP.pdf";
PROC SGPLOT data=proj1.log_st_zwr;
    title "Identyfikacja wartości odstających - Wykres pudełkowy stóp zwrotu LPP";
    vbox log_LPP;
    yaxis label="Logarytmiczna stopa zwrotu";
RUN;
ods pdf close;

/*Badanie współzależności stóp zwrotu*/
ods pdf file="/sciezka/do/folderu/logarytm_st.pdf";

PROC CORR data=proj1.log_st_zwr plots=matrix(histogram);
	var log_ALE log_DNP log_LPP log_MDV log_PCO;
	title "Badanie współzależności stóp zwrotu";
RUN;

ods pdf close;

/* wykesy log stop zwrotu*/
ods pdf file="/sciezka/do/folderu/log_lpp.pdf";

PROC SGPLOT data=proj1.log_st_zwr;
	title "Logarytmiczna stopa zwrotu LPP (2024-2026)";
	series x=data y=log_LPP / curvelabel="LPP";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_ale.pdf";

PROC SGPLOT data=proj1.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Allegro (2024-2026)";
	series x=data y=log_ALE / curvelabel="Allegro";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_dnp.pdf";

PROC SGPLOT data=proj1.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Dino Polska (2024-2026)";
	series x=data y=log_DNP / curvelabel="Dino";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_mdv.pdf";

PROC SGPLOT data=proj1.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Modivo (2024-2026)";
	series x=data y=log_MDV / curvelabel="Modivo";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;
ods pdf file="/sciezka/do/folderu/log_pco.pdf";

PROC SGPLOT data=proj1.log_st_zwr;
	title "Logarytmiczna stopa zwrotu Pepco (2024-2026)";
	series x=data y=log_PCO / curvelabel="Pepco";
	yaxis label="Logarytmiczna stopa";
	keylegend / title="Spółka:";
RUN;

ods pdf close;

/*Analiza Value at Risk (VaR) dla wybranych
portfeli akcji*/

/*ostatnie 250 dni */
DATA proj1.log_st_zwr250;
    SET proj1.log_st_zwr nobs=liczba_obs;
    IF _N_ > liczba_obs - 250;
RUN;
/*tworzenie portfeli*/

DATA proj1.portfel_rowne;
    LENGTH Spolka $10;
    INPUT Spolka $ Waga;
    datalines;
ALE 0.20
DNP 0.20
LPP 0.20
MDV 0.20
PCO 0.20
;
RUN;

DATA proj1.portfel_losowe;
    LENGTH Spolka $10;
    INPUT Spolka $;
    datalines;
ALE 
DNP 
LPP 
MDV 
PCO 
;
RUN;

/*przypisanie losowych wag*/
DATA proj1.portfel_losowe;
 SET proj1.portfel_losowe;
 CALL STREAMINIT(1234);
    i = rand("Uniform");
RUN;
PROC SQL;
CREATE TABLE proj1.portfel_losowe AS
    SELECT Spolka, 
           i / SUM(i) AS Waga
    FROM proj1.portfel_losowe;
QUIT;
/*wykresy portfeli*/
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=Spolka response=Waga / stat=mean;
		endlayout;
		endgraph;
	end;
run;

ods pdf file="/sciezka/do/folderu/wykresy_portfeli.pdf" style=HTMLBlue;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=proj1.PORTFEL_ROWNE;
run;

proc sgrender template=SASStudio.Pie data=proj1.PORTFEL_LOSOWE;
run;

ods graphics / reset;
title;
ods pdf close;
/*obliczanie dziennych stop zwrotow portfeli*/ 
data proj1.portfel_rowne_zwroty;
    set proj1.log_st_zwr250; 
    
    prosty_zwrot = (0.20 * (exp(log_ALE) - 1)) + 
                   (0.20 * (exp(log_DNP) - 1)) + 
                   (0.20 * (exp(log_LPP) - 1)) + 
                   (0.20 * (exp(log_MDV) - 1)) + 
                   (0.20 * (exp(log_PCO) - 1));
                   
    /* Powrót do logarytmicznej stopy zwrotu */
    zwrot_portfela = log(1 + prosty_zwrot);
    keep data zwrot_portfela;
run;

proc sql;
    create table proj1.portfel_losowe_zwroty as
    select a.data,
        
        /* Logarytm z (1 + średnia ważona prostych stóp zwrotu) */
        log(1 + 
            (select Waga from proj1.portfel_losowe where Spolka='ALE') * (exp(a.log_ALE) - 1) +
            (select Waga from proj1.portfel_losowe where Spolka='DNP') * (exp(a.log_DNP) - 1) +
            (select Waga from proj1.portfel_losowe where Spolka='LPP') * (exp(a.log_LPP) - 1) +
            (select Waga from proj1.portfel_losowe where Spolka='MDV') * (exp(a.log_MDV) - 1) +
            (select Waga from proj1.portfel_losowe where Spolka='PCO') * (exp(a.log_PCO) - 1)
        ) as zwrot_portfela
    from proj1.log_st_zwr250 as a;
quit;

/* obliczanie var */

proc means data=proj1.portfel_rowne_zwroty noprint;
    var zwrot_portfela;
    output out=statystyki_robocze (drop=_type_ _freq_)
           p5=var_hist_95_raw
           p1=var_hist_99_raw
           mean=Srednia
           std=Odchylenie;
run;


data proj1.portfel_rowne_var;
    set statystyki_robocze;
   wartosc_portfela = 10000;
   /* VaR historyczny */
    var_hist_95 = -var_hist_95_raw * wartosc_portfela ;
    var_hist_99 = -var_hist_99_raw * wartosc_portfela ;

   /* VaR parametryczny */
    var_para_95 = -(Srednia - 1.645 * Odchylenie)* wartosc_portfela ;
    var_para_99 = -(Srednia - 2.326 * Odchylenie)* wartosc_portfela ;


    drop wartosc_portfela var_hist_95_raw var_hist_99_raw Srednia Odchylenie;
run;

proc means data=proj1.portfel_losowe_zwroty noprint;
    var zwrot_portfela;
    output out=statystyki_robocze_losowe (drop=_type_ _freq_)
           p5=var_hist_95_raw
           p1=var_hist_99_raw
           mean=Srednia
           std=Odchylenie;
run;


data proj1.portfel_losowe_var;
    set statystyki_robocze_losowe;
     wartosc_portfela = 10000;
    /* VaR historyczny */
    var_hist_95 = -var_hist_95_raw * wartosc_portfela ;
    var_hist_99 = -var_hist_99_raw * wartosc_portfela ;

    /* VaR parametryczny */
    var_para_95 = -(Srednia - 1.645 * Odchylenie)* wartosc_portfela ;
    var_para_99 = -(Srednia - 2.326 * Odchylenie)* wartosc_portfela ;

  
    drop wartosc_portfela var_hist_95_raw var_hist_99_raw Srednia Odchylenie;
run;


ods pdf file="/sciezka/do/folderu/wyniki_VaR.pdf" style=HTMLBlue;

title "Wartosci VaR - Portfel o rownych wagach";
proc print data=proj1.portfel_rowne_var noobs; 
run;

title "Wartosci VaR - Portfel o losowych wagach";
proc print data=proj1.portfel_losowe_var noobs; 
run;

title;
ods pdf close;

/*Analiza porównawcza: Model Blacka-Scholesa vs
Symulacja Monte Carlo*/

/* odchylenie standardowe dzienne*/
proc means data=proj1.log_st_zwr std noprint;
	var log_LPP;
	output out=LPP_std (drop=_type_ _freq_) std=odchylenie_standard;
run;

/* zmiennosc roczna*/
data _null_;
	set LPP_std;
	call symputx('sigma', odchylenie_standard * sqrt(252));
run;

/* cena zamkniecia dnia ostatniego (S_0) */
data _null_;
	set proj1.cenaclose5 end=last;

	if last then
		call symputx('S0', CenaClose_LPP);
run;

%let K = &S0; /* Strike K ustawiony na najblizsza cene*/
%let T = 0.5; /* Termin wygasania pol roku */
%let r = 0.0585; /* stawka WIBOR 6M */
/*tabela parametrow*/
ods escapechar='^';
ods pdf file='/sciezka/do/folderu/tabela_parametrow.pdf';
data parametry;
    S_0=&S0;
	K=&K;
	T=&T;
	r=&r;
	sigma=&sigma;
run;
proc print data=parametry noobs label;
 label sigma = "^{unicode 03C3}";
run;
ods pdf close;


/*wycena wzorem Blacka-Scholesa */
ods pdf file='/sciezka/do/folderu/BS.pdf';
data BS;
	S=&S0;
	K=&K;
	T=&T;
	r=&r;
	sigma=&sigma;

	/* obliczenie d1 i d2 */
	d1=(log(S/K) + (r + (sigma**2)/2)*T) / (sigma * sqrt(T));
	d2=d1 - sigma * sqrt(T);

	/* wycena Call i Put */
	Call_BS=S * cdf('NORMAL', d1) - K * exp(-r*T) * cdf('NORMAL', d2);
	Put_BS=K * exp(-r*T) * cdf('NORMAL', -d2) - S * cdf('NORMAL', -d1);
	keep d1 d2 S Call_BS Put_BS;
run;
proc print data=BS noobs;
run;
ods pdf close;
/* wycena metodą Monte Carlo */

data MC_10000;
	call streaminit(333);

	/* Ustawienie ziarna losowości dla powtarzalnosci */
	S=&S0;
	K=&K;
	T=&T;
	r=&r;
	sigma=&sigma;

	do i=1 to 10000;
		Z=rand('NORMAL');

		/* rozklad normalny*/
		/* Generowanie indeksu bazowego (geometryczny ruch Browna) */
		IB=S * exp((r - 0.5*sigma**2)*T + sigma*sqrt(T)*Z);

		/* Wypłaty*/
		w_Call=max(IB - K, 0);
		w_Put=max(K - IB, 0);

		/* PV */
		Call_PV=exp(-r*T) * w_Call;
		Put_PV=exp(-r*T) * w_Put;
		output;
	end;
	keep Call_PV Put_PV;
run;

data MC_50000;
	call streaminit(333);

	/* Ustawienie ziarna losowości dla powtarzalnosci */
	S=&S0;
	K=&K;
	T=&T;
	r=&r;
	sigma=&sigma;

	do i=1 to 50000;
		Z=rand('NORMAL');

		/* rozklad normalny*/
		/* Generowanie indeksu bazowego (geometryczny ruch Browna) */
		IB=S * exp((r - 0.5*sigma**2)*T + sigma*sqrt(T)*Z);

		/* Wypłaty*/
		w_Call=max(IB - K, 0);
		w_Put=max(K - IB, 0);

		/* PV */
		Call_PV=exp(-r*T) * w_Call;
		Put_PV=exp(-r*T) * w_Put;
		output;
	end;
	keep Call_PV Put_PV;
run;

proc means data=MC_10000 mean noprint;
	var Call_PV Put_PV;
	output out=MC_10000_wynik (drop=_type_ _freq_) mean=Call_MC_10000 Put_MC_10000;
run;

data MC_10000_wynik;
	retain S;
	set MC_10000_wynik;
	
run;

proc means data=MC_50000 mean noprint;
	var Call_PV Put_PV;
	output out=MC_50000_wynik (drop=_type_ _freq_) mean=Call_MC_50000 Put_MC_50000;
run;

data MC_50000_wynik;
	retain S;
	set MC_50000_wynik;
	
run;
ods pdf file='/sciezka/do/folderu/MC.pdf';
proc print data=MC_10000_wynik noobs;
proc print data=MC_50000_wynik noobs;
run;
ods pdf close;
/* Zestawienie wyników */

data Zestawienie_Wynikow;
	merge BS(keep=S Call_BS Put_BS) MC_10000_wynik (keep=Call_MC_10000 
		Put_MC_10000) MC_50000_wynik (keep=Call_MC_50000 Put_MC_50000);

	/* roznice BS vs MC_50000*/
	/*call*/
	r_abs_BS50k_call=abs(Call_BS-Call_MC_50000); /*absolutna*/
	r_wzgl_BS50k_call=r_abs_BS50k_call/Call_BS; /*wzgledna*/
	
	/*put*/
	r_abs_BS50k_put=abs(Put_BS-Put_MC_50000); /*absolutna*/
	r_wzgl_BS50k_put=r_abs_BS50k_put/Put_BS; /*wzgledna*/
	
	/* roznice BS vs MC_10000*/
	/*call*/
	r_abs_BS_10k_call=abs(Call_BS-Call_MC_10000); /*absolutna*/
	r_wzgl_BS_10k_call=r_abs_BS_10k_call/Call_BS; /*wzgledna*/
	
	/*put*/
	r_abs_BS_10k_put=abs(Put_BS-Put_MC_10000); /*absolutna*/
	r_wzgl_BS_10k_put=r_abs_BS_10k_put/Put_BS; /*wzgledna*/
run;

data tabela_ceny;
    set Zestawienie_Wynikow;
    length Metoda $30;
    format Call Put 10.2;

    Metoda = "Model Blacka-Scholesa";
    Call = Call_BS; Put = Put_BS; output;

    Metoda = "Monte Carlo (N=10 000)";
    Call = Call_MC_10000; Put = Put_MC_10000; output;

    Metoda = "Monte Carlo (N=50 000)";
    Call = Call_MC_50000; Put = Put_MC_50000; output;
    
    keep Metoda Call Put;
run;
ods pdf file='/sciezka/do/folderu//wynikiBSMC.pdf';
proc print data=tabela_ceny noobs;
run;
ods pdf close;

data tabela_roznice;
    set Zestawienie_Wynikow;
    length Metoda $30;
    format wzgledna_call absolutna_call wzgledna_put absolutna_put 10.4;

    Metoda = "BS vs MC10000";
    wzgledna_call=r_wzgl_BS_10k_call;
    absolutna_call=r_abs_BS_10k_call;
    wzgledna_put=r_wzgl_BS_10k_put;
    absolutna_put=r_abs_BS_10k_put; output;

    Metoda = "BS vs MC50000";
   wzgledna_call=r_wzgl_BS50k_call;
   absolutna_call=r_abs_BS50k_call;
   wzgledna_put=r_wzgl_BS50k_put;
   absolutna_put=r_abs_BS50k_put; output;

    keep metoda wzgledna_call absolutna_call wzgledna_put absolutna_put;
   
run;
ods pdf file='/sciezka/do/folderu/tabroznice.pdf';
proc print data=tabela_roznice noobs;
run;
ods pdf close;

ods pdf close;
