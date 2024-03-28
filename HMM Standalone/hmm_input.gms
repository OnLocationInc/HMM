*Read the data in H2_User_Inputs.xlsx

$call gdxxrw input\H2_User_Inputs.xlsx output=input\H2_Inputs.gdx squeeze=n @input\H2Read.txt

Set      capacity
         periods years mapped to NEMS periods
;

* Sets contained in h2_inputs.gdx
Set      Coal_Region
         h2prodtech_specs
         Fuel_Region
         h2comptech_specs
         h2prodtech
         h2stortech
         h2stortech_specs
         h2transtech_specs
         CensusDiv
         NumYr
         GDPYears GDP Years
         Market_Price
         Market_Quantity
         prod_tech Abbreviations of h2prodtech
         Seasons full text and including All Seasons
         Steps
;


Set
         MNUMY3
         M10
         MNUMYR
         MNUMCR
         MNMFS1
         NDRGN1
;

Set
         Fuels(h2prodtech_specs)
         CombustionFuels(Fuels)
         CenDivOpt(CensusDiv) Census Divisions Opt
         SeasonOpt(Seasons)
         Census_Division_Links(CensusDiv,CensusDiv)
         Coal_Region_Map(CensusDiv,Coal_Region)
         Fuel_Region_Map(Fuel_Region,CensusDiv)
         CalYears(GDPYears)
         Market_Quantity_EMM(Market_Quantity)
         Market_Quantity_Code_Season(Market_Quantity,Seasons)
         Market_P_Q(Market_Price,Market_Quantity)
         Production_Code(prod_tech,h2prodtech)
         GDPYearMap(MNUMY3,GDPYears)
         CalYearMap(MNUMYR,CalYears)
         NumYr_2_CalYr(CalYears,NumYr)
         CensusRegionMap(MNUMCR,CensusDiv)
         CoalRegionMap(NDRGN1,Coal_Region)
         MAXNFR
         MarketQ_2_M10(Market_Quantity,M10)
         FuelRegion_2_MAXNFR(Fuel_Region,MAXNFR)   Map GAMS fuel regions to EMM fuel regions
;

Scalar
         CreateOutputXL
         CreateSQLiteDB
         CreateYearlyGDXFile
;

Parameter          Years_by_Period(periods)                Number of years in each planning period
         comptech_props(h2comptech_specs)
         HMMCntl
         FirstModelYear
         LastModelYear
         DaysInYear
         MMBTU_to_KWH
         EMRP Rate of Return on market
         Beta Equity Rate parameter
         HydrogenHHV HHV hydrogen per kg
         ProductionCapacityReserve
         HeatRateNuclear
         RenewablesShareLimit
         NuclearShareLimit
         ProductionGrowthLimit
         I_45V_SYR
         I_45V_LYR_NEW
         I_45V_DURATION
         I_45V_Multiplier
         MarketShareON
         MarketShareCutoff
         MarketShareAlpha
         dollar_year
         MinPrice
         slack_cost
         NationalCR
         HMMMARKUP(Market_Price)
         IRA_45V
         IRA_ITC(Steps)
         IRA_LCA(Steps)
         IRA_PTC(Steps)
         lca_tech(NumYr,prod_tech)
         Market_Sharing
         StorageExpansionFraction
         pipetech_props(h2transtech_specs)
         prodtech_props(h2prodtech_specs,h2prodtech)
         Production_Step_Cost_Fraction(Steps)
         Production_Step_Size(Steps)
         Production_Step_Size_Period(periods,Steps)
         prod_cap(prod_tech,CensusDiv,NumYr,capacity)
         Season_Fraction(Seasons)
         SeasonStorageMap(Seasons,Seasons)
         stortech_props(h2stortech_specs)
         stor_cap(h2stortech,CensusDiv,NumYr,capacity)
         Transportation_Step_Cost_Fraction(Steps)
         Transportation_Step_Size(Steps)
         Transportation_Step_Size_Period(periods,Steps)
         trans_cap(CensusDiv,CensusDiv,NumYr,capacity)
;

