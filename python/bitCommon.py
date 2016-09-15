def testBit(int_type, offset):
	mask = 1 << offset
	return 	(int_type & mask)

# print bin(8)
# print 1 << 3
# print str(bin(100))

# i = 15
# mask = 1 << 3
# print   (i & mask) >> 3

# mask = 1 << 2
# print (i & mask) >> 2

# mask = 1 << 1
# print (i & mask) >> 1

# mask = 1 << 0
# print (i & mask) >> 0

# 01
# 10
# 11

maskBitPosition = 2
itemCount = 7
myList = [0,1,2,3,4,6]
def findMissing(a,itemCount,maskBitPosition):
	pile0 = []
	pile1 = []
	for i in a:
		mask = 1 << (maskBitPosition)
		if (i & mask) >> (maskBitPosition) == 0:
			pile0.append(i)
		if (i & mask) >> (maskBitPosition) == 1:
			pile1.append(i)
		
	print pile0
	print pile1
	
	if len(pile0) == 0:
		print "must be all 0"
		return
	if len(pile1) == 0:
		print "must be all 1"
		return
	
	if len(pile0) < itemCount / 2.0:
		print "must in 0 pile"
		return findMissing(pile0,itemCount / 2,maskBitPosition - 1)
	if len(pile1) < itemCount / 2:
		print "must in 1 pile"
		return findMissing(pile1,itemCount / 2,maskBitPosition - 1)
	
findMissing(myList,itemCount,maskBitPosition)

	