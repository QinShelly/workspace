  
alter PROC [dbo].[sp$RSI_DQ_SYNC_JOB]  
 AS  
 BEGIN    
        declare @siloId nvarchar(500)  
       declare @syncCount int  
       declare @expectRebuild nvarchar(10)  
       declare @siloName nvarchar(500)  
       declare @hubName nvarchar(500)  
       declare @currentTime nvarchar(10)  
       declare @currentDate VARCHAR (23)  
          
    declare @sql nvarchar(max)  
   
  
    DECLARE @last_sync_time   NVARCHAR(50)  
    select @last_sync_time= value FROM dbo.RSI_DQ_PARAMETER_STORE WHERE Name='DQ_LAST_SYNC_TIME'  
      
    select @siloName = value from RSI_CORE_CFGPROPERTY where Name ='db.domain.name'  
    select @hubName = value from RSI_CORE_CFGPROPERTY where Name ='md.domain.name'  
   
      if(@last_sync_time is null)  
          BEGIN  
                
               select top 1 @siloId =  SiloId from dbo.RSI_DIM_SILO  
               set @currentTime = CONVERT(nvarchar(10),getdate(),120)  
            
              SET @sql =  
             -- 'EXEC (''delete from '+@hubName+'.dbo.RSI_DQ_EXPECT_DATA where  SiloId ='''''+@siloId+''''''') AT '+@siloName +'HubLink    
                
                  
             -- insert into '+@siloName +'HubLink.'+@hubName+'.dbo.RSI_DQ_EXPECT_DATA  
               -- select * from RSI_DQ_EXPECT_DATA  
            
              'insert into '+@siloName +'HubLink.'+@hubName+'.dbo.[RSI_DQ_GAP_INFO]  
              select * from [RSI_DQ_GAP_INFO]  where GAP=''Y'' 
                
              delete from '+@siloName +'HubLink.'+@hubName+'.dbo.[RSI_DQ_ALERT] where SiloId = '''+@siloId +'''   
                
              insert into '+@siloName +'HubLink.'+@hubName+'.dbo.[RSI_DQ_ALERT]  
              select * from RSI_DQ_ALERT'  
                
              EXEC (@sql)  
                
                
              set @currentDate =CONVERT (VARCHAR (23),  GETDATE(), 121)  
                
              INSERT dbo.RSI_DQ_PARAMETER_STORE  (Name, Value) VALUES ('DQ_LAST_SYNC_TIME',  @currentDate);  
                   
                 SET @sql=  'insert into '+@siloName +'HubLink.'+@hubName+'.dbo.RSI_DQ_SILO_SYNC_TIME (SiloId,SyncTime)   
                               values('''+@siloId +''','''+@currentDate+''')'  
                 EXEC (@sql)  
                 --select  @sql  
          END  
       else   
          BEGIN  
            
             select @expectRebuild = value from dbo.RSI_DQ_PARAMETER_STORE where Name = 'DQ_EXPECT_REBUILD'  
               
              select top 1 @siloId =  SiloId from dbo.RSI_DIM_SILO  
               set @currentTime = CONVERT(nvarchar(10),getdate(),120)  
               
             if(@expectRebuild= 'Y')  
             begin  
            
               --set @sql =  
               -- 'delete from '+@siloName+'HubLink.'+@hubName+'.dbo.RSI_DQ_EXPECT_DATA where SiloId ='''+@siloId+'''   
                  
               -- insert into '+@siloName +'HubLink.'+@hubName +'.dbo.RSI_DQ_EXPECT_DATA  
               -- select * from RSI_DQ_EXPECT_DATA'  
                  
               -- exec (@sql)  
                  
                update RSI_DQ_PARAMETER_STORE  set Value ='N' where Name = 'DQ_EXPECT_REBUILD'  
             end  
                 
               select top 1 @siloId =  SiloId from dbo.RSI_DIM_SILO  
               set @currentTime = CONVERT(nvarchar(10),getdate(),120)  
                 
               set @sql=  
               --' EXEC (''delete from  '+@hubName+'.dbo.[RSI_DQ_GAP_INFO] where SiloId ='''''+@siloId+''''' and convert(nvarchar(10),TimeStamp,120) = '''''+@currentTime+''''''') AT '+@siloName +'HubLink   
                 
               'insert into '+@siloName +'HubLink.'+@hubName +'.dbo.[RSI_DQ_GAP_INFO]  
                select * from [RSI_DQ_GAP_INFO] where GAP=''Y'' and  TimeStamp >'''+ @last_sync_time+'''  
                 
                delete from '+@siloName +'HubLink.'+@hubName+'.dbo.[RSI_DQ_ALERT] where SiloId = '''+@siloId +'''   
                
                insert into '+@siloName +'HubLink.'+@hubName+'.dbo.[RSI_DQ_ALERT]  
                select * from RSI_DQ_ALERT'  
                  
                exec (@sql)  
                  
                 
                  
                ---------------------------  
                --select @syncCount = MAX (SyncCount) from RSI_DQ_GAP_INFO where convert(nvarchar(10),TimeStamp,120) =CONVERT(nvarchar(10),GETDATE(),120 )   
                --select top 1 @siloId =  SiloId from dbo.RSI_DIM_SILO  
                  
           
                -- set @sql =  
                --   'if exists (select SyncCount from '+@siloName +'HubLink.'+@hubName +'.dbo.RSI_DQ_SILO_SYNC_COUNT where SiloId='''+@siloId+''')  
                --     UPDATE '+@siloName +'HubLink.'+@hubName +'.dbo.RSI_DQ_SILO_SYNC_COUNT set SyncCount= '+convert(nvarchar,@syncCount)+' where siloId= '''+@siloId+'''   
                --   else   
                --     insert into '+@siloName +'HubLink.'+@hubName +'.dbo.RSI_DQ_SILO_SYNC_COUNT (SiloId,SyncCount) values('''+@siloId+''','+convert(nvarchar,@syncCount)+')'  
                -- exec (@sql)  
                  
                ----------------------------------  
                  
                 set @currentDate =CONVERT (VARCHAR (23),  GETDATE(), 121)  
               UPDATE dbo.RSI_DQ_PARAMETER_STORE SET VAlUE =   @currentDate  WHERE NAME = 'DQ_LAST_SYNC_TIME'  
            
                
            
                 SET @sql=  'update '+@siloName +'HubLink.'+@hubName+'.dbo.RSI_DQ_SILO_SYNC_TIME    
                            set LastSyncTime = SyncTime ,  
                             SyncTime='''+@currentDate+''' where SiloId= '''+@siloId +''''  
                   EXEC (@sql)  
                   --select @sql  
            
            
            
          END  
         
         
         
         
    
    
  END  
 
  
 