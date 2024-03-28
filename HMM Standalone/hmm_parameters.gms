*Declare all parameters before loop


Set
         CurrentOptYear(CalYears)
         NextOptYear(CalYears)
         LastOptYear(CalYears)
         LastCalYear(CalYears)
         ThirdPeriodYears(CalYears)
         YearPeriodMap(GDPYears,periods)                   Map year to Period
         ProdActiveOptTechs(h2prodtech)
         StorageOptTechs(h2stortech)
;

Set
         PlanningPeriodFirst(periods)
         PlanningPeriodSecond(periods)
         PlanningPeriodSecondThird(periods)
         ModelYears(CalYears)
         AvailableCap(capacity)
         PlannedCap(capacity)
;

Parameter
         HorizonYears                       Total number of years in the planning horizon
         TotalFuelEmissionsPerTech(h2prodtech,CalYears)
         AdjustedFuelPricebyTech(Fuels, h2prodtech, CensusDiv, CalYears)
         SlackCost(periods)
         HydrogenPrice(CensusDiv,Seasons,CalYears)
         MarketH2DemandSeasonFraction(Market_Quantity, Seasons)
         MarketH2DemandbySeason(Market_Quantity,CensusDiv,Seasons,CalYears)
         TotalH2MarketDemand(CensusDiv,Seasons,CalYears)
         ProductionCapacityAvailable(prod_tech,CensusDiv,NumYr)
         repProductionUnplannedCapacity(h2prodtech,CensusDiv,CalYears)
         ProductionCapacityPlanned(prod_tech,CensusDiv,NumYr)
         TotalProductionCapacity(h2prodtech,CensusDiv,CalYears)
         TotalProductionCapacityMultiple(h2prodtech,CensusDiv,CalYears)
         p_CO2CaptureQty45QCreditbyYear
         CapacityProductionTaxCreditbyYear
         HeatRateNuclear
         FirstYrProdCapacity(h2prodtech,CensusDiv)           Production Capacity in First Model Year
         ElectricityGenerationNuclearbyYear(CensusDiv,CalYears)
         ElectricityGenerationRenewablebyYear(CensusDiv,CalYears)
         CCS_SALINE_45Q(CalYears)               CCS_SALINE_45Q in model dimensions
         CCS_EOR_45Q(CalYears)                  CCS_EOR_45Q in model dimensions
         TransportationCapacityAvailable(CensusDiv,CensusDiv,NumYr)
         TransportationCapacityPlanned(CensusDiv,CensusDiv,NumYr)
         repTransportationUnplannedCapacity(CensusDiv,CensusDiv,CalYears)
         TotalTransportCapacity(CensusDiv,CensusDiv,CalYears)
         StorageCapacityAvailable(h2stortech,CensusDiv,NumYr)
         StorageCapacityPlanned(h2stortech,CensusDiv,NumYr)
         repStorageUnplannedCapacity(h2stortech,CensusDiv,CalYears)
         TotalStorageCapacity(h2stortech,CensusDiv,CalYears)
         ProductionUnplannedCapacityCostbyYear(h2prodtech,CensusDiv,CalYears)
         ProdRefDeflator(h2prodtech) GDP Deflator at the ProdReferenceYear per prodtech (intermediate result)
         ProductionFixedO_MCostbyYear(h2prodtech,CensusDiv,CalYears)
         ProdProcessCO2CapturedPerTech(h2prodtech)
         ProductionVariableO_MCostbyYear(h2prodtech,CensusDiv,CalYears)
         TransportUnplannedCapacityCostbyYear(CensusDiv,CensusDiv,CalYears)
         StorageUnplannedCapacityCostbyYear(h2stortech,CensusDiv,CalYears)
         CO2CaptureQty45QCreditbyYear(h2prodtech,CensusDiv,CalYears)
         CapacityProductionTaxCreditbyYear(h2prodtech,CensusDiv,CalYears)
         CapacityInvestmentTaxCreditbyYear(h2prodtech,CensusDiv,CalYears)
         Section45QSalineCreditbyYear(h2prodtech,CensusDiv,CalYears)
         Section45QEORCreditbyYear(h2prodtech,CensusDiv,CalYears)
         ProductionTaxCreditbyTech(prod_tech,NumYr)
         ProductionTaxCreditbyYear(h2prodtech,CensusDiv,CalYears)
         InvestmentTaxCreditbyTech(prod_tech,NumYr)
         InvestmentTaxCreditbyYear(h2prodtech,CensusDiv,CalYears)
         CO2CaptureSaline45QCreditbyYear(h2prodtech,CensusDiv,CalYears)
         CO2CaptureEOR45QCreditbyYear(h2prodtech,CensusDiv,CalYears)
         Section45VCreditbyYear(h2prodtech,CensusDiv,CalYears)
