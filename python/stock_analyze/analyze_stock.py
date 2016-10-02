# coding: utf-8

import tushare as ts
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# df = ts.get_h_data('601318',start='2015-01-01') #一次性获取全部日k线数据
# df.to_csv('601318.csv')

df = pd.read_csv('601318.csv')
df = df.sort_values('date')
df = df.set_index('date')
df['seenHighest'] = np.NaN
df['seenLowest'] = np.NaN
df['secondaryRally'] = np.NaN
df['naturalRally'] = np.NaN
df['upwardTrend'] = np.NaN
df['downwardTrend'] = np.NaN
df['naturalReaction'] = np.NaN
df['secondaryReaction'] = np.NaN
df['reason'] = np.NaN

seenHighest = 0 
seenLowest = 999
determineFirstStatus = True
currentStatus = 'Unknown'
upwardTrend = 0
downwardTrend = 0
naturalReaction = 0
naturalRally = 0

for index, row in df.iterrows():

	if row['high'] > seenHighest:
		seenHighest = row['high']
		row['seenHighest'] = row['high']
	if row['low'] < seenLowest:
		seenLowest = row['low']
		row['seenLowest'] = row['low']
	if row['high'] > seenLowest + 6 and currentStatus == 'Unknown':
		row['upwardTrend'] = row['high']
		upwardTrend = row['high']
		currentStatus = 'UpwardTrend'
	if row['low'] < seenHighest - 6 and currentStatus == 'Unknown':
		row['downwardTrend'] = row['low']
		downwardTrend = row['low']
		currentStatus = 'DownwardTrend'
	
	# 6.c 6.d (1)
	# 
	if  currentStatus == 'NaturalRally' and row['high'] > naturalRally :
		row['naturalRally'] = naturalRally = row['high']
		row['reason'] = 1
		continue
	# 6.d (2)
	# UpwardTrend -- continue up 
	if currentStatus == 'UpwardTrend' and row['high'] > upwardTrend :
		row['upwardTrend'] = upwardTrend = row['high']
		row['reason'] = 2
		continue
	# 6.a 6.b (1)
	if  currentStatus == 'NaturalReaction' and row['low'] < naturalReaction :
		row['naturalReaction'] = naturalReaction = row['low']
		row['reason'] = 3
		continue

	# 6.b (2)
	# DownwardTrend -- continue down 
	if  currentStatus == 'DownwardTrend' and row['low'] < downwardTrend :
		row['downwardTrend'] = downwardTrend = row['low']
		row['reason'] = 4
		continue

	# 4.a
	# UpwardTrend -- -6 -- NatualReaction
	if currentStatus == 'UpwardTrend' and row['low'] < upwardTrend - 6:
		redUpwardTrend = upwardTrend
		row['naturalReaction'] = naturalReaction = row['low']
		currentStatus = 'NaturalReaction'
		row['reason'] = 5
		continue
	# 4.b
	# NaturalReaction -- +6 -- UpTrend Or NatualRally
	if currentStatus == 'NaturalReaction' and row['high'] > naturalReaction + 6:
		redNaturalReaction = naturalReaction
		if row['high'] > upwardTrend:
			currentStatus = 'UpwardTrend'
			upwardTrend = row['high']
			row['reason'] = '4.b'
		else:
			currentStatus = 'NaturalRally'
			naturalRally = row['high']
			row['reason'] = '4.b'
		row['reason'] = 6
		continue
	# 4.c
	# DownTrend -- +6 -- NatualRally
	if currentStatus == 'DownwardTrend' and row['high'] > downwardTrend + 6:
		blackDownwardTrend = downwardTrend
		row['naturalRally'] = naturalRally = row['high']
		currentStatus = 'NaturalRally'
		row['reason'] = 7
		continue
	# 4.d
	# NaturalRally -- -6 -- DownwardTrend Or NaturalReaction
	if currentStatus == 'NaturalRally' and row['low'] < naturalRally - 6:
		blackNatualRally = naturalRally
		if row['low'] < downwardTrend:
			currentStatus = 'DownwardTrend'
			downwardTrend = row['low']
		else:
			currentStatus = 'NaturalReaction'
			naturalReaction = row['low']
		row['reason'] = 8
		continue
	# 5.a
	if currentStatus == 'NaturalRally' and 'blackNatualRally' in locals() and row['high'] > blackNatualRally + 3:
		currentStatus = 'UpwardTrend'
		upwardTrend = row['high']
		row['reason'] = 9
		continue
	# 5.b
	if currentStatus == 'NaturalReaction' and 'redNaturalReaction' in locals() and row['low'] < redNaturalReaction - 3:
		currentStatus = 'DownwardTrend'
		downwardTrend = row['low']
		row['reason'] = 10
		continue
	#  6.e
	if currentStatus == 'NaturalReaction' and row['low'] < downwardTrend:
		currentStatus = 'DownwardTrend'
		row['downwardTrend'] = downwardTrend = row['low']
		row['reason'] = 11
		continue
	#  6.f
	if currentStatus == 'NaturalRally' and row['high'] > upwardTrend:
		currentStatus = 'UpwardTrend'
		row['upwardTrend'] = upwardTrend = row['high']
		row['reason'] = 12
		continue
	# 6.g
	if currentStatus == 'NaturalReaction':
		currentStatus = 'NaturalReaction'

for index, row in df.iterrows():
	if pd.notnull(row['naturalRally']) or pd.notnull(row['upwardTrend']) or \
		pd.notnull(row['naturalReaction']) or pd.notnull(row['downwardTrend']):
		print "%s %6.2f %6.2f %10s| %6.2f %6.2f %6.2f %6.2f" % (index, row['high'], row['low'], row['reason'],\
		 row['naturalRally'],row['upwardTrend'], row['downwardTrend'],row['naturalReaction'] )

#print df[any((np.isfinite(df['upwardTrend'])) or any((np.isfinite(df['downwardTrend'])))]

#df.plot(x='date', y='close')
#plt.show()
