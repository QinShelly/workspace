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

# open Firefox
driver = webdriver.Firefox()

# login
driver.get("http://invest.ppdai.com/account/lend")
driver.implicitly_wait(10)
driver.find_element_by_id("UserName").clear()
time.sleep(random.uniform(1,3))
driver.find_element_by_id("UserName").send_keys(ppdai.config.accounts['username'])
time.sleep(random.uniform(1,3))
driver.implicitly_wait(10)
driver.find_element_by_id("Password").clear()
time.sleep(random.uniform(1,3))
driver.find_element_by_id("Password").send_keys(ppdai.config.accounts['password'])
time.sleep(random.uniform(1,3))
driver.implicitly_wait(10)
driver.find_element_by_id("rememberMe").click()
time.sleep(random.uniform(1,3))
driver.find_element_by_id("login_btn").click()
# must sleep otherwise login status is lost
# need more time for inputing the anti bot code
time.sleep(random.uniform(10,12))

cnt_row = 0
visited_li = []

conn = sqlite3.connect('example.db')

while True:
    # Get item to bid
    
    sql = "select id, amount_bid from vw_ppdai where amount_bid > 0 and bid is null"
    found = False

    attempts = 0
    print("in loop %s" % datetime.datetime.now())
    while attempts < 100:
        try:
            result = conn.execute(sql)
            break
        except sqlite3.OperationalError:
            attempts += 1
            print("warning!!! : database locked when querying bid data")
            time.sleep(1)

    for row in result:
        if row[0] in visited_li:
            break
        found = True
        visited_li.append(row[0])

        # update bid to 0
        sql = "update ppdai set bid = 0 where id = '%s'" % row[0]
        print "set bid %s to 0 start" % row[0]

        attempts = 0

        while attempts < 100:
            try:
                conn.execute(sql)
                conn.commit()
                print "set bid %s to 0 complete" % row[0]
                break
            except sqlite3.OperationalError:
                attempts += 1
                print("warning!!! : database locked when set bid to 0")
                time.sleep(1)

        print "bid for %s " % row[0]
        loan_id = row[0].replace("http://invest.ppdai.com/loan/info?id=", "")
        bid_amount = row[1]
        base_url = "http://invest.ppdai.com/"
        try:
            bid_success = True
            driver.get(row[0])
            time.sleep(random.uniform(1, 3))
            driver.implicitly_wait(10)
            driver.find_element_by_id(loan_id).click()
            time.sleep(random.uniform(1, 3))
            driver.find_element_by_id(loan_id).clear()
            time.sleep(random.uniform(1, 3))
            driver.find_element_by_id(loan_id).send_keys(bid_amount)
            time.sleep(random.uniform(1, 3))
            driver.implicitly_wait(10)
            driver.find_element_by_css_selector("input.subBtn.orange").click()
            time.sleep(random.uniform(1, 3))
            element = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, "btBid"))
            )
            # must sleep otherwise click not work
            time.sleep(random.uniform(5, 7))
            driver.find_element_by_id("btBid").click()
        except NoSuchElementException:
            print("it's already bid by others :(")
            bid_success = False

        if bid_success:
            # update bid to 1
            sql = "update ppdai set bid = 1 where id = '%s'" % row[0]
            print "set bid %s to 1 start" % row[0]

            attempts = 0

            while attempts < 100:
                try:
                    conn.execute(sql)
                    conn.commit()
                    print "set bid %s to 1 complete" % row[0]
                    break
                except sqlite3.OperationalError:
                    attempts += 1
                    print("warning!!! : database locked when set bid to 1")
                    time.sleep(1)

        time.sleep(5)
        try:
            driver.get('http://invest.ppdai.com/account/lend')
        except UnexpectedAlertPresentException:
            print("got Unexpected Alert exception")


    
    # if not found:
    #     sql = "select count(*) from ppdai"
    #     for row in conn.execute(sql):
    #         cnt_row_new = row[0]
    #     if cnt_row_new != cnt_row:
    #         print "Nothing found in %s rows ... %s" % (cnt_row_new, datetime.datetime.now())
    #         cnt_row = cnt_row_new

    #conn.close()

    sleep_secs = random.uniform(20,30)
    # print "sleep %.2f secs" % sleep_secs
    time.sleep(sleep_secs)
