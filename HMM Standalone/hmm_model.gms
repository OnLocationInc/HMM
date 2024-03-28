* Start model setup and solve

CURCALYR=2023+Horizon.val-1;

ReadLastYearResult     = CreateYearlyGDXFile;

HorizonYears                          = sum(periods, Years_by_Period(periods)) ;
LastCalYear(CalYears)$(CalYears.val=LastModelYear) = yes;
ModelYears(CalYears) = no;
ModelYears(CalYears)$(CalYears.val >= CURCALYR and CalYears.val < CURCALYR + HorizonYears) = yes;

* set up planning period subsets for unplanned capacity
PlanningPeriodFirst(periods)$(ord(periods)=1) = yes;
PlanningPeriodSecond(periods)$(ord(periods)=2) = yes;
PlanningPeriodSecondThird(periods)$(ord(periods) > 1) = yes;

* set up planning period subsets for unplanned capacity
AvailableCap(capacity)$(ord(capacity)=1) = yes;
PlannedCap(capacity)$(ord(capacity)=2) = yes;

CurrentOptYear(CalYears) = no;
NextOptYear(CalYears) = no;
ThirdPeriodYears(CalYears) = no;
LastOptYear(CalYears) = no;
CurrentOptYear(CalYears)$(CalYears.val ge CURCALYR and CalYears.val le (CURCALYR + sum(PlanningPeriodFirst,Years_by_Period(PlanningPeriodFirst)) - 1)) = yes;
NextOptYear(CalYears)$(CalYears.val > CURCALYR + sum(PlanningPeriodFirst,Years_by_Period(PlanningPeriodFirst)) - 1 and CalYears.val <= CURCALYR + sum(PlanningPeriodFirst,Years_by_Period(PlanningPeriodFirst)) + sum(PlanningPeriodSecond,Years_by_Period(PlanningPeriodSecond)) - 1) = yes;
ThirdPeriodYears(CalYears)$(CalYears.val > CURCALYR + sum(PlanningPeriodFirst,Years_by_Period(PlanningPeriodFirst)) + sum(PlanningPeriodSecond,Years_by_Period(PlanningPeriodSecond)) - 1 and CalYears.val < CURCALYR + HorizonYears) = yes;
LastOptYear(CalYears)$(CalYears.val eq CURCALYR-1) = yes;

loop(CurrentOptYear(CalYears),
         if(CalYears.val eq FirstModelYear,
                 ReadLastYearResult     = 0;
         );
);

if((ReadLastYearResult eq 1),
         loop(LastOptYear(CalYears),
                 put_utility 'gdxin' / 'HMM_'LastOptYear.te(LastOptYear)'.gdx' ;
         );
    execute_load CO2CaptureQty45QCreditbyYear, CapacityProductionTaxCreditbyYear,
         CapacityInvestmentTaxCreditbyYear, CO2CaptureEOR45QCreditbyYear, CO2CaptureSaline45QCreditbyYear
         Section45VCreditbyYear, HydrogenPrice, repProductionUnplannedCapacity,
         repTransportationUnplannedCapacity,repStorageUnplannedCapacity
 ;
else
*Reporting variables reset in first year
  CO2CaptureQty45QCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
  CapacityProductionTaxCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
  CapacityInvestmentTaxCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
  CO2CaptureEOR45QCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
  CO2CaptureSaline45QCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
  Section45VCreditbyYear(h2prodtech,CensusDiv,CalYears) =0;

* Hydrogen prices beyond current year
  HydrogenPrice(CenDivOpt,SeasonOpt,CalYears)$(CalYears.val > CURCALYR) = 0 ;

  repProductionUnplannedCapacity(h2prodtech,CensusDiv,CalYears) = 0 ;
  repTransportationUnplannedCapacity(CensusDiv,CenDiv2,CalYears) = 0 ;
  repStorageUnplannedCapacity(h2stortech,CensusDiv,CalYears) = 0 ;

);

* only technologies active during current opt year.
ProdActiveOptTechs(ProdActiveTechs)$(ProdStartYearPerTech(ProdActiveTechs) <= CURCALYR) = yes;
StorageOptTechs(h2stortech)$(ord(h2stortech)=1) = yes;

