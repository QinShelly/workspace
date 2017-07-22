# coding: utf-8
import tushare as ts
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
import argparse
parser = argparse.ArgumentParser(description="My parser")

parser.add_argument("-g", "--games", type=int,dest='stockid', default=600547,
                    help="The stockid")
parser.add_argument('--feature', dest='feature', action='store_true')
parser.add_argument('--no-feature', dest='feature', action='store_false')
parser.set_defaults(feature=True)
parsed_args = parser.parse_args()

file = "%s.csv" % parsed_args.stockid
if parsed_args.feature:
	df = ts.get_h_data(sys.argv[1],start='2016-01-01') #一次性获取全部日k线数据
	df.to_csv(file)

df = pd.read_csv(file)
df = df.sort_values('date')
df = df.set_index('date')
df['seenHighest'] = np.NaN
df['seenLowest'] = np.NaN
df['secondaryRally'] = np.NaN
df['naturalRally'] = np.NaN
df['upwardTrend'] = np.NaN
df['red'] = np.NaN
df['black'] = np.NaN
df['downwardTrend'] = np.NaN
df['naturalReaction'] = np.NaN
df['secondaryReaction'] = np.NaN
df['reason'] = np.NaN

seenHighest = 0 
seenLowest = 999
determineFirstStatus = True
lastPivotalStatus = 'Unknown'
currentStatus = 'Unknown'
redNaturalReaction = 0
blackNaturalRally = 999
upwardTrend = downwardTrend = naturalReaction  = 0
naturalRally = secondaryRally = secondaryReaction =0

for index, row in df.iterrows():
	if row['high'] > seenHighest:
		seenHighest = row['high']
		row['seenHighest'] = row['high']
	if row['low'] < seenLowest:
		seenLowest = row['low']
		row['seenLowest'] = row['low']
	if row['high'] > seenLowest + 6 and currentStatus == 'Unknown':
		row['upwardTrend'] = upwardTrend = row['high']
		currentStatus = 'UpwardTrend'
	if row['low'] < seenHighest - 6 and currentStatus == 'Unknown':
		row['downwardTrend'] =	downwardTrend = row['low']
		currentStatus = 'DownwardTrend'

# =============================================
	#  6.g(3)
	# SecondaryRally -- NaturalRally
	if  currentStatus == 'SecondaryRally' and row['high'] > naturalRally :
		currentStatus = 'NatualRally'
		row['naturalRally'] = naturalRally = row['high']
		row['reason'] = 12
		continue
	#  6.g(2)
	# SecondaryRally -- SecondaryRally
	if  currentStatus == 'SecondaryRally' and row['high'] > secondaryRally :
		row['secondaryRally'] = secondaryRally = row['high']
		row['reason'] = 11
		continue
	# SecondaryRally -- DownwardTrend
	# SecondaryRally -- NaturalReaction
	# SecondaryRally -- SecondaryReaction
# =============================================
	# 5.a
	# NatualRally -- +3 blackNaturalRally -- UpwardTrend
	if currentStatus == 'NaturalRally' and row['high'] > blackNaturalRally + 3:
		currentStatus = 'UpwardTrend'
		row['upwardTrend'] = upwardTrend = row['high']
		row['reason'] = 231
		continue
	#  6.f
	# NatualRally --  Higher than UpwardTrend -- UpwardTrend
	if currentStatus == 'NaturalRally' and row['high'] > upwardTrend:
		currentStatus = 'UpwardTrend'
		row['upwardTrend'] = upwardTrend = row['high']
		row['reason'] = 232
		continue
	# 6.c(2) 6.d(2)
	# NatualRally -- NatualRally
	if  currentStatus == 'NaturalRally' and row['high'] > naturalRally :
		row['naturalRally'] = naturalRally = row['high']
		row['reason'] = 22
		continue
	# 6.h(1) NatualRally -- -6 -- secondaryReaction
	if currentStatus == 'NaturalRally' and row['low'] < naturalRally - 6 \
	and row['low'] > naturalReaction and naturalReaction > 0:
		currentStatus = 'SecondaryReaction'
		row['secondaryReaction'] = secondaryReaction = row['low']
		row['reason'] = 26
		continue
	# 4.d 6.b(1)
	# NaturalRally -- -6 -- DownwardTrend Or NaturalReaction
	if currentStatus == 'NaturalRally' and row['low'] < naturalRally - 6:
		blackNaturalRally = naturalRally
		row['black'] = 6666
		if row['low'] < downwardTrend:
			currentStatus = 'DownwardTrend'
			row['downwardTrend'] = downwardTrend = row['low']
			row['reason'] = 24
		else:
			currentStatus = 'NaturalReaction'
			row['naturalReaction'] = naturalReaction = row['low']
			row['reason'] = 25
		continue
	
