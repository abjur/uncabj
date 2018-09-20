################################################################################
# tse decision parser
# developed by:
# Andre Assumpcao
# andre.assumpcao@gmail.com

# import statements
from bs4 import BeautifulSoup
import codecs
import feather
import glob
import os
import pandas as pd
import re

################################################################################
# initial options
# set working dir
path = '/Users/aassumpcao/OneDrive - University of North Carolina ' + \
  'at Chapel Hill/Documents/Research/2018 TSE'
os.chdir(path)

# list of files to be used in webdriver
files = os.listdir('./html')
files.remove('.DS_Store')

# empty dataset to store tables
sentencingData = [['basicInfo', 'progressionInfo', 'sentencingInfo', 'protNum']]

# loop over all files in html folder
for z in range(0, 996):
    # build path to load files into python
    page = './html/' + files[z]
    # save var with protocolor num
    prot = re.search('[0-9]+', page).group(0)
    # use standard encoding for Portuguese characters or use utf-8 as fallback
    try:
        file = codecs.open(page, 'r', 'cp1252').read()
    except:
        file = codecs.open(page, 'r', 'utf-8').read()
    # call BeautifulSoup to read string as html
    soup = BeautifulSoup(file, 'lxml')
    # find table nodes in html
    tables = soup.find_all('table')
    # loop over each table in html
    for x in range(0, len(tables)):
        # find rows using the 'tr' tag in each table
        rows = tables[x].find_all('tr')
        # find row content for all rows in each table
        text = [y.text for y in rows]
        # join rows so as to have each table in one value
        text = ''.join(text)
        # and add prot number to bservation
        # append tables into one observation
        if x == 0:
            individualTable = [text]
        else:
            individualTable.extend([text])
    # join protocol number at the end of table
    individualTable.append(prot)
    # print loop progresion
    print('HTML ' + str(z + 1) + ' parsed successfully')
    # append to dataset
    sentencingData.append(individualTable)

# call pd to organize list into dataframe
sentencingData = pd.DataFrame(sentencingData)

# save to file
feather.write_dataframe(sentencingData, 'sentencingData.feather')
