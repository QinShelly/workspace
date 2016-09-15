# coding: utf-8
import tushare as tu
import pandas as pd
# check 6 conditions
# 0 pe 9
pe_condition = 25	
# 1 debt ratio 1.5
debt_condition = 1.1
# 2 no loss in 5 yrs
# 3 distribute
# 4 profit increase in last year
# 5 pb 1.2
pb_condition = 1.5

# for each category, we pick rn <= rn_condition stocks
rn_condition = 3	

refresh_tushare = False
#refresh_tushare = True
# stock basics -- pe (0) pb (5)
# pe pb daily refresh
if refresh_tushare:
	df_pb = tu.get_stock_basics()
	df_pb.to_csv('stock_basics.csv')

df_pb = pd.read_csv('stock_basics.csv')

df_pb.loc[:,("pb_pe")] = df_pb["pb"] * 10 + df_pb["pe"]
# pb <= 1.2
# pe <= 9
df_pb = df_pb[(df_pb.pb <= pb_condition) & (df_pb.pe <= pe_condition) 
			& (df_pb.pb > 0) & (df_pb.pe > 0)
			& (df_pb.pb_pe <= 100)]
df_pb = df_pb[['code','name','pe','industry','pb','pb_pe']]
# add pb_pe

# report data -- profit (4) , distribute (3)
# report data yearly refresh
# df_ly = tu.get_report_data(2015,4)
df_ly = pd.read_csv('reportdata2015Q4.csv')
df_ly = df_ly.drop_duplicates(subset="code") 
df_profit = df_ly[(df_ly['profits_yoy'] > 0) & (df_ly['distrib'].notnull())]
df_profit = df_profit[['code','distrib','profits_yoy' ]]

# condition 0, 3, 4, 5
df_result = pd.merge(df_pb, df_profit, left_on='code', right_on ='code' )
#print (df_result.assign(rn=df_result.sort_values(["pb_pe"]).groupby(["industry"]).cumcount() + 1)).query('rn<3')

# no loss in 5 yrs (2)
# yearly
df_2ya = pd.read_csv('reportdata2014Q4.csv')
df_2ya = df_2ya.drop_duplicates(subset="code") 
df_2ya.loc[:,("net_profits_2ya")] = df_2ya["net_profits"] 
df_3ya = pd.read_csv('reportdata2013Q4.csv')
df_3ya = df_3ya.drop_duplicates(subset="code") 
df_3ya.loc[:,("net_profits_3ya")] = df_3ya["net_profits"] 
df_4ya = pd.read_csv('reportdata2012Q4.csv')
df_4ya = df_4ya.drop_duplicates(subset="code") 
df_4ya.loc[:,("net_profits_4ya")] = df_4ya["net_profits"] 
df_5ya = pd.read_csv('reportdata2011Q4.csv')
df_5ya = df_5ya.drop_duplicates(subset="code") 
df_5ya.loc[:,("net_profits_5ya")] = df_5ya["net_profits"] 

df_tmp1 = pd.merge(df_2ya,df_3ya,left_on ='code',right_on ='code')
df_tmp2 = pd.merge(df_4ya,df_5ya,left_on ='code',right_on ='code')
df_tmp3 = pd.merge(df_tmp1,df_tmp2,left_on ='code',right_on ='code')
df_tmp3 = df_tmp3[(df_tmp3.net_profits_2ya > 0) & (df_tmp3.net_profits_3ya > 0) & (df_tmp3.net_profits_4ya > 0) & (df_tmp3.net_profits_5ya > 0) ]
df_tmp3 = df_tmp3[['code','net_profits_2ya','net_profits_3ya','net_profits_4ya','net_profits_5ya']]

# condition 0, 2, 3, 4, 5
df_result2 = pd.merge(df_result, df_tmp3, left_on='code', right_on ='code' )

# debt ratio (1)
# quartely
df_debt = pd.read_csv('debtpaying2015Q4.csv')
df_debt = df_debt.replace('--',999)
df_debt[['currentratio']] = df_debt[['currentratio']].apply(pd.to_numeric)
df_debt = df_debt[df_debt['currentratio'] >= debt_condition]
df_debt = df_debt[['code','currentratio']]

df_result2 = pd.merge(df_result2,df_debt,left_on ='code',right_on ='code')

rn_str = "rn<=%s"  % rn_condition
print (df_result2.assign(rn=df_result2.sort_values(["pb_pe"])
	.groupby(["industry"]).cumcount() + 1)).query(rn_str).sort_values(by = ['industry','rn'])
