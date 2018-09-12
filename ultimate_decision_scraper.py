################################################################################
# import statements
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions        import TimeoutException
from selenium.common.exceptions        import StaleElementReferenceException
from selenium.webdriver.common.by      import By
from selenium.webdriver.common.keys    import Keys
from selenium.webdriver.support.ui     import WebDriverWait
from selenium.webdriver.support        import expected_conditions as EC
import feather
import os
import pandas as pd
import time
import re
import codecs

################################################################################
# initial options
# set working dir
os.chdir('/Users/aassumpcao/OneDrive - University of North Carolina ' +
  'at Chapel Hill/Documents/Research/2018 TSE')

# import scraper
from tse_decision import tse_decision

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

# import test dataset with 1,000 individuals
candidacyDecisions = feather.read_dataframe('candidacyDecisions.feather')

################################################################################
# # run scraper for two individuals
# tse_decision(550892016, 'ma', browser)
# tse_decision(301952016, 'to', browser)
# tse_decision(737012016, 'ce', browser)

################################################################################
# run scraper for the previous sample of 1,000 individuals
for x in range(0, 1000):

    # pull sequential numbers from table
    num   = candidacyDecisions.loc[x, 'protNum']
    state = candidacyDecisions.loc[x, 'state']

    # run scraper capturing browser crash error
    try:
        tse_decision(num, state, browser)
    except:
        browser.quit()
        browser = webdriver.Chrome(executable_path = CHROMEDRIVER_PATH,
                                   chrome_options  = chrome_options)
        # set implicit wait for page load
        browser.implicitly_wait(60)

        # run scraper
        tse_decision(num, state, browser)

    # print information
    print('Iteration ' + str(x + 1) + ' of 1000 successful')

# quit browser
browser.quit()
