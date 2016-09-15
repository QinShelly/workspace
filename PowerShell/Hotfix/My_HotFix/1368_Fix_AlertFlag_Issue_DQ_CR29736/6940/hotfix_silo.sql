Alter PROCEDURE [dbo].[SP$RSI_DQ_CREATE_ALERT_INFO]  AS
BEGIN

    declare @lvs_mdx nvarchar(max)
    
    declare @siloId nvarchar(500)
    declare @siloType nvarchar(100)
    
    declare @vendorKey int
    declare @retailerKey int
    declare @sum float(53) 
    
    declare @rowId int
    declare @rowIdEnd int
    declare @totalPercent float
    declare @cumulativeTotalPercent float
     declare @lastTotalPercent float
    declare @lastCumulativeTotalPercent float
    declare @alertFlag char(10)
   
	declare @liveServerName nvarchar(500)
	declare @cubeName nvarchar(500)
	declare @cubeDBName nvarchar(500)
	

	
	declare @lvs_calendar NVARCHAR(100)
	declare @lvs_calendar_key NVARCHAR(100)

	
	declare @lvs_params NVARCHAR(500)
	declare @percent float
	
	select @siloId=SiloId,@siloType=Type from RSI_DIM_SILO 

	select @liveServerName= [dbo].[fn$RSI_get_config_property] ( 'db.domain.olap.liveserver');
	select @cubeName = [dbo].[fn$RSI_get_config_property]('db.domain.olap.cubeName')
	select @cubeDBName = [dbo].[fn$RSI_get_config_property] ( 'db.domain.olap.databaseName');
   
    select @percent = value from RSI_CORE_CFGPROPERTY where Name ='rsi.dq.subvendor.alert.percent'
    
    
    select top 1 @vendorKey = VENDOR_KEY,@retailerKey = RETAILER_KEY from RSI_CONFIG_CUSTOMERS 
                 where VENDOR_KEY  in (select VENDOR_KEY from RSI_DIM_VENDOR where IS_DUMMY=0) 
                 and RETAILER_KEY  in  (select  RETAILER_KEY from RSI_DIM_RETAILER where IS_DUMMY=0)

 

    --set @liveServerName='192.168.148.47'



    declare @mdx nvarchar(max)
    
    
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DQAlertTempTable]') AND type in (N'U'))
        DROP TABLE [dbo].[DQAlertTempTable]


    set @mdx = ' select ( [SUBVENDOR].[SUBVENDOR ID].[SUBVENDOR ID] ) on 1,
                [Measures].[Measures].[Total Sales Volume Units] on 0 
                from  ['+@cubeName+']'
               
               
    SET @lvs_mdx = 'select * into DQAlertTempTable
						    from OPENROWSET(''MSOLAP'', ''DATASOURCE='+@liveServerName+';Initial Catalog='+@cubeDBName+';'',
						    '''+@mdx+''') '
					     
							
		     exec sp_executesql @lvs_mdx
		     
		     --select "[SUBVENDOR].[SUBVENDOR ID].[SUBVENDOR ID].[MEMBER_CAPTION]" as subVendorId,
		     --       "[Measures].[Total Sales Volume Units]" as TotalSaleVolumeUnits  
		       
		     --    from DQAlertTempTable 

			 IF  (OBJECT_ID('DQAlertTempTable','U') IS NOT NULL) AND (NOT EXISTS (SELECT *  FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME ='DQAlertTempTable' AND COLUMN_NAME='[SUBVENDOR].[SUBVENDOR ID].[SUBVENDOR ID].[MEMBER_CAPTION]'))
				BEGIN
					ALTER TABLE DQAlertTempTable ADD [[SUBVENDOR]].[SUBVENDOR ID]].[SUBVENDOR ID]].[MEMBER_CAPTION]]] nvarchar(20)
				END
						         
		      insert into dbo.RSI_DQ_ALERT (SiloId,RetailerKey,SubVendorId,TotalSalesVolumeUnits,rowId)
		      
		       select @siloId,@retailerKey,[[SUBVENDOR]].[SUBVENDOR ID]].[SUBVENDOR ID]].[MEMBER_CAPTION]]] as subVendorId,
		            convert(bigint,convert(float,[[Measures]].[Total Sales Volume Units]]])) as TotalSalesVolumeUnits , 
		           ROW_NUMBER() over(order by convert(bigint,convert(float,[[Measures]].[Total Sales Volume Units]]]))  desc) as rowId
		         from DQAlertTempTable --where convert(bigint,"[Measures].[Total Sales Volume Units]") <> null
		         
		         
		        
		         
		         select @sum=SUM (TotalSalesVolumeUnits)  from dbo.RSI_DQ_ALERT
		         
		         
		         
		         update dbo.RSI_DQ_ALERT set [Sum]=@sum
		         
		         update dbo.RSI_DQ_ALERT set TotalPercent =  ([TotalSalesVolumeUnits]/[sum])*100
		     
		        
		         
		         set @rowId=1
		         select  @rowIdEnd = COUNT(*) from dbo.RSI_DQ_ALERT 
		         
		   while (@rowId<=@rowIdEnd)
		      begin
		            select  @totalPercent =TotalPercent ,@cumulativeTotalPercent=CumulativeTotalPercent
		            from dbo.RSI_DQ_ALERT where rowId =@rowId
		            
		            if(@rowId=1) 
		               begin
		                 set @cumulativeTotalPercent=@totalPercent 
						 --If the sales is not null,the first sub-vendor with the maximal sales should always be yes to alert.
						 IF @cumulativeTotalPercent IS NOT NULL
						   BEGIN
						 	  SET @alertFlag='Y'
						   END
						 ELSE
						   BEGIN
						 	  SET @alertFlag='N'
						   END
		                 update dbo.RSI_DQ_ALERT set CumulativeTotalPercent=@cumulativeTotalPercent,
		                                             AlertFlag =@alertFlag
		                        where rowId = @rowId
		               end
		               
		             else 
		                 begin
		                    select  @lastTotalPercent =TotalPercent ,@lastCumulativeTotalPercent=CumulativeTotalPercent
		                       from dbo.RSI_DQ_ALERT where rowId =@rowId-1
		                       
		                    set @cumulativeTotalPercent=@totalPercent + @lastCumulativeTotalPercent
		                    
		                    if (@cumulativeTotalPercent<@percent) 
		                       set @alertFlag='Y'
		                    else 
		                       set @alertFlag='N'
		                       
		                   update dbo.RSI_DQ_ALERT set CumulativeTotalPercent=@cumulativeTotalPercent,
		                                             AlertFlag =@alertFlag
		                     where rowId = @rowId
		                 
		                 end
		         
		          set @rowId = @rowId +1
		      end 
		        
		        
		        
	  IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DQAlertTempTable]') AND type in (N'U'))
           DROP TABLE [dbo].[DQAlertTempTable]
		         --select * from dbo.RSI_DQ_ALERT order by rowId
		         
		         --delete from   dbo.RSI_DQ_ALERT 
		END 
		GO