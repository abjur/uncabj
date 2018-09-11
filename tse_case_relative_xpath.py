# tse scraper
# developed by:
# Andre Assumpcao
# andre.assumpcao@gmail.com

# import statements
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions        import TimeoutException
from selenium.common.exceptions        import StaleElementReferenceException
from selenium.webdriver.common.by      import By
from selenium.webdriver.common.keys    import Keys
from selenium.webdriver.support.ui     import WebDriverWait
from selenium.webdriver.support        import expected_conditions as EC
import numpy as np
import pandas as pd
import time
import re

# scraper function
def tse_case(candidateID, electoralUnitID, electionYear, browser):
    # parameters for search
    # unique election ID
    electionID = np.select([electionYear == 2004, electionYear == 2008,
                            electionYear == 2012, electionYear == 2016],
                            [14431, 14422, 1699, 2])
    # base url
    main  = 'http://divulgacandcontas.tse.jus.br/divulga/#/candidato'
    # case and protocol xpaths
    casePath = '//*[contains(@data-ng-if, "numeroProcesso")]'
    protPath = '//*[contains(@href, "nprot")]'

    # concatenate web address
    url = [main, str(electionYear), str(electionID), str(electoralUnitID),
           str(candidateID)]
    s   = '/'
    url = s.join(url)

    # while loop to return to page if there is any error in finding info in DOM
    while True:
        try:
            # navigate to url
            browser.get(url)
            # check if elements are located
            caseVisible = EC.presence_of_element_located((By.XPATH, casePath))
            protVisible = EC.presence_of_element_located((By.XPATH, protPath))
            # wait elements have not yet been located
            WebDriverWait(browser, 3).until(caseVisible)
            WebDriverWait(browser, 3).until(protVisible)
            # if they have, download such elements
            caseElem = browser.find_elements_by_xpath(casePath)
            protElem = browser.find_elements_by_xpath(protPath)
            # and put them all into one
            caseNum = [x.text for x in caseElem]
            protNum = [x.get_attribute('href') for x in protElem]
            # recheck if case number empty or string
            while caseNum[0].isnumeric() == False:
                time.sleep(.5)
                caseNum = [x.text for x in caseElem]
                break
            # recheck if protocol number empty
            while len(protNum[0]) == 0:
                time.sleep(.5)
                protNum = [x.get_attribute('href') for x in protElem]
                break
            # exit loop if successful
            break
        except StaleElementReferenceException as Exception:
            # if element is not in DOM, return to the top of the loop
            continue
        except TimeoutException as Exception:
            # if we spend too much time looking for elements, return to top of
            # the loop
            continue

    # bring together information provided as arguments to function and list
    # found on website
    data = [str(candidateID), str(electoralUnitID), str(electionYear)]
    data.append(caseNum[0])
    data.append(protNum[0])

    # return data
    return data

