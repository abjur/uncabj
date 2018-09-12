################################################################################
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
# import pymongo
import time
import re

################################################################################
# initial options
# set working dir
os.chdir('/Users/aassumpcao/OneDrive - University of North Carolina ' +
  'at Chapel Hill/Documents/Research/2018 TSE')

# import scraper
from tse_case import tse_case

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
candidates = feather.read_dataframe('candidates.feather')

################################################################################
# run scraper for one random individual
tse_case(candidates.loc[9, 'candidateID'], candidates.loc[9, 'electoralUnitID'],
         2016, browser)

################################################################################
# run scraper for 1,000 individuals pulled from random sample of candidates
# create empty dataset to bind results
candidateCases = [['candidateID', 'electoralUnitID', 'electionYear', 'caseNum',
                  'protNum']]

# run scraper for random sample of 1,000 individuals
for x in range(0, 1000):

    # pull sequential numbers from table
    candidateID     = candidates.loc[x, 'candidateID']
    electoralUnitID = candidates.loc[x, 'electoralUnitID']

    # run scraper capturing browser crash error
    try:
        row = tse_case(candidateID, electoralUnitID, 2016, browser)
    except:
        browser.quit()
        browser = webdriver.Chrome(executable_path = CHROMEDRIVER_PATH,
                                   chrome_options  = chrome_options)
        # set implicit wait for page load
        browser.implicitly_wait(60)

        # run scraper
        row = tse_case(candidateID, electoralUnitID, 2016, browser)

    # print information
    print('Iteration ' + str(x + 1) + ' of 1000 successful')

    # bind to dataset
    candidateCases.append(row)

# quit browser
browser.quit()

################################################################################
# wrangle data
# transform list into dataframe
candidateCases = pd.DataFrame(candidateCases)

# save to file
feather.write_dataframe(candidateCases, 'candidateCases.feather')