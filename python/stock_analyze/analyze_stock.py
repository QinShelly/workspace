# coding: utf-8

import tushare as ts
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

#df = ts.get_h_data('000623') #一次性获取全部日k线数据
#df.to_csv('000623.csv')

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
	if  currentStatus == 'NaturalRally' and row['high'] > naturalRally :
		row['naturalRally'] = naturalRally = row['high']
	# 6.d (2)
	if currentStatus == 'UpwardTrend' and row['high'] > upwardTrend :
		row['upwardTrend'] = upwardTrend = row['high']
	# 6.a 6.b (1)
	if  currentStatus == 'NaturalReaction' and row['low'] < naturalReaction :
		row['naturalReaction'] = naturalReaction = row['low']
	# 6.b (2)
	if  currentStatus == 'DownwardTrend' and row['low'] < downwardTrend :
		row['downwardTrend'] = downwardTrend = row['low']

	# 4.a
	if currentStatus == 'UpwardTrend' and row['low'] < upwardTrend - 6:
		redUpwardTrend = upwardTrend
		row['naturalReaction'] = naturalReaction = row['low']
		currentStatus = 'NaturalReaction'
	# 4.b
	if currentStatus == 'NaturalReaction' and row['high'] > naturalReaction + 6:
		redNaturalReaction = naturalReaction
		if row['high'] > upwardTrend:
			currentStatus = 'UpwardTrend'
			upwardTrend = row['high']
		else:
			currentStatus = 'NaturalRally'
			naturalRally = row['high']
	# 4.c
	if currentStatus == 'DownwardTrend' and row['high'] > downwardTrend + 6:
		blackDownwardTrend = downwardTrend
		row['naturalRally'] = naturalRally = row['high']
		currentStatus = 'NaturalRally'
	# 4.d
	if currentStatus == 'NaturalRally' and row['low'] < naturalRally - 6:
		blackNatualRally = naturalRally
		if row['low'] < downwardTrend:
			currentStatus = 'DownwardTrend'
			downwardTrend = row['low']
		else:
			currentStatus = 'NaturalReaction'
			naturalReaction = row['low']
	# 5.a
	if currentStatus == 'NaturalRally' and 'blackNatualRally' in locals() and row['high'] > blackNatualRally + 3:
		currentStatus = 'UpwardTrend'
		upwardTrend = row['high']
	# 5.b
	if currentStatus == 'NaturalReaction' and 'redNaturalReaction' in locals() and row['low'] < redNaturalReaction - 3:
		currentStatus = 'DownwardTrend'
		downwardTrend = row['low']
	#  6.e
	if currentStatus == 'NaturalReaction' and row['low'] < downwardTrend:
		currentStatus = 'DownwardTrend'
		row['downwardTrend'] = downwardTrend = row['low']
	#  6.f
	if currentStatus == 'NaturalRally' and row['high'] > upwardTrend:
		currentStatus = 'UpwardTrend'
		row['upwardTrend'] = upwardTrend = row['high']
	# 6.g
	if currentStatus == 'NaturalReaction':
		currentStatus = 'NaturalReaction'

	if pd.notnull(row['naturalRally']) or pd.notnull(row['upwardTrend']) or \
		pd.notnull(row['naturalReaction']) or pd.notnull(row['downwardTrend']):
		print "%s %6.2f %6.2f | %6.2f %6.2f %6.2f %6.2f" % (index, row['high'], row['low'], row['naturalRally'],\
			row['upwardTrend'], row['downwardTrend'],row['naturalReaction'] )

#print df[any((np.isfinite(df['upwardTrend'])) or any((np.isfinite(df['downwardTrend'])))]


#df.plot(x='date', y='close')
#plt.show()