*  The total fuel emissions are used to split the CO2 emissions by fuel when reporting outputs
TotalFuelEmissionsPerTech(ProdActiveTechs,CalYears) = sum(CombustionFuels, ProdFuelConsumptionPerTech(CombustionFuels,ProdActiveTechs)*EmissionFactors(CombustionFuels,CalYears)) ;

* subtract out carbon tax from fuel price i proportion to carbon captured
AdjustedFuelPricebyTech(Fuels, ProdActiveOptTechs, CenDivOpt, CalYears) = FuelPrice(Fuels,CenDivOpt,CalYears) - Emission_Tax(CalYears) * GDP_Deflator(CalYears)
                                                        * EmissionFactors(Fuels,CalYears) * ProdProcessCO2FracCapturedPerTech(ProdActiveOptTechs) ;

* Season fraction
MarketH2DemandSeasonFraction(Market_Quantity,SeasonOpt) = Season_Fraction(SeasonOpt);
MarketH2DemandSeasonFraction(Market_Quantity,SeasonOpt)$(Market_Quantity_Code_Season(Market_Quantity, SeasonOpt)) = 1;
MarketH2DemandSeasonFraction(Market_Quantity_EMM,SeasonOpt)$(MarketH2DemandSeasonFraction(Market_Quantity_EMM,SeasonOpt) < 1) = 0;

* Calculate demand by season; convert to thousand tons of hydrogen from trills
MarketH2DemandbySeason(Market_Quantity,CenDivOpt,SeasonOpt,CalYears) = 1e6*QHMM(Market_Quantity,CenDivOpt,CalYears)*MarketH2DemandSeasonFraction(Market_Quantity,SeasonOpt)/HydrogenHHV ;
MarketH2DemandbySeason(Market_Quantity,CenDivOpt,SeasonOpt,CalYears)$(CalYears.val > LastModelYear) = sum(LastCalYear,MarketH2DemandbySeason(Market_Quantity,CenDivOpt,SeasonOpt,LastCalYear)) ;
TotalH2MarketDemand(CenDivOpt,SeasonOpt,CalYears) = sum(Market_Quantity,MarketH2DemandbySeason(Market_Quantity,CenDivOpt,SeasonOpt,CalYears)) ;

ProductionCapacityAvailable(prod_tech,CensusDiv,NumYr) = sum(AvailableCap,prod_cap(prod_tech,CensusDiv,NumYr,AvailableCap)) ;
ProductionCapacityPlanned(prod_tech,CensusDiv,NumYr) = sum(PlannedCap,prod_cap(prod_tech,CensusDiv,NumYr,PlannedCap)) ;

* Reset unplanned capacity to zero past current year
repProductionUnplannedCapacity(h2prodtech,CensusDiv,CalYears)$(CalYears.val > CURCALYR) = 0 ;

TotalProductionCapacity(h2prodtech,CenDivOpt,CalYears) = 0;
TotalProductionCapacity(h2prodtech,CenDivOpt,CalYears)$(CalYears.val >= CURCALYR) = sum((prod_tech,NumYr)$(NumYr_2_CalYr(CalYears,NumYr) and Production_Code(prod_tech,h2prodtech)),
         ProductionCapacityAvailable(prod_tech,CenDivOpt,NumYr) + 0*ProductionCapacityPlanned(prod_tech,CenDivOpt,NumYr))
         + sum(CurrentOptYear,repProductionUnplannedCapacity(h2prodtech,CenDivOpt,CurrentOptYear)) ;

*  calculate multiple from base capacity by tech or a minimum of 100 for learning purposes
FirstYrProdCapacity(h2prodtech,CenDivOpt) = sum(CalYears,TotalProductionCapacity(h2prodtech,CenDivOpt,CalYears)$(CalYears.val=FirstModelYear))  ;
TotalProductionCapacityMultiple(ProdActiveOptTechs,CenDivOpt,CalYears)= 1 ;
TotalProductionCapacityMultiple(ProdActiveOptTechs,CenDivOpt,CalYears)$(TotalProductionCapacity(ProdActiveOptTechs,CenDivOpt,CalYears) > 100
             and FirstYrProdCapacity(ProdActiveOptTechs,CenDivOpt) > 0)
             =  TotalProductionCapacity(ProdActiveOptTechs,CenDivOpt,CalYears) / FirstYrProdCapacity(ProdActiveOptTechs,CenDivOpt) ;

