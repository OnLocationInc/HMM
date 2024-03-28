*BEGIN MODEL PREP

* Calculations based parameters read in from h2_inputs.gdx
set      ProdActiveTechs(h2prodtech)
         ProdNGTechs(h2prodtech)
         ProdNGSeqTechs(h2prodtech)
         ProdCLTechs(h2prodtech)
         ProdCLSeqTechs(h2prodtech)
         ProdELTechs(h2prodtech)
         ProdBMTechs(h2prodtech)
         ProdBMSeqTechs(h2prodtech)
         ProdNucTechs(h2prodtech)
         ProdRenTechs(h2prodtech)
;

Set      LastYear(CalYears)
         ExtHorizon(CalYears)
         CenDivNatl(CensusDiv)
         StepOne(Steps)
         DollarYear(GDPYears) Read as input
         FirstGDPYear(GDPYears)
         Horizon /1*100/;
;

Parameter
         ProdFuelConsumptionPerTech(Fuels, h2prodtech)
         ProdReferenceYearPerTech(h2prodtech)
         ProdStartYearPerTech(h2prodtech)
         ProdDesignCapacityPerTech(h2prodtech)
         ProdProcessCO2PerTech(h2prodtech)
         ProdProcessCO2FracCapturedPerTech(h2prodtech)
         ProdCapitalCostsPerTech(h2prodtech)
         ProdFixedO_MCostsPerTech(h2prodtech)
         ProdVariableO_MCostsPerTech(h2prodtech)
         ProdLearningAlphaPerTech(h2prodtech)
         ProdLearningBetaPerTech(h2prodtech)
         ProdCapacityFactorPerTech(h2prodtech)
         PipelineReferenceYear
         PipeFlowRate
         PipeO_MCosts
         PipeCapitalCosts
         PipeCompressorReferenceYear
         PipeCompressorFlowRate
         PipeCompressorVariableO_MCosts
         PipeCompressorFixedO_MCosts
         PipeCompressorCapitalCosts
         PipeCompressorPowerConsumption(Fuels)
         StorageReferenceYear
         StorageDesignCapacity
         StorageVariableO_MCosts
         StorageFixedO_MCosts
         StorageCapitalCosts
         StorageCompressorPowerConsumption(Fuels)
;

Parameter
         CURCALYR
         CURITR
         GDP_Deflator(GDPYears)
         AvgGDP_Growth
         Emission_Tax(CalYears)
         FuelPrice(Fuels,CensusDiv,CalYears)
         PBMH2CL(Coal_Region,CalYears)        PBMH2CL in model dimensions
         EmissionFactors(Fuels,CalYears)
         BondRate Average 10-Yr Treasury bond rate over the model time horizon
         EquityRate
         CRF
         TnS_Costs(CensusDiv,CalYears)
         I_45Q_DURATION
         I_45Q_LYR_NEW
         QHMM(Market_Quantity,CensusDiv,CalYears)       QHMM in model dimensions
         QUREL(CensusDiv,CalYears)                      QUREL in model dimensions
         QPVEL(CensusDiv,CalYears)                      QPVEL in model dimensions
         QWIEL(CensusDiv,CalYears)                      QWIEL in model dimensions
         WHRFOSS(CensusDiv,CalYears)                   WHRFOSS in model dimensions
;

   ProdFuelConsumptionPerTech(Fuels, h2prodtech)= prodtech_props(Fuels,h2prodtech) ;

* Process production inputs
ProdActiveTechs(h2prodtech) =  prodtech_props('Active',h2prodtech) $ (prodtech_props('Active',h2prodtech)=1) ;
ProdNGTechs(h2prodtech) =  prodtech_props('ProdTechNG',h2prodtech) $ (prodtech_props('ProdTechNG',h2prodtech)=1) ;
ProdNGSeqTechs(h2prodtech) =  prodtech_props('ProdTechNG',h2prodtech) $ (prodtech_props('ProdTechNG',h2prodtech)=2) ;
ProdCLTechs(h2prodtech) =  prodtech_props('ProdTechCL',h2prodtech) $ (prodtech_props('ProdTechCL',h2prodtech)=1) ;
ProdCLSeqTechs(h2prodtech) =  prodtech_props('ProdTechCL',h2prodtech) $ (prodtech_props('ProdTechCL',h2prodtech)=2) ;
ProdELTechs(h2prodtech) =  prodtech_props('ProdTechEL',h2prodtech) $ (prodtech_props('ProdTechEL',h2prodtech)=1) ;
ProdBMTechs(h2prodtech) =  prodtech_props('ProdTechBM',h2prodtech) $ (prodtech_props('ProdTechBM',h2prodtech)=1) ;
ProdBMSeqTechs(h2prodtech) =  prodtech_props('ProdTechBM',h2prodtech) $ (prodtech_props('ProdTechBM',h2prodtech)=2) ;
ProdNucTechs(h2prodtech) =  prodtech_props('ProdTechNuc',h2prodtech) $ (prodtech_props('ProdTechNuc',h2prodtech)=1) ;
ProdRenTechs(h2prodtech) =  prodtech_props('ProdTechRen',h2prodtech) $ (prodtech_props('ProdTechRen',h2prodtech)=1) ;