Parameter
         NCNTRL_CURCALYR current year in NEMS run (if not standalone mode)
         NCNTRL_CURITR current iteration in NEMS run
         MACOUT_MC_JPGDP(MNUMY3)
         MACOUT_MC_RMGBLUSREAL(MNUMYR)
         EMISSION_EMETAX(MNUMYR)
         EMEBLK_EBMHM(MNUMYR)
         EMEBLK_ECLHM(MNUMYR)
         EMEBLK_ENGHM(MNUMYR)
         EUSPRC_PELINP(MNUMYR,MNUMCR)
         AMPBLK_PNGIN(MNUMYR,MNUMCR)
         AMPBLK_PCLIN(MNUMYR,MNUMCR)
         WRENEW_PBMH2CL(NDRGN1,MNUMYR,MNMFS1)
         HMMBLK_QHMM(MNUMCR,MNUMYR,M10)
         QBLK_QUREL(MNUMYR,MNUMCR)
         QBLK_QWIEL(MNUMYR,MNUMCR)
         QBLK_QPVEL(MNUMYR,MNUMCR)
         COGEN_WHRFOSS(MNUMYR,MNUMCR)
         TCS45Q_CCS_SALINE_45Q(MNUMYR)
         TCS45Q_CCS_EOR_45Q(MNUMYR)
         TCS45Q_I_45Q_DURATION
         TCS45Q_I_45Q_LYR_NEW
         UECPOUT_TNS_COSTS(MNUMYR,MAXNFR)
;

$gdxin %HMM_InputFile%
$load Coal_Region=CoalRegion, Fuel_Region, h2comptech_specs, h2prodtech, h2stortech, h2prodtech_specs, h2stortech_specs, h2transtech_specs
$load CensusDiv, NumYr, GDPYears, Market_Price, Market_Quantity, prod_tech, Seasons, Steps, capacity, periods
$load CreateOutputXL, CreateSQLiteDB, CreateYearlyGDXFile

$load Fuels, Census_Division_Links, Coal_Region_Map, Fuel_Region_Map, CalYears, Market_Quantity_Code_Season, Market_Quantity_EMM
$load Production_Code, NumYr_2_CalYr, CenDivOpt, SeasonOpt, CombustionFuels, dollar_year=DollarYear, Market_P_Q

$load comptech_props, FirstModelYear, LastModelYear, DaysInYear, MMBTU_to_KWH
$load EMRP, Beta, HydrogenHHV, ProductionCapacityReserve, HeatRateNuclear, RenewablesShareLimit, NuclearShareLimit, ProductionGrowthLimit
$load I_45V_SYR, I_45V_LYR_NEW, I_45V_DURATION, I_45V_Multiplier, MarketShareON, MarketShareCutoff, MarketShareAlpha, MinPrice
$load HMMMARKUP=hmm_markup, IRA_ITC, IRA_LCA, IRA_PTC, lca_tech, slack_cost=SlackCost, NationalCR
$load pipetech_props, prodtech_props, Years_by_Period, StorageExpansionFraction
$load Production_Step_Cost_Fraction, Production_Step_Size, Production_Step_Size_Period, prod_cap, Season_Fraction, SeasonStorageMap=Storage_Season_Links
$load stortech_props, stor_cap, Transportation_Step_Cost_Fraction, Transportation_Step_Size, Transportation_Step_Size_Period, trans_cap

$load NCNTRL_CURCALYR=CurrentCalendarYear, NCNTRL_CURITR=Current_Iteration, MNUMY3=GDP_Years, MNUMYR=CalendarYears, MNUMCR=CensusRegions, MNMFS1=BiomassRegions, NDRGN1=CoalDemandRegions,
$load M10=DemandSectors, MAXNFR=FuelRegion, MarketQ_2_M10
$load GDPYearMap, CalYearMap, CensusRegionMap, CoalRegionMap, FuelRegion_2_MAXNFR

$load MACOUT_MC_JPGDP=PriceIndex_GDPChained,
$load EMISSION_EMETAX=CarbonPrice, EUSPRC_PELINP=IndustrialElectricityPrice,
$load AMPBLK_PNGIN=IndustrialNaturalGasPrice, AMPBLK_PCLIN=IndustrialCoalPrice,
$load WRENEW_PBMH2CL=BiomassPrice, EMEBLK_ENGHM=NaturalGasEmissionsFactor, EMEBLK_EBMHM=BiomassEmissionsFactor,
$load EMEBLK_ECLHM=CoalEmissionsFactor, MACOUT_MC_RMGBLUSREAL=LongTermBondRate, UECPOUT_TNS_COSTS=CO2_TransportAndStorageCosts,
$load HMMBLK_QHMM=HydrogenDemand, QBLK_QUREL=NuclearGeneration
$load QBLK_QWIEL=WindGeneration, COGEN_WHRFOSS=AvgFossilFuelHeatRate, TCS45Q_CCS_SALINE_45Q=Section45QCreditForSaline,
$load TCS45Q_CCS_EOR_45Q=Section45QCreditForEOR, QBLK_QPVEL=SolarPV_Generation, TCS45Q_I_45Q_DURATION=Section45QCreditDuration,
$load TCS45Q_I_45Q_LYR_NEW=LastYearSection45QCreditNew
$gdxin