* Nuclear generation limit (SOE-NUC)
ElectricityGenerationNuclearbyYear(CenDivOpt,CalYears) = QUREL(CenDivOpt,CalYears) / HeatRateNuclear * 1000 ;
ElectricityGenerationNuclearbyYear(CenDivOpt,ExtHorizon) = sum(LastYear,ElectricityGenerationNuclearbyYear(CenDivOpt,LastYear)) ;

* Electrolysis from renewable capacity limit
ElectricityGenerationRenewablebyYear(CenDivOpt,CalYears)$(WHRFOSS(CenDivOpt,CalYears) > 0) =
 (QPVEL(CenDivOpt,CalYears) + QWIEL(CenDivOpt,CalYears)) / WHRFOSS(CenDivOpt,CalYears) * 1000 ;
ElectricityGenerationRenewablebyYear(CenDivOpt,ExtHorizon) = sum(LastYear,ElectricityGenerationRenewablebyYear(CenDivOpt,LastYear)) ;

TransportationCapacityAvailable(CensusDiv,CenDiv2,NumYr) = sum(AvailableCap,trans_cap(CensusDiv,CenDiv2,NumYr,AvailableCap)) ;
TransportationCapacityPlanned(CensusDiv,CenDiv2,NumYr) = sum(PlannedCap,trans_cap(CensusDiv,CenDiv2,NumYr,PlannedCap)) ;
* Unplanned transportation capacity beyond current year
repTransportationUnplannedCapacity(CensusDiv,CenDiv2,CalYears)$(CalYears.val > CURCALYR) = 0 ;
* Total transportation capacity
TotalTransportCapacity(CenDivOpt,CenDivOpt2,CalYears) = 0;
TotalTransportCapacity(CenDivOpt,CenDivOpt2,CalYears)$(CalYears.val >= CURCALYR) =
    sum(NumYr$NumYr_2_CalYr(CalYears,NumYr),TransportationCapacityAvailable(CenDivOpt,CenDivOpt2,NumYr) + TransportationCapacityPlanned(CenDivOpt,CenDivOpt2,NumYr))
    + sum(CurrentOptYear,repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,CurrentOptYear)) ;

StorageCapacityAvailable(h2stortech,CensusDiv,NumYr) = sum(AvailableCap,stor_cap(h2stortech,CensusDiv,NumYr,AvailableCap)) ;
StorageCapacityPlanned(h2stortech,CensusDiv,NumYr) = sum(PlannedCap,stor_cap(h2stortech,CensusDiv,NumYr,PlannedCap)) ;

* Unplanned storage capacity beyond current year (set to zero)
repStorageUnplannedCapacity(h2stortech,CenDivOpt,CalYears)$(CalYears.val > CURCALYR) = 0 ;

* Total storage capacity
TotalStorageCapacity(StorageOptTechs,CenDivOpt,CalYears) = 0;
TotalStorageCapacity(StorageOptTechs,CenDivOpt,CalYears)$(CalYears.val >= CURCALYR) =
    sum(NumYr$NumYr_2_CalYr(CalYears,NumYr),StorageCapacityAvailable(StorageOptTechs,CenDivOpt,NumYr) + StorageCapacityPlanned(StorageOptTechs,CenDivOpt,NumYr))
    + sum(CurrentOptYear,repStorageUnplannedCapacity(StorageOptTechs,CenDivOpt,CurrentOptYear))  ;

* GDP Deflator in production reference year of prod tech
ProdRefDeflator(ProdActiveOptTechs) = sum(GDPYears, GDP_Deflator(GDPYears)$(GDPYears.val=ProdReferenceYearPerTech(ProdActiveOptTechs))) ;

* Calculate and annuitize unplanned production capacity costs
ProductionUnplannedCapacityCostbyYear(ProdActiveOptTechs,CenDivOpt,CalYears) = ProdCapitalCostsPerTech(ProdActiveOptTechs)
    * CRF / ProdRefDeflator(ProdActiveOptTechs) * GDP_Deflator(CalYears) ;

