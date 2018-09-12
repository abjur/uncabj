# import statements
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions        import TimeoutException
from selenium.webdriver.common.by      import By
from selenium.webdriver.common.keys    import Keys
from selenium.webdriver.support.ui     import WebDriverWait
from selenium.webdriver.support        import expected_conditions as EC
import feather
import os
import numpy as np
import pandas as pd
import pymongo
import time
import re

# initial options
# set working dir
os.chdir('/Users/aassumpcao/OneDrive - University of North Carolina ' +
  'at Chapel Hill/Documents/Research/2018 TSE')

# import scraper
from tse_case_relative_xpath import tse_case

# define chrome options
CHROME_PATH      ='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
CHROMEDRIVER_PATH='/usr/local/bin/chromedriver'
WINDOW_SIZE      ='1920,1080'

# set options
chrome_options = Options()
chrome_options.add_argument('--headless')
chrome_options.add_argument('--window-size=%s'  % WINDOW_SIZE)
chrome_options.binary_location = CHROME_PATH

# open invisible browser
browser = webdriver.Chrome(executable_path = CHROMEDRIVER_PATH,
                           chrome_options  = chrome_options)

# set implicit wait for page load
browser.implicitly_wait(60)

# run scraper for missing cases
case01 = tse_case(60000012916,  13463, 2016, browser)
case02 = tse_case(240000010915, 81604, 2016, browser)
case03 = tse_case(210000008152, 89737, 2016, browser)
case04 = tse_case(270000002647, 96830, 2016, browser)
case05 = tse_case(260000002529, 31453, 2016, browser)
case06 = tse_case(130000043076, 43850, 2016, browser)
case07 = tse_case(250000056497, 63630, 2016, browser)
case08 = tse_case(130000017070, 52450, 2016, browser)
case09 = tse_case(120000002979, 90972, 2016, browser)
case10 = tse_case(250000021351, 63118, 2016, browser)
case11 = tse_case(210000029594, 88862, 2016, browser)
case12 = tse_case(130000044340, 45551, 2016, browser)
case13 = tse_case(180000007798, 10162, 2016, browser)
case14 = tse_case(110000003215, 89796, 2016, browser)
case15 = tse_case(240000011637, 80390, 2016, browser)

# close browser
browser.quit()

# build table of cases
case = [case01, case02, case03, case04, case05, case06, case07, case08, case09,
        case10, case11, case12, case13, case14, case15]

# organize and write to file
remainingCases = pd.DataFrame(case)
feather.write_dataframe(remainingCases, 'remainingCases.feather')