* Year-based inputs
ProdReferenceYearPerTech(ProdActiveTechs) = prodtech_props('Reference year',ProdActiveTechs) ;
ProdStartYearPerTech(ProdActiveTechs) = prodtech_props('Assumed start-up year',ProdActiveTechs) ;
ProdDesignCapacityPerTech(ProdActiveTechs) = DaysInYear * prodtech_props('Plant Design Capacity',ProdActiveTechs) ;
ProdProcessCO2PerTech(ProdActiveTechs) = prodtech_props('Process CO2 produced after Capture',ProdActiveTechs) ;
ProdProcessCO2FracCapturedPerTech(ProdActiveTechs) = prodtech_props('Fraction CO2 Captured',ProdActiveTechs) ;
ProdCapitalCostsPerTech(ProdActiveTechs) = prodtech_props('Total Capital Costs',ProdActiveTechs)/(ProdDesignCapacityPerTech(ProdActiveTechs)/1e6) ;
ProdFixedO_MCostsPerTech(ProdActiveTechs) = prodtech_props('Total Fixed Operating Costs',ProdActiveTechs)/(ProdDesignCapacityPerTech(ProdActiveTechs)/1e6) ;
ProdVariableO_MCostsPerTech(ProdActiveTechs) = prodtech_props('Total Variable Operating Costs',ProdActiveTechs) ;
ProdVariableO_MCostsPerTech(ProdActiveTechs) = (ProdVariableO_MCostsPerTech(ProdActiveTechs) - prodtech_props('Total Energy Costs',ProdActiveTechs)) /
                                                (ProdDesignCapacityPerTech(ProdActiveTechs)/1e6) ;
ProdLearningAlphaPerTech(ProdActiveTechs) = prodtech_props('Alpha',ProdActiveTechs) ;
ProdLearningBetaPerTech(ProdActiveTechs) = prodtech_props('Beta',ProdActiveTechs) ;
ProdCapacityFactorPerTech(ProdActiveTechs) = prodtech_props('Operating Capacity Factor',ProdActiveTechs)/100 ;

* Process transportation inputs
PipelineReferenceYear = pipetech_props('Reference year') ;
PipeFlowRate = pipetech_props('Peak Hydrogen Flowrate') * DaysInYear ;
PipeO_MCosts = pipetech_props('Total O&M Costs')/(PipeFlowRate/1e6) ;
PipeCapitalCosts = pipetech_props('Total Capital Investment')/(PipeFlowRate/1e6) ;

* Year-based parameters for compressor
PipeCompressorReferenceYear = pipetech_props('Reference year') ;
PipeCompressorFlowRate = comptech_props('Net Hydrogen Dispensed at Stations') ;
PipeCompressorVariableO_MCosts = comptech_props('Electricity Costs')*1e6/PipeCompressorFlowRate ;
PipeCompressorFixedO_MCosts = comptech_props('Total O&M Costs')*1e6/PipeCompressorFlowRate - PipeCompressorVariableO_MCosts ;
PipeCompressorCapitalCosts = comptech_props('Total Capital Costs')*1e6/PipeCompressorFlowRate ;
PipeCompressorPowerConsumption('Electricity') = comptech_props('Electricity Consumption')/1/PipeCompressorFlowRate ;

*Process storage inputs
StorageReferenceYear = stortech_props('Reference year');
StorageDesignCapacity = stortech_props('Design Cavern Capacity');
StorageVariableO_MCosts = stortech_props('Electricity Costs')*1e6/StorageDesignCapacity;
StorageFixedO_MCosts = stortech_props('Total O&M Costs')*1e6/StorageDesignCapacity - StorageVariableO_MCosts;
StorageCapitalCosts = stortech_props('Total Capital Costs')*1e6/StorageDesignCapacity;
StorageCompressorPowerConsumption('Electricity') = stortech_props('Electricity Consumption')/1/StorageDesignCapacity;

I_45Q_DURATION=TCS45Q_I_45Q_DURATION;
I_45Q_LYR_NEW=TCS45Q_I_45Q_LYR_NEW;
LastYear(CalYears)$(CalYears.val=LastModelYear)=yes;
ExtHorizon(CalYears)$(CalYears.val > LastModelYear)=yes;
CenDivNatl(CensusDiv)$(CensusDiv.val=NationalCR) = yes;
StepOne(Steps)$(ord(Steps)=1) = yes;
DollarYear(CalYears)$(CalYears.val=dollar_year) = yes;
FirstGDPYear(GDPYears)$GDPYears.first = yes;

* Set up GDP calendar and Extend GDP deflator and emissions tax beyond 2050
GDP_Deflator(GDPYears) = sum(GDPYearMap(MNUMY3,GDPYears),MACOUT_MC_JPGDP(MNUMY3))  ;
AvgGDP_Growth = sum(GDPYears$(GDP_Deflator(GDPYears) > 0 and not FirstGDPYear(GDPYears)),  GDP_Deflator(GDPYears)/ GDP_Deflator(GDPYears-1))/
                 sum(GDPYears$(GDP_Deflator(GDPYears) > 0 and not FirstGDPYear(GDPYears)), 1) ;
