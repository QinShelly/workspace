#How To Install Selenium on your Mac OSx
#sudo easy_install selenium
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
from selenium.common.exceptions import NoAlertPresentException
#import selenium
#print selenium.__file__

#compatibility Firefox 45 selenium 2.53.6
#Unfortunately Selenium WebDriver 2.53.6 is not compatible with Firefox 47.0.
driver = webdriver.Firefox()
driver.get("https://ac.ppdai.com/User/Login?redirect=")
try:
    driver.find_element_by_id("UserName").clear()
    driver.find_element_by_id("UserName").send_keys("17717501365")
    driver.find_element_by_id("Password").clear()
    driver.find_element_by_id("Password").send_keys("")
    driver.find_element_by_id("login_btn").click()
finally:
	pass
	#mydriver.quit()