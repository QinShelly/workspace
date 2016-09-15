# RV #

- JBoss log is at:  
Change Server name 
\\PRODP1FS120.colo.retailsolutions.com\c$\RSI\Fusion\domains\PRODP1FS120-Domain\log

## How to get MDX used in RV ##
In ticket get Job ID like: 0588-0132744. This is transformed report id, not the report id stored in DB. 
In Jobs page in RV, filter this Job ID. Click the link in Status column to open the log page.
You can find MDX in the log page

## RV tables ## 

- RSI_CORE_CFGPROPERTY  

 Report types metadata – ONLY IN HUB
- RSI_REPORT_DEFINITION_SILO
- RSI_REPORT_DEFINITION_SILOTYPE

Data for saved report(my reports)
- RSI_REPORT_DEFINITION
- RSI_REPORT_USER
- RSI_PURPOSEDREPORT_METADATA

Data for generated reports(inbox)
- RSI_PROCESSED_REPORT
- RSI_PROCESSED_REPORT_SHARE

Data for translation tables (this may not need to copy, just run a job to load translation and sync it from hub to silo)
- RSI_META_TRANSLATION_X
- RSI_META_TRANSLATION_MESSAGES
- RSI_META_TRANLATION_LANG

Data for filters
- RSI_FILTER_DEFINITION
- RSI_FILTER_USER
- RSI_FILE_FDL_RELATION

Data for job (Job list)
- RSI_CORE_JOB_DEFINITION
- RSI_CORE_JOB
- RSI_CORE_JOB_LOG

Data for schedule (schedule list)
- RSI_REPORT_SCHEDULE_STATUS
- RSI_CORE_SCHEDULE
- RSI_CORE_SCHEDULE_SILO_SYNC_HUB, all the infos from silo RSI_CORE_SCHEDULE are synced to this HUB table
- RSI_CORE_TIME_TRIGGER
- RSI_ADV_RPT_CORE_SCHEDULE
- RSI_ADVANCED_REPORT_SCHEDULE
- RSI_ES_REPORT_SCHEDULE
- RSI_EASY_SCHEDULING_TEMP

Data for log (this may not need?)
- RSI_LOG
- RSI_LOG_OWNER_RELATION
- RSI_LOG_OWNER_TYPE

## Get Data Export reports ##
Run this query on Hub production, this will get top 10 data export report by filesize

	select top 10 * from RSI_PROCESSED_REPORT where ReportTypeId = 11 order by FileSize desc

Also take this, top 10 data export reports which took long time.

	select top 10 * from RSI_PROCESSED_REPORT where ReportTypeId = 11 order by datediff (second , StartDate , EndDate ) desc

Also take, top 10 report (not just data export)

	select top 10 * from RSI_PROCESSED_REPORT order by datediff ( second, StartDate, EndDate ) desc