GDP_Deflator(ExtHorizon) = sum(LastYear,GDP_Deflator(LastYear))*power(AvgGDP_Growth, ExtHorizon.val-LastModelYear);

Emission_Tax(CalYears) = sum(CalYearMap(MNUMYR,CalYears),EMISSION_EMETAX(MNUMYR))  ;
Emission_Tax(ExtHorizon) = sum(LastYear,Emission_Tax(LastYear))  ;

* Set up fuel prices and Extend beyond 2050
FuelPrice('Electricity',CenDivOpt,CalYears) = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(CalYearMap(MNUMYR,CalYears),EUSPRC_PELINP(MNUMYR,MNUMCR)))/MMBTU_to_KWH  ;

FuelPrice('Natural Gas',CenDivOpt,CalYears) = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(CalYearMap(MNUMYR,CalYears),AMPBLK_PNGIN(MNUMYR,MNUMCR)))  ;

FuelPrice('Coal',CenDivOpt,CalYears) = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(CalYearMap(MNUMYR,CalYears),AMPBLK_PCLIN(MNUMYR,MNUMCR)))  ;

PBMH2CL(Coal_Region,CalYears) = sum(CoalRegionMap(NDRGN1,Coal_Region),sum(CalYearMap(MNUMYR,CalYears), WRENEW_PBMH2CL(NDRGN1,MNUMYR,'4_MNMFS1')))  ;
FuelPrice('Biomass',CenDivOpt,CalYears) = sum(Coal_Region_Map(CenDivOpt,Coal_Region),PBMH2CL(Coal_Region,CalYears))  ;


FuelPrice(Fuels,CenDivOpt,ExtHorizon) = sum(LastYear,FuelPrice(Fuels, CenDivOpt, LastYear))  ;
FuelPrice(Fuels,CenDivOpt,CalYears) = FuelPrice(Fuels, CenDivOpt, CalYears)*GDP_Deflator(CalYears) ;

* Process emissions factors from NEMS and extend past 2050
EmissionFactors('Natural Gas',CalYears) =  sum(CalYearMap(MNUMYR,CalYears),EMEBLK_ENGHM(MNUMYR)) ;
EmissionFactors('Biomass',CalYears) =  -1*sum(CalYearMap(MNUMYR,CalYears),EMEBLK_EBMHM(MNUMYR)) ;
EmissionFactors('Coal',CalYears) =  sum(CalYearMap(MNUMYR,CalYears),EMEBLK_ECLHM(MNUMYR)) ;
EmissionFactors(Fuels,ExtHorizon) = sum(LastYear,EmissionFactors(Fuels, LastYear))  ;

* Average 10-Yr Treasury bond rate over the model time horizon
BondRate = 0.01*sum(CalYearMap(MNUMYR,CalYears),MACOUT_MC_RMGBLUSREAL(MNUMYR))/card(MNUMYR) ;
EquityRate = BondRate + Beta*(EMRP - BondRate);
CRF = EquityRate/(1 - 1/power(1 + EquityRate,30)) ;

*Calculate TnS cost as average over fuel region within a census division
TnS_Costs(CenDivOpt,CalYears) = sum((MAXNFR,MNUMYR,Fuel_Region)$(Fuel_Region_Map(Fuel_Region,CenDivOpt) and FuelRegion_2_MAXNFR(Fuel_Region,MAXNFR)
         and CalYearMap(MNUMYR,CalYears)), UECPOUT_TNS_COSTS(MNUMYR,MAXNFR)) /
         sum((Fuel_Region)$Fuel_Region_Map(Fuel_Region,CenDivOpt), 1);

*Convert dimensions of HMMBLK_QHMM:  M10 to MarketQuantity, MNUMCR to CensusDiv, MNUMYR to CalYears
QHMM(Market_Quantity,CenDivOpt,CalYears) = sum((M10,MNUMCR,MNUMYR)$(MarketQ_2_M10(Market_Quantity,M10) and CensusRegionMap(MNUMCR,CenDivOpt) and CalYearMap(MNUMYR,CalYears)),HMMBLK_QHMM(MNUMCR,MNUMYR,M10))  ;
QUREL(CensusDiv,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv),sum(CalYearMap(MNUMYR,CalYears),QBLK_QUREL(MNUMYR,MNUMCR))) ;
QWIEL(CensusDiv,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv),sum(CalYearMap(MNUMYR,CalYears),QBLK_QWIEL(MNUMYR,MNUMCR))) ;
QPVEL(CensusDiv,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv),sum(CalYearMap(MNUMYR,CalYears),QBLK_QPVEL(MNUMYR,MNUMCR))) ;
WHRFOSS(CensusDiv,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv),sum(CalYearMap(MNUMYR,CalYears),COGEN_WHRFOSS(MNUMYR,MNUMCR))) ;

