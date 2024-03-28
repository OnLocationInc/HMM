
* BEGIN REPORT SECTION


  if((ReadLastYearResult eq 1),
loop(LastOptYear(CalYears),
    put_utility 'gdxin' / 'HMM_'LastOptYear.te(LastOptYear)'.gdx' ;
);
         execute_load ProductionUnplannedCapacityPerYearAndIter TransportUnplannedCapacityPerYearAndIter
                StorageUnplannedCapacityPerYearAndIter ProductionOperatePerYearAndIter
                RegionalTransportPerYearAndIter DemandSlackPerYearAndIter SolvedYearsAndCosts;
    execute_load PHMM INVCST HMPRODSEQ CO2CAPFUEL H2Fuel HMGSPRD HMCLPRD HMELPRD
         HMBIPRD QCLHM QNGHM QBMHM QELHM HydrogenProductionOpCost HydrogenFixedO_MCost
         HydrogenProductionOpCredit HydrogenProductionCapCost HydrogenProductionInvstCredit
         CO2CaptureCredit CO2CaptureQtybyTech CO2CaptureSalinebyTech CO2CaptureEORbyTech;
  );

Section45QYrs(CalYears) = no;
Section45VYrs(CalYears) = no;
Section45QYrs(CalYears)$(CalYears.val > CURCALYR and CalYears.val <=
   CURCALYR + I_45Q_DURATION and CURCALYR <= I_45Q_LYR_NEW) = yes;
Section45VYrs(CalYears)$(CalYears.val > CURCALYR and CalYears.val <=
   CURCALYR + I_45V_DURATION and CURCALYR <= I_45V_LYR_NEW) = yes;

if (MarketShareON=1 ,
* Calculate        Production Cost Ratio     ! Calculate ratio of deviation from best cost to total cost
ProductionCostRatio(ProdActiveOptTechs,CenDivOpt)
   = 1 - (sum((PlanningPeriodSecond,StepOne),ProductionUnplannedCapacityByStep.m(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond,StepOne)))
    / (sum(PlanningPeriodSecond,ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond)
    + sum(Fuels,AdjustedFuelPricebyPeriod(Fuels,ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond)
    * ProdFuelConsumptionPerTech(Fuels,ProdActiveOptTechs)) + ProductionVariableO_MCost(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond)
    + ProductionFixedO_MCost(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond) - MaxCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond)));
ProductionCostRatio(ProdActiveOptTechs,CenDivOpt)$(sum((PlanningPeriodSecond,StepOne),ProductionUnplannedCapacityByStep.m(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond,StepOne)) lt 0) = 1;

* Calculate        Market Share                                        ! Calculate Market share
SumProductionMarketShareAlpha(CenDivOpt) = sum(ProdActiveOptTechs$(ProductionCostRatio(ProdActiveOptTechs,CenDivOpt) > MarketShareCutoff),
   rpower(ProductionCostRatio(ProdActiveOptTechs,CenDivOpt),MarketShareAlpha));

ProductionMarketShare(h2prodtech,CensusDiv) = 0;
ProductionMarketShare(ProdActiveOptTechs,CenDivOpt)$(ProductionCostRatio(ProdActiveOptTechs,CenDivOpt) > MarketShareCutoff
   and SumProductionMarketShareAlpha(CenDivOpt) > 0)
   = rpower(ProductionCostRatio(ProdActiveOptTechs,CenDivOpt),MarketShareAlpha) / SumProductionMarketShareAlpha(CenDivOpt);

* Calculate        Unplanned builds                                        ! Recalculating unplanned builds
SumProductionUnplannedCapacity(CenDivOpt) = sum((ProdActiveOptTechs,PlanningPeriodSecond)$(ProductionMarketShare(ProdActiveOptTechs,CenDivOpt) > 0),
   ProductionUnplannedCapacity.l(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond));

