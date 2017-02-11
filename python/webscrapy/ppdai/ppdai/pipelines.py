# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html

import sqlite3

class PpdaiPipeline(object):
    def process_item(self, item, spider):
        conn = sqlite3.connect('example.db')
        c = conn.cursor()

        # Insert a row of data
        c.execute("INSERT INTO ppdai (id , ppdai_level , title , rate , amount "
                  ", limitTime "
                  ", purpose "
                  ", sex "
                  ",age "
                  ", marriage "
                  ", education "
                  ", house "
                  ", car "
                  ", school "
                  ", education_level "
                  ", education_method "
                  ", detail, hukou , certificates_in_str, cnt_return_on_time, cnt_return_less_than_15, over15plus "
                  ", total_borrow, waiting_to_pay, waiting_to_get_back) "
                  "VALUES (?,?,?,?,?"
                  ",?,?,?,?,?,?"
                  ",?,?,?,?,?"
                  ",?, ? ,?, ?, ?, ?"
                  ",? ,? ,?)",
                  (item['id'], item['rank'], item['title'][0], item['brate'][0], item['qty']
                   , item['limitTime'][0]
                   , "purpose"
                   , item['sex']
                   , item['age']
                   , "marriage"
                   , item['education']
                   , item['house']
                   , item['car']
                   , item['school']
                   , item['study_level']
                   , item['study_format']
                   , item['detail'], item['hukou'], item['audit'], item['pay_clear'], item['over1_15'],item['over15plus']
                   , item['total_borrow'],item['to_pay'],item['to_receive']
                   )
                  )
        conn.commit()
        sql = "select amount_bid from vw_ppdai where id = '%s'" % item['id']
        print sql
        data = conn.execute(sql) 

        # one row or an empty list is in data. 
        for row in data:
          amount_bid = row[0] 
          if amount_bid is None:
            print "not a bid :("
          else:
            if int(amount_bid) > 0:
              print "!!!!!!!!!!!!!!!!insert into bidProcess!!!!!!!!!!!!!!"
              conn.execute("INSERT INTO bidProcess(id) values ('%s')" % item['id'])
            else:
              print "not a bid :("
          
        # fetchone not working
        # data = c.fetchone()
        # if data is None: 
        #     print "not a bid" 
        # else:
        #   print data[0]
        #   if int(data[0]) > 0:
        #     print "insert into bidProcess"
        #     c.execute("INSERT INTO bidProcess(id) values ('%s')" % item['id'])

        # Save (commit) the changes
        conn.commit()

        # We can also close the connection if we are done with it.
        # Just be sure any changes have been committed or they will be lost.
        conn.close()
        return item
