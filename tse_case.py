# import statements
import numpy as np
import time
from selenium                       import webdriver
from selenium.common.exceptions     import TimeoutException
from selenium.webdriver.common.by   import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui  import WebDriverWait
from selenium.webdriver.support     import expected_conditions as EC

################################################################################
# function
################################################################################
# scraper definition
def tse_case(sequential, sigla_ue, year):
    # parameters for search
    uniqueID = np.select([year == 2004, year == 2008, year == 2012, year == 2016], [14431, 14422, 1699, 2])
    main     = 'http://divulgacandcontas.tse.jus.br/divulga/#/candidato'
    xpath    = '//*[contains(concat( " ", @class, " " ), concat( " ", "ng-binding", " " ))]'

    # concatenate web address
    url = [main, str(year), str(uniqueID), str(sigla_ue), str(sequential)]
    s   = '/'
    url = s.join(url)

    # set incognito option for Chrome Driver
    option = webdriver.ChromeOptions()
    option.add_argument(' — incognito')

    # create driver
    browser = webdriver.Chrome()

    # define implicit wait time
    # browser.implicitly_wait(60)

    # get url
    browser.get(url)

    # ask browser to wait for all elements to be located or try again
    delay = 1
    while True:
        try:
            element_present = EC.presence_of_all_elements_located((By.XPATH, xpath))
            WebDriverWait(browser, delay).until(element_present)
            break
        except TimeoutException:
            print('not all elements have been found, revisiting page...')

    # pull element content
    time.sleep(1)
    webElem = browser.find_elements_by_xpath(xpath)
    data    = [x.text for x in webElem]

    # close webdriver
    browser.quit()

    # print data
    print(data)