* Calculate and annuitize production O&M costs (fixed)
ProductionFixedO_MCostbyYear(ProdActiveOptTechs,CenDivOpt,CalYears) = ProdFixedO_MCostsPerTech(ProdActiveOptTechs) /
    ProdRefDeflator(ProdActiveOptTechs) * GDP_Deflator(CalYears) ;

* Calculate CO2 captured by production tech
ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) = ProdProcessCO2PerTech(ProdActiveOptTechs)*ProdProcessCO2FracCapturedPerTech(ProdActiveOptTechs)
    / (1 - ProdProcessCO2FracCapturedPerTech(ProdActiveOptTechs)) ;

* Calculate and annuitize production o&m costs (variable)
ProductionVariableO_MCostbyYear(ProdActiveOptTechs,CenDivOpt,CalYears) = (ProdVariableO_MCostsPerTech(ProdActiveOptTechs) /
    ProdRefDeflator(ProdActiveOptTechs) + ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) * TnS_Costs(CenDivOpt,CalYears)/1000) *
    GDP_Deflator(CalYears)  ;

* Calculate and annuitize unplanned transportation capacity cost
TransportUnplannedCapacityCostbyYear(CenDivOpt,CenDivOpt2,CalYears) = (PipeCapitalCosts*CRF + PipeO_MCosts) /
    sum(GDPYears,GDP_Deflator(GDPYears)$(GDPYears.val=PipelineReferenceYear)) * GDP_Deflator(CalYears) +
    (PipeCompressorCapitalCosts*CRF + PipeCompressorFixedO_MCosts) /
    sum(GDPYears,GDP_Deflator(GDPYears)$(GDPYears.val=PipeCompressorReferenceYear)) * GDP_Deflator(CalYears) ;

* Calculate and annuitize unplanned storage capacity cost
StorageUnplannedCapacityCostbyYear(StorageOptTechs,CenDivOpt,CalYears) = (StorageCapitalCosts*CRF + StorageFixedO_MCosts) /
    sum(GDPYears,GDP_Deflator(GDPYears)$(GDPYears.val=StorageReferenceYear)) * GDP_Deflator(CalYears) ;

* Section 45Q Tax Credits
CCS_SALINE_45Q(CalYears) = sum(CalYearMap(MNUMYR,CalYears),TCS45Q_CCS_SALINE_45Q(MNUMYR)) ;
Section45QSalineCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
Section45QSalineCreditbyYear(ProdActiveOptTechs,CenDivOpt,CalYears)$(CO2CaptureQty45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,CalYears) > 0
    or (CURCALYR=FirstModelYear and ProdProcessCO2FracCapturedPerTech(ProdActiveOptTechs) > 0)) =
    CCS_SALINE_45Q(CalYears) * GDP_Deflator(CalYears) ;
CCS_EOR_45Q(CalYears) = sum(CalYearMap(MNUMYR,CalYears),TCS45Q_CCS_EOR_45Q(MNUMYR)) ;
Section45QEORCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
Section45QEORCreditbyYear(ProdActiveOptTechs,CenDivOpt,CalYears)$(CO2CaptureQty45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,CalYears) > 0
    or (CURCALYR=FirstModelYear and ProdProcessCO2FracCapturedPerTech(ProdActiveOptTechs) > 0)) =
    CCS_EOR_45Q(CalYears) * GDP_Deflator(CalYears) ;

* Production Tax Credit by tech
loop(Steps,
ProductionTaxCreditbyTech(prod_tech,NumYr)$(lca_tech(NumYr,prod_tech) <= IRA_LCA(Steps)) = IRA_PTC(Steps) ;
) ;

ProductionTaxCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
ProductionTaxCreditbyYear(h2prodtech,CenDivOpt,CalYears)$(CalYears.val >= I_45V_SYR and CalYears.val < I_45V_LYR_NEW + I_45V_DURATION and
    (CapacityProductionTaxCreditByYear(h2prodtech,CenDivOpt,CalYears) > 0 or CURCALYR=FirstModelYear)) =
    sum((prod_tech,NumYr)$(NumYr_2_CalYr(CalYears,NumYr) and Production_Code(prod_tech,h2prodtech)),ProductionTaxCreditbyTech(prod_tech,NumYr)) * GDP_Deflator(CalYears) * I_45V_Multiplier ;