;

alias(CensusDiv,CenDiv2);
alias(CenDivOpt,CenDivOpt2);
alias(MNUMCR,MNUMCR2);
scalar ReadLastYearResult;

* Calculations of net present value using macros NPV1,NPV2, NPV3
Parameter
         YearIndex(GDPYears)               Ordinal index of t in the Model years
         FuelPriceByPeriod(Fuels,CensusDiv,periods)
         AdjustedFuelPriceByPeriod(Fuels,h2prodtech,CensusDiv,periods)
         TotalH2Demand(CensusDiv,Seasons,periods)
         ProdCapacityLimit(h2prodtech,CensusDiv,periods)
         CO2CaptureQty45QCredit(h2prodtech,CensusDiv,periods)
         CapacityProductionTaxCredit(h2prodtech,CensusDiv,periods)
         ElectricityGenerationNuclear(CensusDiv,periods)
         ElectricityGenerationRenewable(CensusDiv,periods)
         TransportCapacityLimit(CensusDiv,CensusDiv,periods)
         StorageCapacityLimit(h2stortech,CensusDiv,periods)
         ProductionUnplannedCapacityCost(h2prodtech,CensusDiv,periods)
         ProductionFixedO_MCost(h2prodtech,CensusDiv,periods)
         ProductionVariableO_MCost(h2prodtech,CensusDiv,periods)
         TransportUnplannedCapacityCost(CensusDiv,CensusDiv,periods)
         StorageUnplannedCapacityCost(h2stortech,CensusDiv,periods)
         Section45QSalineCredit(h2prodtech,CensusDiv,periods)
         Section45QSalineCreditH2(h2prodtech,CensusDiv,periods)
         Section45QEORCredit(h2prodtech,CensusDiv,periods)
         Section45QEORCreditH2(h2prodtech,CensusDiv,periods)
         ProductionTaxCreditUsed(h2prodtech,CensusDiv,periods)
         ProductionTaxCreditActual(h2prodtech,CensusDiv,periods)
         InvestmentTaxCredit(h2prodtech,CensusDiv,periods)
         MaxCredit(h2prodtech,CensusDiv,periods)
;

alias(CalYears,CalYear2);
alias(periods,period2);

Variables
         TotalCost
         FuelConsumption(Fuels,CensusDiv,periods)
         CO2Emissions(h2prodtech,CensusDiv,Seasons,periods)
         CO2EmissionstoCapture(h2prodtech,CensusDiv,Seasons,periods)
         CO2Capture45QCredit(h2prodtech,CensusDiv,Seasons,periods)

Positive Variables
         ProductionOperate(h2prodtech,CensusDiv,Seasons,periods)
         DemandSlack(CensusDiv,Seasons,periods)
         ProductionUnplannedCapacity(h2prodtech,CensusDiv,periods)
         ProductionUnplannedCapacityByStep(h2prodtech,CensusDiv,periods,Steps)
         TotalProduction(CensusDiv,Seasons,periods)
         ProductionTaxCredit(h2prodtech,CensusDiv,periods)
         RegionalTransport(CensusDiv,CensusDiv,Seasons,periods)
         TransportUnplannedCapacity(CensusDiv,CensusDiv,periods)
         TransportUnplannedCapacityByStep(CensusDiv,CensusDiv,periods,Steps)
         StorageUnplannedCapacity(h2stortech,CensusDiv,periods)
         SeasonalStorageLevel(h2stortech,CensusDiv,Seasons,periods)
         SeasonalStorageChange(h2stortech,CensusDiv,Seasons,periods)
         SeasonalTransfer(h2stortech,CensusDiv,Seasons,Seasons,periods)
         CO2CapturetoSaline(h2prodtech,CensusDiv,Seasons,periods)
         CO2CapturetoSaline45Q(h2prodtech,CensusDiv,Seasons,periods)
         CO2CapturetoEOR(h2prodtech,CensusDiv,Seasons,periods)
         CO2CapturetoEOR45Q(h2prodtech,CensusDiv,Seasons,periods)

