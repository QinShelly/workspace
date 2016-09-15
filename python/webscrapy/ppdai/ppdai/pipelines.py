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
                  ", limitTime , purpose, sex ,age , marriage , education "
                  ", house , car ,school , education_level , education_method "
                  ", detail, hukou , certificates_in_str, cnt_return_on_time, cnt_return_less_than_15, over15plus "
                  ", total_borrow, waiting_to_pay, waiting_to_get_back) "
                  "VALUES (?,?,?,?,?"
                  ",?,?,?,?,?,?"
                  ",?,?,?,?,?"
                  ",?, ? ,?, ?, ?, ?"
                  ",? ,? ,?)",
                  (item['id'], item['rank'], item['title'][0], item['brate'][0], item['qty']
                   , item['limitTime'][0], item['purpose'], item['sex'][0], item['age'][0], item['marriage'][0],
                        item['education'][0]
                   , item['house'][0], item['car'][0], item['school'], item['study_level'],
                        item['study_format']
                   ,item['detail'], item['hukou'], item['audit'], item['pay_clear'], item['over1_15'],item['over15plus']
                   ,item['total_borrow'],item['to_pay'],item['to_receive']
                   )
                  )
        # Save (commit) the changes
        conn.commit()

        # We can also close the connection if we are done with it.
        # Just be sure any changes have been committed or they will be lost.
        conn.close()
        return item
