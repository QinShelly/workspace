import MySQLdb
 
try:
    conn=MySQLdb.connect(host='localhost',user='root',passwd='',db='ppdai',port=3306)
    cur=conn.cursor()
    cur.execute('select * from ppdai')
    value=[1,'hi rollen']
    cur.execute('insert into test values(%s,%s)',value)
    values=[]
    for i in range(20):
        values.append((i,'hi rollen'+str(i)))    
    cur.executemany('insert into test values(%s,%s)',values)
    cur.execute('update test set info="I am rollen" where id=3')
    sql = "select count(*) from vw_ppdai where id = 'http://invest.ppdai.com/loan/info?id=3471442' and amount_bid > 0" 
    print sql
       
    count=cur.execute(sql)
    print 'there has %s rows record' % count
 
    result=cur.fetchone()
    print result
    print 'count is %s' % result

    if result[0] == 1:
    	print "it is a bid"
    else:
    	print "not at bid"

    conn.commit()
    cur.close()
    conn.close()
except MySQLdb.Error,e:
     print "Mysql Error %d: %s" % (e.args[0], e.args[1])