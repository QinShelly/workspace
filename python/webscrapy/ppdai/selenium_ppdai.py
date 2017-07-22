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
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
import unittest, time, re
import sqlite3
import ppdai.config
import random
import datetime

def getTimes():
    times = 1
    with open('./ppdai/config.py', 'r') as f:
        for line in f.readlines():
            m = re.match("times\W*=\W*(\d+)", line)
            if m: 
                #print line.strip()
                times = m.group(1)
                break
   
    return int(times)

def check_exists_by_xpath(webdriver,xpath):
    try:
        webdriver.find_element_by_xpath(xpath)
    except NoSuchElementException:
        return False
    return True

def getTimesFromBalance():
    times = 1
    try:
        driver.get('http://invest.ppdai.com/account/lend')
        balance = float(driver.find_element_by_xpath("//span[@class='my-ac-ps-yue']").text.replace(u'¥','').replace(',',''))
        print "balance is %s" % balance
        if balance >= 6000:
            times = 3
        elif balance >= 5000:
            times = 2
        elif balance >= 4000:
            times = 1
        else: 
            times = 1
    except (UnexpectedAlertPresentException,NoSuchElementException,TimeoutException) as e:
        print("got Unexpected exception")
    return times
# ==================================================================    
# open Firefox
driver = webdriver.Firefox()

# login
driver.get("http://invest.ppdai.com/account/lend")
driver.implicitly_wait(10)
driver.find_element_by_id("UserName").clear()
time.sleep(random.uniform(1,2))
driver.find_element_by_id("UserName").send_keys(ppdai.config.accounts['username'])
time.sleep(random.uniform(1,2))
driver.implicitly_wait(10)
driver.find_element_by_id("Password").clear()
time.sleep(random.uniform(1,2))
driver.find_element_by_id("Password").send_keys(ppdai.config.accounts['password'])
time.sleep(random.uniform(1,2))
driver.implicitly_wait(10)
driver.find_element_by_id("rememberMe").click()
time.sleep(random.uniform(1,2))
driver.find_element_by_id("login_btn").click()
# must sleep otherwise login status is lost
# need more time for inputing the anti bot code
time.sleep(random.uniform(10,12))

cnt_row = 0
visited_li = []

conn = sqlite3.connect('example.db')
base_url = "http://invest.ppdai.com/"

 # using ppdai.config.times cannot get update to the config when program is running
# times = ppdai.config.times
#times = getTimes()
times = getTimesFromBalance()

while True:
    if random.randint(1,50) == 1:
        print "running %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S')
    # Get item to bid
    view_name = ppdai.config.view_name
   
    #sql = "select id, amount_bid from " + view_name + " where amount_bid > 0 and bid is null"
    sql = "select bidProcess.id,amount_bid from bidProcess join " + view_name + " a on bidProcess.id = a.id where processFlag is null and amount_bid > 0"
    #print sql
    
    found = False

    attempts = 0
    while attempts < 100:
        try:
            result = conn.execute(sql)
            break
        except sqlite3.OperationalError:
            attempts += 1
            print("warning!!! : database locked when querying bid data")
            time.sleep(1)

    for row in result:
        id = row[0]
        if id in visited_li:
            break
        found = True
        visited_li.append(id)

        # update bid to 0
        #sql = "update ppdai set bid = 0 where id = '%s'" % id
        sql = "update bidProcess set processFlag = 0 ,update_bid0_dt=current_timestamp where id = '%s'" % id
        print "set bid %s to 0 start" % id

        attempts = 0  
        while attempts < 100:
            try:
                conn.execute(sql)
                conn.commit()
                print "set bid %s to 0 complete" % id
                break
            except sqlite3.OperationalError:
                attempts += 1
                print("warning!!! : database locked when set bid to 0")
                time.sleep(1)

        print "bid for %s " % id
        loan_id = id.replace("http://invest.ppdai.com/loan/info?id=", "")
        bid_amount = row[1] * times
        if bid_amount > 1000:
            bid_amount = 1000
        print "%s times" % times
        print "%s bid_amount" % bid_amount

        print("page open %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
        bid_success = False

        try:
            driver.get(id)
            time.sleep(random.uniform(0, 1))
            driver.implicitly_wait(10)

            if check_exists_by_xpath(driver, "//img[@src='http://www.ppdaicdn.com/invest/2014/img/detail/mb.jpg']") == False:
                print("clear amount %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
                driver.find_element_by_id(loan_id).click()
                driver.find_element_by_id(loan_id).clear()
                time.sleep(random.uniform(0, 1))
                
                print("update bid amount %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
                driver.find_element_by_id(loan_id).send_keys(bid_amount)
                time.sleep(random.uniform(0, 1))
                driver.implicitly_wait(10)

                print("click submit button %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
                driver.find_element_by_css_selector("input.subBtn.orange").click()
                time.sleep(random.uniform(0, 1))
                element = WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.ID, "btBid"))
                )
                # must sleep otherwise click not work
                time.sleep(random.uniform(2, 3))

                print("click confirm button %s" % datetime.datetime.now().strftime('%b-%d-%y %H:%M:%S'))
                driver.find_element_by_id("btBid").click()
                bid_success = True
            else:
                print("it's already bid by others :(")
        except (NoSuchElementException,UnexpectedAlertPresentException,TimeoutException) as e :
            print("it's already bid by others :(")
            bid_success = False

        if bid_success:
            # update bid to 1
            #sql = "update ppdai set bid = 1 where id = '%s'" % id
            sql = "update bidProcess set processFlag = 1,update_bid1_dt=current_timestamp where id = '%s'" % id
            print "set bid %s to 1 start" % id

            attempts = 0
            while attempts < 100:
                try:
                    conn.execute(sql)
                    conn.commit()
                    print "set bid %s to 1 complete" % id
                    break
                except sqlite3.OperationalError:
                    attempts += 1
                    print("warning!!! : database locked when set bid to 1")
                    time.sleep(1)

        #time.sleep(2)
        times = getTimesFromBalance()

    # if not found:
    #     sql = "select count(*) from ppdai"
    #     for row in conn.execute(sql):
    #         cnt_row_new = row[0]
    #     if cnt_row_new != cnt_row:
    #         print "Nothing found in %s rows ... %s" % (cnt_row_new, datetime.datetime.now())
    #         cnt_row = cnt_row_new

    #conn.close()

    #sleep_secs = random.uniform(2,3)
    # print "sleep %.2f secs" % sleep_secs
    time.sleep(1)