AdjProductionUnplannedCapacity(h2prodtech,CensusDiv) = 0;
AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt)$(ProductionMarketShare(ProdActiveOptTechs,CenDivOpt) > 0)
   = SumProductionUnplannedCapacity(CenDivOpt) * ProductionMarketShare(ProdActiveOptTechs,CenDivOpt);
) ;

* Calculate        Hydrogen base price (87$)  ! keep only current year    ep_PlanningPeriodFirst = StringToElement(PlanningPeriodFirst,"Current Year");
HydrogenPrice(CenDivOpt,SeasonOpt,CurrentOptYear) = sum(YearPeriodMap(CurrentOptYear,PlanningPeriodFirst),
   DemandNodes.m(CenDivOpt,SeasonOpt,PlanningPeriodFirst)) / GDP_Deflator(CurrentOptYear);

* Check        Slack Price   ! set all to slack cost if any is a slack   Adjust        Hydrogen base price (87$)
if (sum((CenDivOpt,SeasonOpt,PlanningPeriodFirst),DemandSlack.l(CenDivOpt,SeasonOpt,PlanningPeriodFirst)) > 0.0,
   HydrogenPrice(CenDivOpt,SeasonOpt,CurrentOptYear) = sum(YearPeriodMap(CurrentOptYear,PlanningPeriodFirst),SlackCost(PlanningPeriodFirst)) / GDP_Deflator(CurrentOptYear);
);

PHMM(Market_Price,CenDivOpt,CurrentOptYear)
*   = (smax(SeasonOpt,HydrogenPrice(CenDivOpt,SeasonOpt,CurrentOptYear)) + HMMMARKUP(Market_Price)) / HydrogenHHV * 1e6;
   = (smax(SeasonOpt,HydrogenPrice(CenDivOpt,SeasonOpt,CurrentOptYear)) + HMMMARKUP(Market_Price)) ;

* Set        Minimum price                                        !set a minimum price
PHMM(Market_Price,CenDivOpt,CurrentOptYear)
*        = max(PHMM(Market_Price,CenDivOpt,CurrentOptYear), MinPrice);
        = max(PHMM(Market_Price,CenDivOpt,CurrentOptYear), MinPrice * HydrogenHHV / 1e6);

* Calculate  Weighted average price by sector                                        ! Product price and quantity
*                                                        ! need for sum to region 11
QHMM(Market_Quantity,CenDivNatl,CurrentOptYear)=
   sum(CenDivOpt,QHMM(Market_Quantity,CenDivOpt,CurrentOptYear));

* first set all prices to average of sectors,in case some quantities are all zero.
PHMM(Market_Price,CenDivNatl,CurrentOptYear)=
   sum(CenDivOpt,PHMM(Market_Price,CenDivOpt,CurrentOptYear))/card(Market_Price) ;

*                                                       ! then derive quantity weights
PHMM(Market_Price,CenDivNatl,CurrentOptYear)$(sum(Market_P_Q(Market_Price,Market_Quantity),QHMM(Market_Quantity,CenDivNatl,CurrentOptYear)) > 0) =
   sum(CenDivOpt,PHMM(Market_Price,CenDivOpt,CurrentOptYear)
   * sum(Market_P_Q(Market_Price,Market_Quantity),QHMM(Market_Quantity,CenDivOpt,CurrentOptYear)));

*    ! divide by quantity for quantity weighted average when nonzero
PHMM(Market_Price,CenDivNatl,CurrentOptYear)$(sum(Market_P_Q(Market_Price,Market_Quantity),QHMM(Market_Quantity,CenDivNatl,CurrentOptYear)) > 0) =
   PHMM(Market_Price,CenDivNatl,CurrentOptYear) /
   sum(Market_P_Q(Market_Price,Market_Quantity), QHMM(Market_Quantity,CenDivNatl,CurrentOptYear));

*Reset  Production by sequestered technologies  ! zero out national total
HMPRODSEQ(CombustionFuels,CenDivNatl,CurrentOptYear) = 0;

