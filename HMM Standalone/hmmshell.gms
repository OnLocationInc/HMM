$Title  Hydrogen Market Module

$Ontext
Created by OnLocation, Inc. for DOE-FECM
$Offtext

$onUNDF

*----------------------------------------------------------------------------------------------------------
$set DirPath ".\"

*Set directory path for location of gams model files
$set HMMDir %DirPath%

*Set directory path for location of results files
$set  Outdir %DirPath%

*Assign current version of model files
$set HMM_InputFile 'input\H2_inputs.gdx'
$set HMM_InputRead  %HMMDir%HMM_input.gms
$set HMM_ModelPrep  %HMMDir%HMM_prep.gms
$set HMM_ModelVars     %HMMDir%HMM_parameters.gms
$set HMM_ModelSetup     %HMMDir%HMM_model.gms
$set HMM_Reports   %HMMDir%HMM_report.gms

* about.put captures information about the versions used for this run
file about /%Outdir%about.put/;
put about;
put 'Run started on = ' system.date ' at ' system.time /

* Read the inputs
$include %HMM_InputRead%
$IF errorlevel 1 $Abort 'Error occurred during user data preparation'
put 'Data Preparation file: %HMM_DataPrep% - run completed at  ' system.time  /
$log Data Preparation completed after %system.elapsed% seconds

*Call HMM model integration data preparation subroutine
$include %HMM_ModelPrep%
$IF errorlevel 1 $Abort 'Error occurred during model data preparation'
put 'Model Preparation file: %HMM_ModelPrep% - run completed at  ' system.time  /
$log Data Preparation completed after %system.elapsed% seconds

* Declare all the variables before running loop
$include %HMM_ModelVars%
$IF errorlevel 1 $Abort 'Model did not terminate with integer solution'
put 'CTS model file: %HMM_Model% - run completed at  ' system.time  /
$log Model Execution completed after %system.elapsed% seconds

* Run the loop over the horizon
loop(Horizon$(Horizon.val<=(LastModelYear-FirstModelYear+1)),
* Call HMM model setup and solve subroutine
$include %HMM_ModelSetup%
$IF errorlevel 1 $Abort 'Error occurred during model setup'
put 'Model Preparation file: %HMM_ModelPrep% - run completed at  ' system.time  /
$log Data Preparation completed after %system.elapsed% seconds

* Run the reporting code
$include %HMM_Reports%
$IF errorlevel 1 $Abort 'Error occurred in report generation'
put 'HMM report file: %HMM_Reports% - run completed at  ' system.time  /

  if((CreateYearlyGDXFile>0),
    put_utility 'msglog' / 'Creating yearly GDX file: HMM_'CURCALYR'.gdx';
loop(CurrentOptYear(CalYears),
    put_utility 'shell' / 'copy HMMshell.lst HMMshell_'CurrentOptYear.te(CurrentOptYear)'.lst' ;
    put_utility 'gdxout' / 'HMM_'CurrentOptYear.te(CurrentOptYear)'.gdx' ;
);
    execute_unload ;
  );
);

*--------------------------------------------------------------------------------------


