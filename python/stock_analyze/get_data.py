import tushare as ts
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
a = ts.get_report_data(2016,4)
a.to_csv("reportdata2016Q4.csv")

b = ts.get_debtpaying_data(2016,4)
b.to_csv("debtpaying2016Q4.csv")