* Investment Tax Credit by tech
loop(Steps,
InvestmentTaxCreditbyTech(prod_tech,NumYr)$(lca_tech(NumYr,prod_tech) <= IRA_LCA(Steps) and
     sum(Production_Code(prod_tech,h2prodtech),ProdCapacityFactorPerTech(h2prodtech)) > 0) =
    (sum(Production_Code(prod_tech,h2prodtech),ProdCapitalCostsPerTech(h2prodtech)) * CRF +
    sum(Production_Code(prod_tech,h2prodtech),ProdFixedO_MCostsPerTech(h2prodtech)) /
    sum(Production_Code(prod_tech,h2prodtech),ProdCapacityFactorPerTech(h2prodtech))) * IRA_ITC(Steps)
);

* Investment Tax Credit by year
InvestmentTaxCreditbyYear(h2prodtech,CensusDiv,CalYears) = 0;
InvestmentTaxCreditbyYear(h2prodtech,CenDivOpt,CalYears)$(CalYears.val >= I_45V_SYR and CalYears.val < I_45V_LYR_NEW + I_45V_DURATION and
    (CapacityInvestmentTaxCreditByYear(h2prodtech,CenDivOpt,CalYears) > 0 or CURCALYR=FirstModelYear) and
     sum(Production_Code(prod_tech,h2prodtech),ProdRefDeflator(h2prodtech)) > 0)
     = sum((prod_tech,NumYr)$(NumYr_2_CalYr(CalYears,NumYr) and Production_Code(prod_tech,h2prodtech)),InvestmentTaxCreditByTech(prod_tech,NumYr))/sum(Production_Code(prod_tech,h2prodtech),ProdRefDeflator(h2prodtech))
    * GDP_Deflator(CalYears) * I_45V_Multiplier ;

*Set up slack prices
SlackCost(periods) = sum(CurrentOptYear, slack_cost*HorizonYears*GDP_Deflator(CurrentOptYear)) ;
SlackCost(PlanningPeriodFirst) = sum(CurrentOptYear, slack_cost*GDP_Deflator(CurrentOptYear)) ;
SlackCost(PlanningPeriodSecond) = sum(NextOptYear, slack_cost*GDP_Deflator(NextOptYear)) ;

YearPeriodMap(GDPYears,periods) = no;
YearPeriodMap(CurrentOptYear,PlanningPeriodFirst) = yes;
YearPeriodMap(NextOptYear,PlanningPeriodSecond) = yes;
YearPeriodMap(ThirdPeriodYears,periods)$(not(PlanningPeriodFirst(periods) or PlanningPeriodSecond(periods))) = yes;

YearIndex(ModelYears(CalYears))   = ord(CalYears) - sum(CalYear2,ord(CalYear2)$(CalYear2.val= CURCALYR)) ;
* Defining Discount as a macro allows the interest rate parameter (RateParam) to be of any form or dimension, e.g. rate(t), TestRate(process)
* Discount Rate
$macro Discount(RateParam)   (1 + RateParam) ** (-YearIndex(CalYears))

* NPV Average
$macro npv1(costtable,RateParam)        sum(YearPeriodMap(ModelYears(CalYears),periods), costtable  * Discount(RateParam) )
$macro npv2(costtable,RateParam)        sum(YearPeriodMap(ModelYears(CalYears),periods), costtable * Discount(RateParam)) / sum(YearPeriodMap(ModelYears(CalYears),periods), Discount(RateParam))
$macro npv3(costtable,RateParam)  sum(period2$(ord(period2)>=ord(periods)),sum(YearPeriodMap(ModelYears(CalYears),period2), costtable * Discount(RateParam)))