*  Calculate        Production by sequestered technologies             Line 89
HMPRODSEQ('Natural Gas',CenDivOpt,CurrentOptYear) =
   sum((ProdNGSeqTechs,SeasonOpt,PlanningPeriodFirst),
   ProductionOperate.l(ProdNGSeqTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));

HMPRODSEQ('Coal',CenDivOpt,CurrentOptYear) =
   sum((ProdCLSeqTechs,SeasonOpt,PlanningPeriodFirst),
   ProductionOperate.l(ProdCLSeqTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));

HMPRODSEQ('Biomass',CenDivOpt,CurrentOptYear) =
   sum((ProdBMSeqTechs,SeasonOpt,PlanningPeriodFirst),
   ProductionOperate.l(ProdBMSeqTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));

* national total
HMPRODSEQ(CombustionFuels,CenDivNatl,CurrentOptYear) =
   sum(CenDivOpt,HMPRODSEQ(CombustionFuels,CenDivOpt,CurrentOptYear));

*  Calculate        CO2 captured by Fuels  line 111
CO2CAPFUEL('Coal',CenDivOpt,CurrentOptYear) =
   sum((ProdActiveOptTechs,SeasonOpt,PlanningPeriodFirst)$(TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear) > 0),
   (CO2EmissionstoCapture.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst)
   * ProdFuelConsumptionPerTech('Coal',ProdActiveOptTechs)
   * EmissionFactors('Coal',CurrentOptYear))
    /    TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear));

CO2CAPFUEL('Natural Gas',CenDivOpt,CurrentOptYear) =
   sum((ProdActiveOptTechs,SeasonOpt,PlanningPeriodFirst)$(TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear) > 0),
   (CO2EmissionstoCapture.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst)
   * ProdFuelConsumptionPerTech('Natural Gas',ProdActiveOptTechs)
   * EmissionFactors('Natural Gas',CurrentOptYear))
    /    TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear));

CO2CAPFUEL('Biomass',CenDivOpt,CurrentOptYear) =
   sum((ProdActiveOptTechs,SeasonOpt,PlanningPeriodFirst)$(TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear) > 0),
   (CO2EmissionstoCapture.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst)
   * ProdFuelConsumptionPerTech('Biomass',ProdActiveOptTechs)
   * EmissionFactors('Biomass',CurrentOptYear))
    /    TotalFuelEmissionsPerTech(ProdActiveOptTechs,CurrentOptYear));

* national total
CO2CAPFUEL(CombustionFuels,CenDivNatl,CurrentOptYear) =
   sum(CenDivOpt,CO2CAPFUEL(CombustionFuels,CenDivOpt,CurrentOptYear));


* Calculate        Fuels consumption by Technology Line 126
H2Fuel(CombustionFuels,CenDivOpt,CurrentOptYear) =
   sum((ProdActiveOptTechs,SeasonOpt,PlanningPeriodFirst),
   ProductionOperate.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst) *
   ProdFuelConsumptionPerTech(CombustionFuels,ProdActiveOptTechs) );

H2Fuel(CombustionFuels,CenDivNatl,CurrentOptYear) =
   sum(CenDivOpt,H2Fuel(CombustionFuels,CenDivOpt,CurrentOptYear)) ;

