# coding: utf-8
import tushare as tu

df = tu.get_deposit_rate()
sorted = df.sort_index(by='date')
result=sorted.drop_duplicates('deposit_type',take_last=True)
print result

df_loan = tu.get_loan_rate()
sorted = df_loan.sort_index(by='date')
result=sorted.drop_duplicates('loan_type',take_last=True)
print result

df_supply = tu.get_money_supply()
df_supply = df_supply[['month','m1','m1_yoy']]
print df_supply.head(12)

df_cpi = tu.get_cpi().head(12)
df_cpi = df_cpi.sort_values(by='month',ascending=True)
#df_cpi.plot(x='month',y=cpi)
print df_cpi