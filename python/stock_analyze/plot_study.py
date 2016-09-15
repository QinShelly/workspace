# coding: utf-8
import pandas as pd
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import datetime
ts = pd.Series(np.random.randn(1000),index=pd.date_range('1/1/2000',periods=1000))
ts=ts.cumsum()
ts.plot()
plt.show()

df = pd.read_csv('sp500.csv',index_col='Date',parse_dates=True)
ts=df['Close']
ts=df['Close'][-10:]
ts=df[['Close','Open']][-10:]
df['H-L'] = df.High - df.Low
close = df['Adj Close']
ma = pd.rolling_mean(close, 50)

ax1 = plt.subplot(2,1,1)
ax1.plot(close,label='sp500')
ax1.plot(ma,label='50MA')
plt.legend()

ax2=plt.subplot(2,1,2, sharex=ax1)
ax2.plot(df['H-L'],label = 'H-L')
plt.legend()
plt.show()