* Calculate Production by Primary Fuels used   beginning with NG
HMGSPRD(CurrentOptYear,CenDivOpt) =
   sum((ProdNGTechs,SeasonOpt,PlanningPeriodFirst), ProductionOperate.l(ProdNGTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
HMGSPRD(CurrentOptYear,CenDivNatl) = sum(CenDivOpt,HMGSPRD(CurrentOptYear,CenDivOpt)) ;
* Coal
HMCLPRD(CurrentOptYear,CenDivOpt) =
   sum((ProdCLTechs,SeasonOpt,PlanningPeriodFirst), ProductionOperate.l(ProdCLTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
HMCLPRD(CurrentOptYear,CenDivNatl) = sum(CenDivOpt,HMCLPRD(CurrentOptYear,CenDivOpt)) ;
* Electricity
HMELPRD(CurrentOptYear,CenDivOpt) =
   sum((ProdELTechs,SeasonOpt,PlanningPeriodFirst), ProductionOperate.l(ProdELTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
HMELPRD(CurrentOptYear,CenDivNatl) = sum(CenDivOpt,HMELPRD(CurrentOptYear,CenDivOpt)) ;
*Biomass
HMBIPRD(CurrentOptYear,CenDivOpt) =
   sum((ProdBMTechs,SeasonOpt,PlanningPeriodFirst), ProductionOperate.l(ProdBMTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
HMBIPRD(CurrentOptYear,CenDivNatl) = sum(CenDivOpt,HMBIPRD(CurrentOptYear,CenDivOpt)) ;

* Calculate        Total CO2 captured                                        !CO2 captured
CO2CaptureQtybyTech(ProdActiveOptTechs,CenDivOpt,CurrentOptYear) =
   sum((SeasonOpt,PlanningPeriodFirst), CO2EmissionstoCapture.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
* Captured CO2 to saline
CO2CaptureSalinebyTech(ProdActiveOptTechs,CenDivOpt,CurrentOptYear) =
   sum((SeasonOpt,PlanningPeriodFirst), CO2CapturetoSaline.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));
* Captured CO2 to EOR
CO2CaptureEORbyTech(ProdActiveOptTechs,CenDivOpt,CurrentOptYear) =
   sum((SeasonOpt,PlanningPeriodFirst), CO2CapturetoEOR.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst));

* Calculate        Total CO2 captured eligible for 45Q credit
CO2CaptureQty45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs) = AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt) *
   ProdProcessCO2CapturedPerTech(ProdActiveOptTechs) / 1000 + CO2CaptureQty45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs);

* Calculate    CO2 captured to saline eligible for 45Q credit
CO2CaptureSaline45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs) =
   sum((SeasonOpt,PlanningPeriodSecond), CO2CapturetoSaline45Q.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodSecond)
   $(Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) +
   CO2CaptureSaline45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs);

* Calculate    CO2 captured to EOR eligible for 45Q credit
CO2CaptureEOR45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs) =
   sum((SeasonOpt,PlanningPeriodSecond), CO2CapturetoEOR45Q.l(ProdActiveOptTechs,CenDivOpt,SeasonOpt,PlanningPeriodSecond)
   $(Section45QEORCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) +
   CO2CaptureEOR45QCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45QYrs);

* Calculate    Total capacity eligible for 45V credit
Section45VCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs) = AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt) +
   Section45VCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs);

* Calculate        Total capacity eligible for 45V PTC
CapacityProductionTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs) = AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt)
   $(sum(PlanningPeriodSecond,ProductionTaxCreditUsed(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) +
   CapacityProductionTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs);

CapacityProductionTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs) =
   CapacityProductionTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs) + sum(NumYr_2_CalYr(NextOptYear,NumYr),
   sum(prod_tech$Production_Code(prod_tech,ProdActiveOptTechs), ProductionCapacityPlanned(prod_tech,CenDivOpt,NumYr)));