;


alias(SeasonOpt,SeasonOpt2);
alias(periods,periods2);

Equations
                 OBJ                                  Objective function
                 SupplyNodes(CensusDiv,Seasons,periods)
                 DemandNodes(CensusDiv,Seasons,periods)
                 ProdOperates(h2prodtech,CensusDiv,Seasons,periods)
                 ProdUnplannedCapyByStep(h2prodtech,CensusDiv,periods)
                 ProdUnplannedCapyLimit(CensusDiv)
                 TotalProd(CensusDiv,Seasons,periods)
                 NuclearGenerationLimit(CensusDiv,periods)
                 RenewableGenerationLimit(CensusDiv,periods)
                 ProductionWithPTCLimit(h2prodtech,CensusDiv,periods)
                 MaxProdWithPTCLimit(h2prodtech,CensusDiv,periods)
                 MaxRegionalTransport(CensusDiv,CensusDiv,Seasons,periods)
                 TotalTransportUnplanned(CensusDiv,CensusDiv,periods)
                 SeasonalTransferLimit(h2stortech,CensusDiv,Seasons,Seasons,periods)
                 MaxStorageCapacity(h2stortech,CensusDiv,Seasons,periods)
                 SeasonalStorageBalance(h2stortech,CensusDiv,Seasons,periods)
                 MaxSeasonalChange(h2stortech,CensusDiv,Seasons,periods)
                 TotalFuelConsumption(Fuels,CensusDiv,periods)
                 TotalCO2Emissions(h2prodtech,CensusDiv,Seasons,periods)
                 TotalCO2Captured(h2prodtech,CensusDiv,Seasons,periods)
                 CO2CapturedToSalineAndEOR(h2prodtech,CensusDiv,Seasons,periods)
                 CO2CapturedToSalineWith45Q(h2prodtech,CensusDiv,Seasons,periods)
                 CO2CapturedToEORwith45Q(h2prodtech,CensusDiv,Seasons,periods)
                 MaxCO2CapturedWith45Q(h2prodtech,CensusDiv,periods)
                 CO2Captured45qSalineEOR(h2prodtech,CensusDiv,Seasons,periods)
;

OBJ..                TotalCost         =E=
   sum((ProdActiveOptTechs,CenDivOpt,periods),
* Production Fuel and Variable Costs
   sum(SeasonOpt,ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)) *
   (sum(Fuels, AdjustedFuelPricebyPeriod(Fuels,ProdActiveOptTechs,CenDivOpt,periods) *
   ProdFuelConsumptionPerTech(Fuels,ProdActiveOptTechs)) +
   ProductionVariableO_MCost(ProdActiveOptTechs,CenDivOpt,periods) +
   ProductionFixedO_MCost(ProdActiveOptTechs, CenDivOpt, periods)) -
   ProductionTaxCredit(ProdActiveOptTechs,CenDivOpt,periods) +
* Production Capacity Costs with steps
   sum(Steps, ProductionUnplannedCapacityByStep(ProdActiveOptTechs,CenDivOpt,periods,Steps) *
   (ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,periods) -
   InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)) * Production_Step_Cost_Fraction(Steps)) -
* Section 45Q Credits
   sum(SeasonOpt, CO2CapturetoSaline45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)) *
   Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,periods) -
   sum(SeasonOpt, CO2CapturetoEOR45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)) *
   Section45QEORCredit(ProdActiveOptTechs,CenDivOpt,periods)) +
   sum((CenDivOpt, SeasonOpt, periods), SlackCost(periods) * DemandSlack(CenDivOpt,SeasonOpt,periods)) +
