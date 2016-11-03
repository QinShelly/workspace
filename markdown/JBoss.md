- Install JBOSS

Clone repository from Stash `http://10.172.4.66:7990/projects/SOF/repos/vm/browse`   
Check word document and find install JBOSS 9 part  
run the install script, it will auto download JBOSS  
install a domain, and start JBOSS service   
JBOSS runlog is in `d:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\bin\run.log`

- Package  
ant -DsiloID=Ken_Hub -Ddeploy.release.name=Ken package

```
-- This should be updated in CP instead of Hub
update RSI_CORE_CFGPROPERTY
set value = 'ENG1VMDEVSRV7.eng.rsicorp.local'
 where name  = 'app.server.domain.host'
GO
update RSI_CORE_CFGPROPERTY
set value = 'D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain'
 where name  = 'app.server.domain.home'
```

- Deploy App JEE  
ant -DsiloID=Ken_Hub -Ddeploy.release.name=Ken deploy-app-jee

Check EAR and Dodeploy file in 
`D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\standalone\deployments`

Error:
Failure to locate DataSource java:jboss/datasources/rsiKen_HubDataSource
Add below to `D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\standalone\configuration\standalone.xml`
```
<xa-datasource jndi-name="java:jboss/datasources/rsiKen_HubDataSource" pool-name="rsiKen_HubDataSource" enabled="true">
                    <xa-datasource-property name="ServerName">
                        ENGV2QA3.ENG.RSICORP.LOCAL
                    </xa-datasource-property>
                    <xa-datasource-property name="DatabaseName">
                        Ken_Hub
                    </xa-datasource-property>
                    <xa-datasource-property name="useCursors">
                        True
                    </xa-datasource-property>
                    <xa-datasource-property name="useLOBs">
                        False
                    </xa-datasource-property>
                    <driver>jtds</driver>
                    <xa-pool>
                        <min-pool-size>20</min-pool-size>
                        <max-pool-size>30</max-pool-size>
                        <is-same-rm-override>false</is-same-rm-override>
                    </xa-pool>
                    <recovery no-recovery="true"/>
                    <validation>
                        <check-valid-connection-sql>select 1</check-valid-connection-sql>
                    </validation>
                </xa-datasource>
```

- Bypass SSO  
Change RsiUserContextProviderImpl to RsiUserContextProviderTempImpl
```D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\standalone\deployments\Ken_Hub.ear\webapp.war\WEB-INF\classes\rsi_uif_config.properties```


remove all "agent" in the file
`D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\standalone\deployments\Ken_Hub.ear\webapp.war\WEB-INF\web.xml` 
add below to bypass SSO 
```
    <context-param> 
        <param-name> RSI_UserToken</param-name> 
        <param-value>Ken.Yao@rsicorp.local</param-value> 
    </context-param>
```

- Debug JBoss
`JAVA_OPTS="$JAVA_OPTS -Xrunjdwp:transport=dt_socket,address=8787,server=y,suspend=n"`
Find a similar line in file `D:\RSI\fusionV\domains\ENG1VMDEVSRV7-Domain\bin\standalone.conf.bat` and uncomment it


Hub URL
RSI_CORE_CFGPROPERTY 
rsi.hub.portal.url  
