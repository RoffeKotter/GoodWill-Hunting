

* Rensa arbetsminnet
clear all

* Importera data från Excel
import excel "/Users/philipberlin/Desktop/Kandidatarbete/Uppladdning_Stata(1.10).xlsx", sheet("Datainsamling") firstrow

* Konvertera strängvariabler till numeriska variabler
destring WACC23 WACC22 WACC21 WACC20 WACC19 Anställda_n_23 Anställda_n_22 Anställda_n_21 Anställda_n_20 Anställda_n_19 ///
EBITDA_tkr_23 EBITDA_tkr_22 EBITDA_tkr_21 EBITDA_tkr_20 EBITDA_tkr_19 SGR__23 SGR__22 SGR__21 SGR__20 SGR__19 ///
VM__23 VM__22 VM__21 VM__20 VM__19 SL23 SL22 SL21 SL20 SL19 OMS_tkr_23 OMS_tkr_22 OMS_tkr_21 OMS_tkr_20 ///
OMS_tkr_19 GW_tkr_23 GW_tkr_22 GW_tkr_21 GW_tkr_20 GW_tkr_19 TT_tkr_2023 TT_tkr_2022 TT_tkr_2021 TT_tkr_2020 TT_tkr_2019 ///
SEK_tkr_23 SEK_tkr_22 SEK_tkr_21 SEK_tkr_20 SEK_tkr_19, replace force

* Ta bort onödiga variabler
drop Anställda_n_23 Anställda_n_22 Anställda_n_21 Anställda_n_20 Anställda_n_19 ///
EBITDA_tkr_23 EBITDA_tkr_22 EBITDA_tkr_21 EBITDA_tkr_20 EBITDA_tkr_19 ///
SGR__19 SGR__20 SGR__21 SGR__22 SGR__23  ///
ISIN LAND Organisationsnummer BRANSCH   ///

* Byt namn på variabler för enkelhet
rename GW_tkr_19 GW19
rename GW_tkr_20 GW20
rename GW_tkr_21 GW21
rename GW_tkr_22 GW22
rename GW_tkr_23 GW23

rename OMS_tkr_19 OMS19
rename OMS_tkr_20 OMS20
rename OMS_tkr_21 OMS21
rename OMS_tkr_22 OMS22
rename OMS_tkr_23 OMS23

rename SEK_tkr_19 SEK19
rename SEK_tkr_20 SEK20
rename SEK_tkr_21 SEK21
rename SEK_tkr_22 SEK22
rename SEK_tkr_23 SEK23

rename TT_tkr_2019 TT19
rename TT_tkr_2020 TT20
rename TT_tkr_2021 TT21
rename TT_tkr_2022 TT22
rename TT_tkr_2023 TT23

rename VM__19 VM19
rename VM__20 VM20
rename VM__21 VM21
rename VM__22 VM22
rename VM__23 VM23

rename GWN19Tkr GWN19
rename GWN20Tkr GWN20
rename GWN21Tkr GWN21
rename GWN22Tkr GWN22
rename GWN23Tkr GWN23

* Begränsa datamängden till de första 100 raderna
keep if _n <= 100

* Omforma data från brett till långt format
reshape long WACC SR OMS GW SEK TT VM INF GWN SL, i(FÖRETAG) j(year)

* Skapa en numerisk företagsidentifierare
encode FÖRETAG, gen(FÖRETAG_num)
label var FÖRETAG_num "Företagsidentifierare"

* Skapa förhållandet mellan eget kapital och goodwill
gen EK_GW = GW / SEK
gen EK_TT = SEK / TT
gen GWN_binary = 0
replace GWN_binary = 1 if GWN > 0

* Ställ in paneldata med företags-ID och år
xtset FÖRETAG_num year

* Skapa första differenser för variablerna
gen d_WACC = d.WACC
gen d_SR = d.SR
gen d_OMS = d.OMS
gen d_VM = d.VM
gen d_SL = d.SL
gen d_INF =d.INF
gen d_EK_GW = d.EK_GW
gen d_EK_TT = d.EK_TT
gen d_SR_GWN = d_SR * GWN_binary


* Ta bort observationer där GW är 0 för att undvika division med noll
drop if GW == 0

* Kör en regression med första differenser
asdoc xtreg d_WACC d_SR d_SL d_OMS d_EK_GW d_VM d_INF GWN_binary d_SR_GWN, fe vce(robust)
predict d_WACC_predicted, xb

* Korrelationstest mellan specifika variabler
asdoc pwcorr d_SR d_WACC d_EK_GW d_INF d_SL, sig star(0.05)

* 1. Multikollinearitetstest (VIF - Variance Inflation Factor)
asdoc regress d_WACC d_SR d_SL d_OMS d_EK_GW d_INF GWN_binary d_SR_GWN
vif

* Modell utan interaktionsterm
asdoc xtreg d_WACC d_SR d_SL d_OMS d_EK_GW d_INF GWN_binary, fe vce(robust)

* Modell med endast huvudvariabler
asdoc xtreg d_WACC d_SR d_INF, fe vce(robust)


* 6. Test för Modellens Antaganden (Normalfördelning av Residualer)
asdoc predict resid, residuals
hist resid, normal

* Skapa en scatterplot för d_WACC och d_SR med en trendlinje
scatter d_WACC d_SR, msize(small) mcolor(blue) ///
    || lfit d_WACC d_SR, lcolor(red) lwidth(medium) ///
    title("Scatterplot mellan d_WACC och d_SR") ///
    ytitle("Första differensen av WACC (d_WACC)") ///
    xtitle("Första differensen av SR (d_SR)") ///
    legend(label(1 "Observationer") label(2 "Trendlinje"))


* Ensure the year variable is numeric
destring year, replace force


* Ensure the data is sorted by year
sort year


* Beräkna medelvärden för varje variabel per år
 collapse (mean) d_WACC d_SR d_SL d_OMS d_EK_GW d_EK_TT d_VM d_INF, by(year)


* Skapa en graf för varje variabel
twoway (line d_INF year, sort) ///
       (line d_SR year, sort) ///
       (line d_WACC year, sort) ///
       (line d_SL year, sort) ///
       (line d_EK_GW year, sort), ///
       title("Medelvärde av differenser per år") ///
       legend(label(1 "INF") label(2 "SR") label(3 "WACC") label(4 "SL") label(5 "GW/EK")) ///
       xtitle("År") ytitle("Medelvärde")

	   
	   
	   
	   
	   
	   
	   
	   
	   
	   