* Calculations using NPV1 and NPV2
FuelPriceByPeriod(Fuels,CenDivOpt,periods) = npv1(FuelPrice(Fuels,CenDivOpt,CalYears),EquityRate);
AdjustedFuelPriceByPeriod(Fuels,ProdActiveOptTechs,CenDivOpt,periods) = npv1(AdjustedFuelPricebyTech(Fuels,ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
TotalH2Demand(CenDivOpt,SeasonOpt,periods) = npv2(TotalH2MarketDemand(CenDivOpt,SeasonOpt,CalYears),EquityRate);
TotalH2Demand(CenDivOpt,SeasonOpt,PlanningPeriodSecond) = TotalH2Demand(CenDivOpt,SeasonOpt,PlanningPeriodSecond) * (1.0 + ProductionCapacityReserve);
ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,periods) = npv2(TotalProductionCapacity(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
CO2CaptureQty45QCredit(ProdActiveOptTechs,CenDivOpt,periods) = npv2(CO2CaptureQty45QCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
CapacityProductionTaxCredit(ProdActiveOptTechs,CenDivOpt,periods) = npv2(CapacityProductionTaxCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
ElectricityGenerationNuclear(CenDivOpt,periods) = npv2(ElectricityGenerationNuclearByYear(CenDivOpt,CalYears),EquityRate);
ElectricityGenerationRenewable(CenDivOpt,periods) = npv2(ElectricityGenerationRenewableByYear(CenDivOpt,CalYears),EquityRate);
TransportCapacityLimit(CenDivOpt,CenDivOpt2,periods)$(Census_Division_Links(CenDivOpt,CenDivOpt2)) = npv2(TotalTransportCapacity(CenDivOpt,CenDivOpt2,CalYears),EquityRate);
StorageCapacityLimit(StorageOptTechs,CenDivOpt,periods) = npv2(TotalStorageCapacity(StorageOptTechs,CenDivOpt,CalYears),EquityRate);

* Calculations using NPV3
ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,periods) = npv3(ProductionUnplannedCapacityCostByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
* Apply learning to unplanned capacity built so far
ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,periods)$(sum(CurrentOptYear,TotalProductionCapacityMultiple(ProdActiveOptTechs,CenDivOpt,CurrentOptYear)) > 0)
         = ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,periods) *
 ((1 - ProdLearningAlphaPerTech(ProdActiveOptTechs)) + ProdLearningAlphaPerTech(ProdActiveOptTechs) *
 rpower(sum(CurrentOptYear,TotalProductionCapacityMultiple(ProdActiveOptTechs,CenDivOpt,CurrentOptYear)),
         ProdLearningBetaPerTech(ProdActiveOptTechs)));

* NPV of transportation capital cost
TransportUnplannedCapacityCost(CenDivOpt,CenDivOpt2,periods)$(Census_Division_Links(CenDivOpt,CenDivOpt2)) =
     npv3(TransportUnplannedCapacityCostByYear(CenDivOpt,CenDivOpt2,CalYears),EquityRate) ;
* Reset NPV transport capital cost within region
TransportUnplannedCapacityCost(CenDivOpt,CenDivOpt2,periods)$(CenDivOpt.val=CenDivOpt2.val) = 0.001;

*NPV of storage capital cost
StorageUnplannedCapacityCost(StorageOptTechs,CenDivOpt2,periods) = npv3(StorageUnplannedCapacityCostByYear(StorageOptTechs,CenDivOpt2,CalYears),EquityRate) ;


ProductionFixedO_MCost(ProdActiveOptTechs,CenDivOpt,periods) = npv1(ProductionFixedO_MCostByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
ProductionVariableO_MCost(ProdActiveOptTechs,CenDivOpt,periods) = npv1(ProductionVariableO_MCostByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,periods) = npv1(Section45QSalineCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
Section45QEORCredit(ProdActiveOptTechs,CenDivOpt,periods) = npv1(Section45QEORCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods) = npv1(ProductionTaxCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
ProductionTaxCreditActual(ProdActiveOptTechs,CenDivOpt,periods) = ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods) ;
InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,periods) = npv1(InvestmentTaxCreditByYear(ProdActiveOptTechs,CenDivOpt,CalYears),EquityRate);
* Calculate 45Q credits per H2 quantity for comparison
Section45QSalineCreditH2(ProdActiveOptTechs,CenDivOpt,periods) = Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,periods) *
     ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) / 1000;
Section45QEORCreditH2(ProdActiveOptTechs,CenDivOpt,periods) = Section45QEORCredit(ProdActiveOptTechs,CenDivOpt,periods) *
     ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) / 1000;
* Calculate the maximum credit to use for any technology
MaxCredit(ProdActiveOptTechs,CenDivOpt,periods) = max(Section45QSalineCreditH2(ProdActiveOptTechs,CenDivOpt,periods), Section45QEORCreditH2(ProdActiveOptTechs,CenDivOpt,periods),
     ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods), InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)) ;