* Calculate        Total capacity eligible for 45V ITC
CapacityInvestmentTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs) = AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt)
   $(sum(PlanningPeriodSecond,InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) +
   CapacityInvestmentTaxCreditbyYear(ProdActiveOptTechs,CenDivOpt,Section45VYrs);

* Calculate        Total consumption by Fuels
QCLHM(CenDivOpt,CurrentOptYear) =
   sum(PlanningPeriodFirst,FuelConsumption.l('Coal',CenDivOpt,PlanningPeriodFirst));
QCLHM(CenDivNatl,CurrentOptYear) = sum(CenDivOpt,QCLHM(CenDivOpt,CurrentOptYear));

QNGHM(CenDivOpt,CurrentOptYear) =
   sum(PlanningPeriodFirst,FuelConsumption.l('Natural Gas',CenDivOpt,PlanningPeriodFirst));
QNGHM(CenDivNatl,CurrentOptYear) = sum(CenDivOpt,QNGHM(CenDivOpt,CurrentOptYear));

QBMHM(CenDivOpt,CurrentOptYear) =
   sum(PlanningPeriodFirst,FuelConsumption.l('Biomass',CenDivOpt,PlanningPeriodFirst));
QBMHM(CenDivNatl,CurrentOptYear) = sum(CenDivOpt,QBMHM(CenDivOpt,CurrentOptYear));
* Note electricity was in kwhr/kg
QELHM(CenDivOpt,CurrentOptYear) =
   sum(PlanningPeriodFirst,FuelConsumption.l('Electricity',CenDivOpt,PlanningPeriodFirst))/MMBTU_to_KWH;
QELHM(CenDivNatl,CurrentOptYear) = sum(CenDivOpt,QELHM(CenDivOpt,CurrentOptYear));

* Calculate        Production builds by year                !Store Production,transportation storage and ammonia capacity
repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,NextOptYear) = sum(CurrentOptYear,repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,CurrentOptYear))
         + AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt);

repProductionUnplannedCapacity(h2prodtech,CenDivOpt,NextOptYear) =
   repProductionUnplannedCapacity(h2prodtech,CenDivOpt,NextOptYear) +
   sum((prod_tech,NumYr)$(NumYr_2_CalYr(NextOptYear,NumYr) and Production_Code(prod_tech,h2prodtech)),ProductionCapacityPlanned(prod_tech,CenDivOpt,NumYr));

repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,ThirdPeriodYears) =
   sum(CurrentOptYear,repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,CurrentOptYear)) +
   AdjProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt);

repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,ThirdPeriodYears) =
   repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,ThirdPeriodYears) +
   sum((prod_tech,NumYr,NextOptYear)$(NumYr_2_CalYr(NextOptYear,NumYr) and Production_Code(prod_tech,ProdActiveOptTechs)),
         ProductionCapacityPlanned(prod_tech,CenDivOpt,NumYr));

*        Calculate        Transportation builds by year  Line 253
repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,NextOptYear) =
   sum(CurrentOptYear,repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,CurrentOptYear)) +
   sum(PlanningPeriodSecond, TransportUnplannedCapacity.l(CenDivOpt,CenDivOpt2,PlanningPeriodSecond));
*DEFINITIONS OF 2ND, THIRD PERIOD ARE THE SAME, MAY WANT TO CHECK
repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,ThirdPeriodYears) =
   sum(CurrentOptYear,repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,CurrentOptYear)) +
   sum(PlanningPeriodSecond, TransportUnplannedCapacity.l(CenDivOpt,CenDivOpt2,PlanningPeriodSecond));

* Calculate        Storage builds by year
repStorageUnplannedCapacity(h2stortech,CenDivOpt,NextOptYear) =
   sum(CurrentOptYear,repStorageUnplannedCapacity(h2stortech,CenDivOpt,CurrentOptYear)) +
   sum(PlanningPeriodSecond, StorageUnplannedCapacity.l(h2stortech,CenDivOpt,PlanningPeriodSecond));

repStorageUnplannedCapacity(h2stortech,CenDivOpt,ThirdPeriodYears) =
   sum(CurrentOptYear,repStorageUnplannedCapacity(h2stortech,CenDivOpt,CurrentOptYear)) +
   sum(PlanningPeriodSecond, StorageUnplannedCapacity.l(h2stortech,CenDivOpt,PlanningPeriodSecond));

* Calculate        Production builds by year and iteration
ProductionUnplannedCapacityPerYearAndIter(ProdActiveOptTechs,MNUMCR,CurrentOptYear) =
   sum(CensusRegionMap(MNUMCR,CenDivOpt), repProductionUnplannedCapacity(ProdActiveOptTechs,CenDivOpt,CurrentOptYear));
