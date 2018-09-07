################################################################################
# TSE decisions web scraper
# Author:
# Andre Assumpcao
# andre.assumpcao@gmail.com
################################################################################
# Remove everything from sight
rm(list = obects())

# Import statements
library(rvest)
library(magrittr)
library(tidyverse)
library(httr)
library(xml2)

# Functions

################################################################################
# Body
################################################################################
# Get table of State TREs
# Define Parameters for search
url <- 'http://inter03.tse.jus.br/sadpPush/Pesquisa.do'  # webpage
xp1 <- '//select[@name="comboTribunal"]/option'          # xpath for Court
xp2 <- '//select[@name="ufOAB"]/option'                  # xpath for State Bar

# Download Court list
options <- url %>%
  GET(., config(ssl_verifypeer = FALSE)) %>%
  read_html(.) %>%
  xml_find_all(., xp1)

# Check which attribute contains the TRE value
xml_attr(options, 'value')
xml_text(options, 'value')

# Create list of TREs
tre.list <- tibble(name = xml_text(options), value = xml_attr(options, 'value'))


