################################################################################
# TJ-SP python web scraper
#
# By: Andre Assumpcao
# andre.assumpcao@gmail.com
#
################################################################################
# unix command for running python in the command line from ST3
# python -u

# import statements
from bs4                            import BeautifulSoup
from selenium                       import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui  import WebDriverWait
from selenium.webdriver.support     import expected_conditions as EC
from selenium.webdriver.common.by   import By
from selenium.common.exceptions     import TimeoutException
import re
import numpy as np
import pandas as pd
import os
import time
import pymongo

# Set working directory
os.chdir('/Users/aassumpcao/OneDrive - University of North Carolina at Chapel Hill/Documents/Research/2020 Dissertation/tse')

################################################################################
# define webdriver information so that scraper works
################################################################################
# set incognito option for Chrome Driver
option = webdriver.ChromeOptions()
option.add_argument(' — incognito')

# create driver
browser = webdriver.Chrome()

from tse_case import tse_case
tse_case(270000007695, 96032, 2016)

exit()
# cd '/Users/aassumpcao/OneDrive - University of North Carolina at Chapel Hill/Documents/Research/2020 Dissertation/tse'
python tse_case.py
python -u
################################################################################
# Test 1:  No loop
################################################################################
# parameters for test search
year       = 2016
uniqueID   = 2
sigla_ue   = 96032
sequential = 270000007695
main       = 'http://divulgacandcontas.tse.jus.br/divulga/#/candidato'
cxpath   = '/html/body/div[2]/div[1]/div/div[1]/section[3]/div/div[1]/div[3]/div[1]/div/h3'
pxpath   = '/html/body/div[2]/div[1]/div/div[1]/section[3]/div/div[1]/div[3]/div[2]/div/h3'

# concatenate address
url = [main, str(year), str(uniqueID), str(sigla_ue), str(sequential)]
s   = '/'
url = s.join(url)

# get url
browser.get(url)

# ask browser to wait for elements to load
delay    = 3
webElem1 = WebDriverWait(browser, delay).until(EC.presence_of_element_located((By.XPATH, cxpath)))
webElem2 = WebDriverWait(browser, delay).until(EC.presence_of_element_located((By.XPATH, pxpath)))
webElem1 = browser.find_elements_by_xpath(cxpath)
webElem2 = browser.find_elements_by_xpath(pxpath)
case     = [x.text for x in webElem1]
process  = [x.text for x in webElem2]
data     = [sequential, sigla_ue, year, case[0], process[0]]

print(data)

################################################################################
# Test 2: Loop for loading all files
################################################################################
year       = 2016
uniqueID   = 2
sigla_ue   = 91391
sequential = 110000006799
main       = 'http://divulgacandcontas.tse.jus.br/divulga/#/candidato'
xpath      = '//*[contains(concat( " ", @class, " " ), concat( " ", "ng-binding", " " ))]'

# concatenate address
url = [main, str(year), str(uniqueID), str(sigla_ue), str(sequential)]
s   = '/'
url = s.join(url)

# implicit wait
browser.implicitly_wait(10)
# get url
browser.get(url)

# ask browser to wait for elements to load
delay = 3
time  =
while True:
    try:
        element_present = EC.presence_of_all_elements_located((By.XPATH, xpath))
        WebDriverWait(browser, delay).until(element_present)
        webElem = browser.find_elements_by_xpath(xpath)
        # webElem = WebDriverWait(browser, delay).until(EC.presence_of_all_elements_located((By.XPATH, xpath)))
        break
    except TimeoutException:
        print('revisiting page')

# webElem = browser.find_elements_by_xpath(xpath)
data    = [x.text for x in webElem]
print(data)