* Transportation Variable Costs
   sum((CenDivOpt,periods), sum(CenDivOpt2, sum(SeasonOpt, RegionalTransport(CenDivOpt,CenDivOpt2,SeasonOpt,periods) *
   sum(Fuels, FuelPricebyPeriod(Fuels,CenDivOpt,periods) * PipeCompressorPowerConsumption(Fuels))) +

* Transportation Capital Costs with steps
   sum(Steps, TransportUnplannedCapacityByStep(CenDivOpt,CenDivOpt2,periods,Steps) *
   TransportUnplannedCapacityCost(CenDivOpt,CenDivOpt2,periods) * Transportation_Step_Cost_Fraction(Steps)))) +
* Storage Variable Cost
   sum((StorageOptTechs,CenDivOpt,periods),
   sum((SeasonOpt,SeasonOpt2), SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods) *
   sum(Fuels, FuelPricebyPeriod(Fuels,CenDivOpt,periods) * StorageCompressorPowerConsumption(Fuels))) +
* Storage Capital Cost
   StorageUnplannedCapacity(StorageOptTechs,CenDivOpt,periods) * StorageUnplannedCapacityCost(StorageOptTechs,CenDivOpt,periods))
;

* Constraints

SupplyNodes(CenDivOpt,SeasonOpt,periods)..
         TotalProduction(CenDivOpt,SeasonOpt,periods) -
         sum(CenDivOpt2, RegionalTransport(CenDivOpt,CenDivOpt2,SeasonOpt,periods)) -
         sum((StorageOptTechs,SeasonOpt2), SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods))
          =E= 0 ;

DemandNodes(CenDivOpt,SeasonOpt,periods)..
         sum(CenDivOpt2, RegionalTransport(CenDivOpt2,CenDivOpt,SeasonOpt,periods)) +
         sum((StorageOptTechs,SeasonOpt2), SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt2,SeasonOpt,periods)) +
         DemandSlack(CenDivOpt,SeasonOpt,periods)
         =E= TotalH2Demand(CenDivOpt,SeasonOpt,periods) ;

ProdOperates(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =L= (ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,periods) +
         sum(periods2$(ord(periods2) <= ord(periods)),
         ProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,periods2))) *
         Season_Fraction(SeasonOpt) * ProdCapacityFactorPerTech(ProdActiveOptTechs) ;

ProdUnplannedCapyByStep(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird)..
         ProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird)
         =E= sum(Steps, ProductionUnplannedCapacityByStep(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecondThird,Steps)) ;

ProdUnplannedCapyLimit(CenDivOpt)..
         sum((ProdActiveOptTechs,PlanningPeriodSecond), ProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))
         =L= sum((ProdActiveOptTechs,PlanningPeriodFirst), ProdCapacityLimit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodFirst)) *
         ProductionGrowthLimit ;

TotalProd(CenDivOpt,SeasonOpt,periods)..
         sum(ProdActiveOptTechs,ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods))
         =E= TotalProduction(CenDivOpt,SeasonOpt,periods) ;

NuclearGenerationLimit(CenDivOpt,PlanningPeriodSecondThird)..
         sum(ProdNucTechs,ProductionUnplannedCapacity(ProdNucTechs,CenDivOpt,PlanningPeriodSecondThird) *
         ProdFuelConsumptionPerTech('Electricity',ProdNucTechs)) / 1
         =L= ElectricityGenerationNuclear(CenDivOpt,PlanningPeriodSecondThird) * NuclearShareLimit ;

RenewableGenerationLimit(CenDivOpt,PlanningPeriodSecondThird)..
         sum(ProdRenTechs, ProductionUnplannedCapacity(ProdRenTechs,CenDivOpt,PlanningPeriodSecondThird) *
         ProdFuelConsumptionPerTech('Electricity',ProdRenTechs))/1
         =L= ElectricityGenerationRenewable(CenDivOpt,PlanningPeriodSecondThird) * RenewablesShareLimit ;

ProductionWithPTCLimit(ProdActiveOptTechs,CenDivOpt,periods)..
         ProductionTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)
         =L= sum(SeasonOpt, ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)) *
         ProductionTaxCreditActual(ProdActiveOptTechs,CenDivOpt,periods) ;

