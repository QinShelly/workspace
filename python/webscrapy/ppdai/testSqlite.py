# -*- coding: utf-8 -*-
import time
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
from selenium.common.exceptions import UnexpectedAlertPresentException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
import unittest, time, re
import sqlite3
import ppdai.config
import random
import datetime



cnt_row = 0
visited_li = []
conn = sqlite3.connect('example.db')
c = conn.cursor()

while True:
    c.execute("select amount_bid from vw_ppdai where id = ?", ('http://invest.ppdai.com/loan/info?id=33708125',) )
    if c.fetchone() > 0:
        c.execute("INSERT INTO bidProcess(id) values (?)",('http://invest.ppdai.com/loan/info?id=33708125',))

c.execute("select amount_bid from vw_ppdai where id = '%s'" % item['id']) 
        amount_bid = c.fetchone()
        print "amount_bid %s" % amount_bid

    # Get item to bid
    
    sql = "select id, amount_bid from vw_ppdai where amount_bid > 0 and bid is null"
    found = False

    result = conn.execute(sql)
   

    for row in result:
        print(row[0])
    
    # if not found:
    #     sql = "select count(*) from ppdai"
    #     for row in conn.execute(sql):
    #         cnt_row_new = row[0]
    #     if cnt_row_new != cnt_row:
    #         print "Nothing found in %s rows ... %s" % (cnt_row_new, datetime.datetime.now())
    #         cnt_row = cnt_row_new

    #conn.close()

    sleep_secs = random.uniform(2,3)
    # print "sleep %.2f secs" % sleep_secs
    time.sleep(sleep_secs)