* Calculate        Transportation builds by year and iteration
TransportUnplannedCapacityPerYearAndIter(MNUMCR,MNUMCR2,CurrentOptYear) =
   sum((CenDivOpt,CenDivOpt2)$(CensusRegionMap(MNUMCR,CenDivOpt) and CensusRegionMap(MNUMCR2,CenDivOpt2)),
         repTransportationUnplannedCapacity(CenDivOpt,CenDivOpt2,CurrentOptYear)) ;
*  Calculate        Storage builds by year and iteration
StorageUnplannedCapacityPerYearAndIter(h2stortech,MNUMCR,CurrentOptYear) =
   sum(CensusRegionMap(MNUMCR,CenDivOpt), repStorageUnplannedCapacity(h2stortech,CenDivOpt,CurrentOptYear)) ;
*  Calculate        Production by year and iteration
ProductionOperatePerYearAndIter(ProdActiveTechs,MNUMCR,CurrentOptYear)
         = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum((SeasonOpt,PlanningPeriodFirst),ProductionOperate.l(ProdActiveTechs,CenDivOpt,SeasonOpt,PlanningPeriodFirst)));
* Calculate        Regional transport by year and iteration
RegionalTransportPerYearAndIter(MNUMCR,MNUMCR2,CurrentOptYear)
         = sum((CenDivOpt,CenDivOpt2)$(CensusRegionMap(MNUMCR,CenDivOpt) and CensusRegionMap(MNUMCR2,CenDivOpt2)),
                 sum((SeasonOpt,PlanningPeriodFirst),RegionalTransport.l(CenDivOpt,CenDivOpt2,SeasonOpt,PlanningPeriodFirst)));

*       Calculate        Production operating costs and credits        ! Store which years-iterations have been solved
SolvedYearsAndCosts(CurrentOptYear) = TotalCost.l;
* write out production operate cost
HydrogenProductionOpCost(ProdActiveOptTechs,MNUMCR,NextOptYear) = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(YearPeriodMap(CalYears,PlanningPeriodSecond),
         sum(Fuels, AdjustedFuelPricebyPeriod(Fuels,ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond) *
   ProdFuelConsumptionPerTech(Fuels,ProdActiveOptTechs)) + ProductionVariableO_MCost(ProdActiveOptTechs,CenDivOpt,
   PlanningPeriodSecond))) * sum(DollarYear,GDP_Deflator(DollarYear)) / GDP_Deflator(NextOptYear);