MaxProdWithPTCLimit(ProdActiveOptTechs,CenDivOpt,periods)..
         ProductionTaxCredit(ProdActiveOptTechs,CenDivOpt,periods)
         =L= CapacityProductionTaxCredit(ProdActiveOptTechs,CenDivOpt,periods) *
         ProductionTaxCreditActual(ProdActiveOptTechs,CenDivOpt,periods) +
         sum(periods2$(ord(periods2) <= ord(periods)),
         ProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,periods2)) *
         ProdCapacityFactorPerTech(ProdActiveOptTechs) * ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,periods) ;

MaxRegionalTransport(CenDivOpt,CenDivOpt2,SeasonOpt,periods)$Census_Division_Links(CenDivOpt,CenDivOpt2)..
         RegionalTransport(CenDivOpt,CenDivOpt2,SeasonOpt,periods)
         =L= (TransportCapacityLimit(CenDivOpt,CenDivOpt2,periods) +
         sum(periods2$(ord(periods2) <= ord(periods)),
         TransportUnplannedCapacity(CenDivOpt,CenDivOpt2,periods2))) * Season_Fraction(SeasonOpt) ;

TotalTransportUnplanned(CenDivOpt,CenDivOpt2,PlanningPeriodSecondThird)..
         TransportUnplannedCapacity(CenDivOpt,CenDivOpt2,PlanningPeriodSecondThird)
         =E= sum(Steps, TransportUnplannedCapacityByStep(CenDivOpt,CenDivOpt2,PlanningPeriodSecondThird,Steps)) ;

SeasonalTransferLimit(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods)..
         SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods)
         =L= SeasonStorageMap(SeasonOpt,SeasonOpt2) ;

MaxStorageCapacity(StorageOptTechs,CenDivOpt,SeasonOpt,periods)..
         SeasonalStorageLevel(StorageOptTechs,CenDivOpt,SeasonOpt,periods)
         =L= StorageCapacityLimit(StorageOptTechs,CenDivOpt,periods) +
         sum(periods2$(ord(periods2) <= ord(periods)),
         StorageUnplannedCapacity(StorageOptTechs,CenDivOpt,periods2)) +
         SeasonalStorageChange(StorageOptTechs,CenDivOpt,SeasonOpt,periods) ;

SeasonalStorageBalance(StorageOptTechs,CenDivOpt,SeasonOpt,periods)..
         SeasonalStorageChange(StorageOptTechs,CenDivOpt,SeasonOpt,periods)
         =E= sum(SeasonOpt2, SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt2,SeasonOpt,periods)) -
             sum(SeasonOpt2, SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods)) ;

MaxSeasonalChange(StorageOptTechs,CenDivOpt,SeasonOpt,periods)..
         SeasonalStorageChange(StorageOptTechs,CenDivOpt,SeasonOpt,periods)
         =L= (StorageCapacityLimit(StorageOptTechs,CenDivOpt,periods) +
         sum(periods2$(ord(periods2) <= ord(periods)),
         StorageUnplannedCapacity(StorageOptTechs,CenDivOpt,periods2))) * StorageExpansionFraction ;

TotalFuelConsumption(Fuels,CenDivOpt,periods)..
         FuelConsumption(Fuels,CenDivOpt,periods)
         =G= sum((ProdActiveOptTechs,SeasonOpt),
         ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) * ProdFuelConsumptionPerTech(Fuels,ProdActiveOptTechs)) +
         sum((CenDivOpt2,SeasonOpt), RegionalTransport(CenDivOpt,CenDivOpt2,SeasonOpt,periods)) * PipeCompressorPowerConsumption(Fuels) +
         sum((StorageOptTechs,SeasonOpt,SeasonOpt2), SeasonalTransfer(StorageOptTechs,CenDivOpt,SeasonOpt,SeasonOpt2,periods) *
         StorageCompressorPowerConsumption(Fuels)) ;

