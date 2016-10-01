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
time.sleep(random.uniform(5,7))

bid_amount = 50
id = "http://invest.ppdai.com/loan/info?id=21108218"
print "bid for %s " % id
loan_id = id.replace("http://invest.ppdai.com/loan/info?id=", "")

base_url = "http://invest.ppdai.com/"
try:
    bid_success = True
    driver.get(id)
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