* O&M Cost
HydrogenFixedO_MCost(ProdActiveOptTechs,MNUMCR,NextOptYear) = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(YearPeriodMap(CalYears,PlanningPeriodSecond),
   ProductionFixedO_MCost(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) * sum(DollarYear,GDP_Deflator(DollarYear)) /
   GDP_Deflator(NextOptYear);
*  ! operating credit Not exactly right,ask Amogh
HydrogenProductionOpCredit(ProdActiveOptTechs,MNUMCR,NextOptYear) = -1. * sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(YearPeriodMap(CalYears,PlanningPeriodSecond),
   ProductionTaxCreditActual(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) * sum(DollarYear,GDP_Deflator(DollarYear)) /
   GDP_Deflator(NextOptYear);

*  Calculate       Levelized cost of production   ! capital cost Needs to be levelized. Use third period amortization period
*OneArray(CurrentOptYear) = 1;
HydrogenProductionCapCost(ProdActiveOptTechs,MNUMCR,NextOptYear) = sum(CensusRegionMap(MNUMCR,CenDivOpt),
         sum(YearPeriodMap(CalYears,PlanningPeriodSecond), ProductionUnplannedCapacityCost(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) *
   sum(DollarYear,GDP_Deflator(DollarYear)) / GDP_Deflator(NextOptYear) / sum(YearPeriodMap(ThirdPeriodYears(CalYears),periods), Discount(EquityRate)) ;

* capital credit
HydrogenProductionInvstCredit(ProdActiveOptTechs,MNUMCR,NextOptYear) =  -1 * sum(CensusRegionMap(MNUMCR,CenDivOpt),
         sum(YearPeriodMap(CalYears,PlanningPeriodSecond),InvestmentTaxCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) *
   sum(DollarYear,GDP_Deflator(DollarYear)) / GDP_Deflator(NextOptYear);
* CO2 credit
CO2CaptureCredit(ProdActiveOptTechs,MNUMCR,NextOptYear) = -1 * sum(CensusRegionMap(MNUMCR,CenDivOpt),
         sum(YearPeriodMap(CalYears,PlanningPeriodSecond),Section45QSalineCredit(ProdActiveOptTechs,CenDivOpt,PlanningPeriodSecond))) *
   sum(DollarYear,GDP_Deflator(DollarYear)) / GDP_Deflator(NextOptYear);



*  Calculate     Demand slack per year and iteration
DemandSlackPerYearAndIter(MNUMCR,SeasonOpt,CurrentOptYear)
         = sum(CensusRegionMap(MNUMCR,CenDivOpt),sum(PlanningPeriodFirst, DemandSlack.l(CenDivOpt,SeasonOpt,PlanningPeriodFirst)))
                 * sum(DollarYear,GDP_Deflator(DollarYear)) / GDP_Deflator(CurrentOptYear);

HMMBLK_PHMM(Market_Price,MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv),
         PHMM(Market_Price,CensusDiv,CalYears)) * sum(DollarYear,GDP_Deflator(DollarYear)) ;
HMMBLK_HMPRODSEQ(CombustionFuels,MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), HMPRODSEQ(CombustionFuels,CensusDiv,CalYears)) ;
HMMBLK_CO2CAPFUEL(CombustionFuels,MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), CO2CAPFUEL(CombustionFuels,CensusDiv,CalYears)) ;
HMMBLK_H2Fuel(Fuels,MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), H2Fuel(Fuels,CensusDiv,CalYears)) ;
HMMBLK_HMGSPRD(MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), HMGSPRD(CalYears,CensusDiv)) ;
HMMBLK_HMCLPRD(MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), HMCLPRD(CalYears,CensusDiv)) ;
HMMBLK_HMELPRD(MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), HMELPRD(CalYears,CensusDiv)) ;
HMMBLK_HMBIPRD(MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), HMBIPRD(CalYears,CensusDiv)) ;
QBLK_QELHM(MNUMCR,CalYears) = sum(CensusRegionMap(MNUMCR,CensusDiv), QELHM(CensusDiv,CalYears)) ;

Execute_Unload 'hmm_report.gdx' ;

Execute_UnloadDI 'HMM_Results.gdx',
         ProductionUnplannedCapacityPerYearAndIter TransportUnplannedCapacityPerYearAndIter StorageUnplannedCapacityPerYearAndIter
         HydrogenProductionOpCost HydrogenFixedO_MCost HydrogenProductionOpCredit HydrogenProductionCapCost
         HydrogenProductionInvstCredit CO2CaptureCredit CO2CaptureQtybyTech CO2CaptureQty45QCreditbyYear
         HMMBLK_PHMM HMMBLK_HMPRODSEQ HMMBLK_CO2CAPFUEL HMMBLK_HMGSPRD HMMBLK_HMCLPRD HMMBLK_H2Fuel HMMBLK_HMELPRD HMMBLK_HMBIPRD QBLK_QELHM
         Section45VCreditbyYear CapacityProductionTaxCreditbyYear CapacityInvestmentTaxCreditbyYear CensusRegionMap
         ProductionOperatePerYearAndIter RegionalTransportPerYearAndIter DemandSlackPerYearAndIter dollar_year
 ;

if((Horizon.val=(LastModelYear-FirstModelYear+1)),

if(CreateSQLiteDB=1,
execute 'gdx2sqlite -i HMM_Results.gdx -o HMM_Results.db -expltext';
);

if(CreateOutputXL=1,
execute 'gdxxrw HMM_Results.gdx output=HMM_Results.xlsx squeeze=n @input\H2Write.txt';
);

);