TotalCO2Emissions(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2Emissions(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =E= ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) *
         ProdProcessCO2PerTech(ProdActiveOptTechs) ;

TotalCO2Captured(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2EmissionstoCapture(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =E= ProductionOperate(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) *
         ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) / 1000 ;

CO2CapturedToSalineAndEOR(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2EmissionstoCapture(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =E= CO2CaptureToSaline(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) +
         CO2CaptureToEOR(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods);

CO2CapturedToSalineWith45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2CaptureToSaline(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =G= CO2CaptureToSaline45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) ;

CO2CapturedToEORWith45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2CaptureToEOR(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =G= CO2CaptureToEOR45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) ;

MaxCO2CapturedWith45Q(ProdActiveOptTechs,CenDivOpt,periods)..
         CO2CaptureQty45QCredit(ProdActiveOptTechs,CenDivOpt,periods)
         =G= sum(SeasonOpt, CO2Capture45QCredit(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)) ;

CO2Captured45qSalineEOR(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)..
         CO2Capture45QCredit(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods)
         =E= CO2CapturetoSaline45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) +
         CO2CapturetoEOR45Q(ProdActiveOptTechs,CenDivOpt,SeasonOpt,periods) ;

Model HMM  / all / ;

Set
         Section45QYrs(CalYears)
         Section45VYrs(CalYears)
;

Parameter
         ProductionCostRatio(h2prodtech,CensusDiv)
         SumProductionMarketShareAlpha(CensusDiv)
         SumProductionUnplannedCapacity(CensusDiv)
         ProductionMarketShare(h2prodtech,CensusDiv)
         AdjProductionUnplannedCapacity(h2prodtech,CensusDiv)
         PHMM(Market_Price,CensusDiv,CalYears)
         INVCST(h2prodtech,CensusDiv,CalYears)
         HMPRODSEQ(CombustionFuels,CensusDiv,CalYears)
         CO2CAPFUEL(CombustionFuels,CensusDiv,CalYears)
         H2Fuel(Fuels,CensusDiv,CalYears)
         HMGSPRD(CalYears,CensusDiv)
         HMCLPRD(CalYears,CensusDiv)
         HMELPRD(CalYears,CensusDiv)
         HMBIPRD(CalYears,CensusDiv)
         CO2CaptureQtybyTech(h2prodtech,CensusDiv,CalYears)
         CO2CaptureSalinebyTech(h2prodtech,CensusDiv,CalYears)
         CO2CaptureEORbyTech(h2prodtech,CensusDiv,CalYears)
         QCLHM(CensusDiv,CalYears)
         QNGHM(CensusDiv,CalYears)
         QBMHM(CensusDiv,CalYears)
         QELHM(CensusDiv,CalYears)
         ProductionUnplannedCapacityPerYearAndIter(h2prodtech,MNUMCR,CalYears)
         TransportUnplannedCapacityPerYearAndIter(MNUMCR,MNUMCR,CalYears)
         StorageUnplannedCapacityPerYearAndIter(h2stortech,MNUMCR,CalYears)
         ProductionOperatePerYearAndIter(h2prodtech,MNUMCR,CalYears)
         RegionalTransportPerYearAndIter(MNUMCR,MNUMCR,CalYears)
         HydrogenProductionOpCost(h2prodtech,MNUMCR,CalYears)
         HydrogenFixedO_MCost(h2prodtech,MNUMCR,CalYears)
         HydrogenProductionOpCredit(h2prodtech,MNUMCR,CalYears)
         HydrogenProductionCapCost(h2prodtech,MNUMCR,CalYears)
         HydrogenProductionInvstCredit(h2prodtech,MNUMCR,CalYears)
         CO2CaptureCredit(h2prodtech,MNUMCR,CalYears)
         DemandSlackPerYearAndIter(MNUMCR,Seasons,CalYears)
         SolvedYearsAndCosts(CalYears)

;

Parameter
         HMMBLK_PHMM(Market_Price,MNUMCR,CalYears)
         HMMBLK_HMPRODSEQ(CombustionFuels,MNUMCR,CalYears)
         HMMBLK_CO2CAPFUEL(CombustionFuels,MNUMCR,CalYears)
         HMMBLK_H2Fuel(Fuels,MNUMCR,CalYears)
         HMMBLK_HMGSPRD(MNUMCR,CalYears)
         HMMBLK_HMCLPRD(MNUMCR,CalYears)
         HMMBLK_HMELPRD(MNUMCR,CalYears)
         HMMBLK_HMBIPRD(MNUMCR,CalYears)
         QBLK_QELHM(MNUMCR,CalYears)
;

