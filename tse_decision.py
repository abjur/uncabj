# tse decision number scraper
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
import os
import time
import re
import codecs

# scraper function
def tse_decision(num, state, browser, case = False):
    # search parameters
    # take values in as string
    state = str(state)
    num   = str(num)
    # URL info
    main  = 'http://inter03.tse.jus.br/sadpPush/ExibirDadosProcesso.do?nprot='
    court = '&comboTribunal='
    # xpaths ('andamento' = case flow; 'despacho/sentenças': case decision)
    xpath1   = '//*[contains(@value, "Andam")]'
    xpath2   = '//*[contains(@value, "Despacho")]'
    viewPath = '//*[@value="Visualizar"]'
    errPath  = '//*[text()="Problemas"]'
    # composed URL
    if case == False:
        url = main + num + court + state
    else:
        pass

    # while loop to load page
    while True:
        try:
            # navigate to url
            browser.get(url)
            # check if elements are located
            decision = EC.presence_of_element_located((By.XPATH, viewPath))
            # wait up to 3s for last element to be located
            WebDriverWait(browser, 3).until(decision)
            # when element is found, click on 'andamento', 'despacho', and
            # 'view' so that the browser opens up the information we want
            decision1 = browser.find_element_by_xpath(xpath1).click()
            decision2 = browser.find_element_by_xpath(xpath2).click()
            visualize = browser.find_element_by_xpath(viewPath).click()
            # save inner html to object
            java = 'return document.getElementsByTagName("html")[0].innerHTML'
            html = browser.execute_script(java)
            # create while loop for recheck
            counter = 1
            while len(html) == 0 | counter < 5:
                time.sleep(.5)
                html = browser.execute_script(java)
                counter += 1
                break
            fail = 0
            break
        except StaleElementReferenceException as Exception:
            # if element is not in DOM, return to the top of the loop
            continue
        except TimeoutException as Exception:
            # if we spend too much time looking for elements, return to top of
            # the loop
            error = EC.presence_of_element_located((By.XPATH, errPath))
            if error != '':
                fail = 1
                html = 'Nothing found'
                print('Prot or case ' + str(num) + ' not found')
                break
            continue

    # if all is good, we create the path, directory, and file name
    if not os.path.exists('./html'):
        os.makedirs('./html')

    # different names for files looked up via protocol or case number
    if fail == 1:
        file = './html/error' + str(num) + '.html'
    else:
        if case == False:
            file = './html/prot' + str(num) + '.html'
        else:
            file = './html/case' + str(num) + '.html'

    # save to file
    codecs.open(file, 'w', 'cp1252').write(html)



