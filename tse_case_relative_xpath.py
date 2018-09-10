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
    electionID = np.select([electionYear == 2004, electionYear == 2008,
                            electionYear == 2012, electionYear == 2016],
                            [14431, 14422, 1699, 2])
    main  = 'http://divulgacandcontas.tse.jus.br/divulga/#/candidato'
    xpath = '//*[contains(concat( " ", @class, " " ), concat( " ", "ng-binding", " " ))]'

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
            visible = EC.presence_of_all_elements_located((By.XPATH, xpath))
            # wait elements have not yet been located
            WebDriverWait(browser, 3).until(visible)
            # if they have, download such elements
            webElem1 = browser.find_elements_by_xpath(xpath)
            # and put them all into one
            data1 = [x.text for x in webElem1]
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
    data.extend(data1)

    # return data
    return data