# =============================================
	# 6.d (3)
	# UpwardTrend -- continue up -- UpwardTrend
	if currentStatus == 'UpwardTrend' and row['high'] > upwardTrend :
		row['upwardTrend'] = upwardTrend = row['high']
		row['reason'] = 33
		continue
	# 4.a 6.a
	# UpwardTrend -- -6 -- NatualReaction
	if currentStatus == 'UpwardTrend' and row['low'] < upwardTrend - 6:
		redUpwardTrend = upwardTrend
		blackNaturalRally = 999
		row['red'] = 9999
		row['naturalReaction'] = naturalReaction = row['low']
		currentStatus = 'NaturalReaction'
		row['reason'] = 35
		continue
	# UpwardTrend -- -6 -- SecondaryReaction
# =============================================
	# 6.b(3)
	# DownwardTrend -- continue down -- DownwardTrend
	if  currentStatus == 'DownwardTrend' and row['low'] < downwardTrend :
		row['downwardTrend'] = downwardTrend = row['low']
		row['reason'] = 44
		continue
	# 4.c 6.c(1)
	# DownwardTrend -- +6 -- NatualRally
	if currentStatus == 'DownwardTrend' and row['high'] > downwardTrend + 6:
		blackDownwardTrend = downwardTrend
		redNaturalReaction = 0
		row['black'] = 6666
		row['naturalRally'] = naturalRally = row['high']
		currentStatus = 'NaturalRally'
		row['reason'] = 42
		continue
	# DownTrend -- +6 -- SecondaryRally
# =============================================
	# 5.b
	# NaturalReaction -- -3 redNaturalReaction -- DownwardTrend
	if currentStatus == 'NaturalReaction' and row['low'] < redNaturalReaction - 3:
		currentStatus = 'DownwardTrend'
		row['downwardTrend'] = downwardTrend = row['low']
		row['reason'] = 541
		continue
	#  6.e
	# NaturalReaction -- DownwardTrend
	if currentStatus == 'NaturalReaction' and row['low'] < downwardTrend:
		currentStatus = 'DownwardTrend'
		row['downwardTrend'] = downwardTrend = row['low']
		row['reason'] = 542
		continue
	#  6.b(2)
	# NaturalReaction -- NaturalReaction
	if  currentStatus == 'NaturalReaction' and row['low'] < naturalReaction :
		row['naturalReaction'] = naturalReaction = row['low']
		row['reason'] = 55
		continue
	# 6.g(1) 
	# NaturalReaction -- +6 -- secondaryRally
	if currentStatus == 'NaturalReaction' and row['high'] > naturalReaction + 6 \
	and row['high'] < naturalRally and naturalRally != 999:
		currentStatus = 'SecondaryRally'
		row['secondaryRally'] = secondaryRally = row['high']
		row['reason'] = 51
		continue
	# 4.b 6.d(1)
	# NaturalReaction -- +6 -- UpTrend Or NatualRally
	if currentStatus == 'NaturalReaction' and row['high'] > naturalReaction + 6:
		redNaturalReaction = naturalReaction
		row['red'] = 9999
		if row['high'] > upwardTrend:
			currentStatus = 'UpwardTrend'
			row['upwardTrend'] = upwardTrend = row['high']
			row['reason'] = 53
		else:
			currentStatus = 'NaturalRally'
			row['naturalRally'] = naturalRally = row['high']
			row['reason'] = 52
		continue
	
# =============================================
	#  6.h(3)
	# SecondaryReaction -- NaturalReaction
	if  currentStatus == 'SecondaryReaction' and row['low'] < naturalReaction :
		currentStatus = 'NaturalReaction'
		row['naturalReaction'] = naturalReaction = row['low']
		row['reason'] = 65
		continue
	#  6.h(2)
	# SecondaryReaction -- SecondaryReaction
	if  currentStatus == 'SecondaryReaction' and row['low'] < secondaryReaction :
		row['secondaryReaction'] = secondaryReaction = row['low']
		row['reason'] = 66
		continue
	# SecondaryReaction -- UpwardTrend
	# SecondaryReaction -- NaturalRally
#=============================================

for index, row in df.iterrows():
	if pd.notnull(row['naturalRally']) or pd.notnull(row['upwardTrend'])  \
		or pd.notnull(row['naturalReaction']) or pd.notnull(row['downwardTrend']) \
		or pd.notnull(row['secondaryRally']) or pd.notnull(row['secondaryReaction']):
		print "%s %6.2f %6.2f %10s| %6.2f %6.2f %6.2f || %6.2f %6.2f %6.2f | %7.0f %7.0f" \
		 % (index, row['high'], row['low'], row['reason'],\
		 row['secondaryRally'], row['naturalRally'],row['upwardTrend'], \
		 row['downwardTrend'],row['naturalReaction'],row['secondaryReaction'] ,row['black'],row['red'])

# for index, row in df.iterrows():
# 	print "%s %6.2f %6.2f %10s| %6.2f %6.2f %6.2f || %6.2f %6.2f %6.2f | %7.0f %7.0f" \
# 	 % (index, row['high'], row['low'], row['reason'],\
# 	 row['secondaryRally'], row['naturalRally'],row['upwardTrend'], \
# 	 row['downwardTrend'],row['naturalReaction'],row['secondaryReaction'] ,row['black'],row['red'])

#df.plot(x='date', y='close')
#plt.show()