* Reset non-maximum credits to zero
Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,periods)$(MaxCredit(ProdActiveOptTechs,CenDivOpt,periods) >
     Section45QSalineCreditH2(ProdActiveOptTechs,CenDivOpt,periods)) = 0;
Section45QEORCredit(ProdActiveOptTechs,CenDivOpt,periods)$(MaxCredit(ProdActiveOptTechs,CenDivOpt,periods) >
     Section45QEORCreditH2(ProdActiveOptTechs,CenDivOpt,periods)) = 0;
ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods)$(MaxCredit(ProdActiveOptTechs,CenDivOpt,periods) >
     ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods)) = 0;
InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)$(MaxCredit(ProdActiveOptTechs,CenDivOpt,periods) >
     InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)) = 0;

SeasonStorageMap(SeasonOpt,SeasonOpt)=0;

* Limit Unplanned production capacity
ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird,StepOne) =
   max(200, ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird) *
   Production_Step_Size_Period(PlanningPeriodSecondThird,StepOne));

ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird,Steps) =
   max(sum(StepOne,ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird,StepOne) *
   Production_Step_Size_Period(PlanningPeriodSecondThird,Steps) / Production_Step_Size_Period(PlanningPeriodSecondThird,StepOne)),
   ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird) *
   Production_Step_Size_Period(PlanningPeriodSecondThird,Steps)) ;

ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond,StepOne) =
   max(100, ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond) *
   Production_Step_Size_Period(PlanningPeriodSecond,StepOne));

ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond,Steps) =
   max(sum(StepOne,ProductionUnplannedCapacityByStep.up(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond,StepOne) *
   Production_Step_Size_Period(PlanningPeriodSecond,Steps) / Production_Step_Size_Period(PlanningPeriodSecond,StepOne)),
   ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond) *
   Production_Step_Size_Period(PlanningPeriodSecond,Steps)) ;

TransportUnplannedCapacityByStep.up(CenDivOpt,CenDivOpt2,PlanningPeriodSecondThird,Steps) =
   TransportCapacityLimit(CenDivOpt,CenDivOpt2,PlanningPeriodSecondThird) * Transportation_Step_Size_Period(PlanningPeriodSecondThird,Steps);

TransportUnplannedCapacityByStep.up(CenDivOpt,CenDivOpt2,PlanningPeriodSecond,Steps) =
   TransportCapacityLimit(CenDivOpt,CenDivOpt2,PlanningPeriodSecond) * Transportation_Step_Size_Period(PlanningPeriodSecond,Steps);

ProductionUnplannedCapacity.fx(h2prodtech,CensusDiv,PlanningPeriodFirst)=0;
ProductionUnplannedCapacityByStep.fx(h2prodtech,CensusDiv,PlanningPeriodFirst,Steps)=0;
TransportUnplannedCapacity.fx(CensusDiv,CenDiv2,PlanningPeriodFirst)=0;
TransportUnplannedCapacityByStep.fx(CensusDiv,CenDiv2,PlanningPeriodFirst,Steps)=0;
StorageUnplannedCapacity.fx(h2stortech,CensusDiv,PlanningPeriodFirst)=0;
RegionalTransport.fx(CensusDiv,CenDiv2,Seasons,periods)$(not Census_Division_Links(CensusDiv,CenDiv2))=0;
TransportUnplannedCapacity.fx(CensusDiv,CenDiv2,periods)$(not Census_Division_Links(CensusDiv,CenDiv2))=0;
TransportUnplannedCapacityByStep.fx(CensusDiv,CenDiv2,periods,Steps)$(not Census_Division_Links(CensusDiv,CenDiv2))=0;

HMM.defPoint = 2;
Solve HMM minimizing TotalCost using lp ;


