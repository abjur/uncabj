################################################################################
# TSE cases number web scraper
#
# Description:
# This web scraper extracts the case and protocol numbers from the Brazilian
# Electoral Court website for all local election candidates (mayors and city
# councilors) for elections 2004, 2008, 2012, and 2016. This is just a beta
# (but) working version.
#
# Author:
# Andre Assumpcao
# andre.assumpcao@gmail.com
################################################################################
# Remove everything from environment
rm(list = objects())

# Import statements
library(rvest)
library(magrittr)
library(tidyverse)
library(httr)
library(xml2)
library(RSelenium)

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

################################################################################
# Function
################################################################################
# start docker (do you have docker installed?)
system('docker run -d -p 4445:4444 selenium/standalone-chrome')

# Start remoteServer
remDr <- remoteDriver(remoteServerAddr = 'localhost',
                      port = 4445L,
                      browserName = 'chrome')

# Open broswer
remDr$open(silent = TRUE)

# tse_case function
tse_case <- function(sequential, sigla_ue, year) {
  # Args:
  #   sequential: unique candidate id
  #   sigla_ue:   unique electoral id
  #   year:       election year

  # Returns:
  #   A dataset with candidate id, year, electoral id, case number, and protocol
  #   number

  # Body:
  #   Define url parameters
  year       <- year
  unique.id  <- case_when(year == 2016 ~ 2,     year == 2012 ~ 1699,
                          year == 2008 ~ 14422, year == 2004 ~ 14431)
  sigla_ue   <- sigla_ue
  sequential <- sequential
  main       <- 'http://divulgacandcontas.tse.jus.br/divulga/\\#/candidato'
  url <- paste(main, year, unique.id, sigla_ue, sequential, sep = "/")

  #   Navigate to url
  remDr$navigate(url)

  #   Wait for page to load
  Sys.sleep(.5)

  #   Define xpath for case and protocol numbers
  c.xpath <- paste0('/html/body/div[2]/div[1]/div/div[1]/section[3]/div/',
                    'div[1]/div[3]/div[1]/div/h3')
  p.xpath <- paste0('/html/body/div[2]/div[1]/div/div[1]/section[3]/div/',
                    'div[1]/div[3]/div[2]/div/h3')

  #   Pull case and protocol numbers
  case     <- remDr$findElement('xpath', c.xpath)
  protocol <- remDr$findElement('xpath', p.xpath)

  #   Store in dataset
  data <- tibble(sequential = sequential, sigla_ue = sigla_ue, year = year,
                 case       = unlist(case$getElementText()),
                 protocol   = unlist(protocol$getElementText()))

  #   Return statement
  return(data)
}

################################################################################
# Load Test Dataset
################################################################################
# # Candidates info in 2016
# load('./tse/candidates.2016.Rda')

# # Download function
# candidates.test <- sample_n(candidates.2016, 1)
# View(candidates.test)

# # Empty dataset
# data <- tibble()

# # Run for loop
# for (i in 1:nrow(candidates.test)) {

#   # Define Search parameters
#   politician   <- unlist(candidates.test[i, "SEQUENCIAL_CANDIDATO"])
#   electoral.id <- unlist(candidates.test[i, "SIGLA_UE"])

#   # Build dataset
#   data         <- rbind(data, tse_case(politician, electoral.id, 2016))

#   # Print loop progress
#   print(paste0('Row ', i, ' of ', nrow(candidates.test)))
# }

# stop all docker container
system('docker stop $(docker ps -aq)')

################################################################################
# Pull cases and protocols later
################################################################################
# year       <- 2016
# unique.id  <- case_when(year == 2016 ~ 2,     year == 2012 ~ 1699,
#                         year == 2008 ~ 14422, year == 2004 ~ 14431)
# sigla_ue   <- sigla_ue
# sequential <- sequential
# main       <- 'http://divulgacandcontas.tse.jus.br/divulga/\\#/candidato'
# url <- paste(main, year, unique.id, sigla_ue, sequential, sep = "/")

# library(rdom)


# rdom('/Users/aassumpcao/OneDrive - University of North Carolina at Chapel Hill/Documents/Research/2020 Dissertation/Divulgação de Candidaturas e Contas Eleitorais.htm')

# url <- 'http://divulgacandcontas.tse.jus.br/divulga/\\#/candidato/2016/2/10740/180000004578'

# download_xml(url)



# http://inter03.tse.jus.br/sadpPush/ExibirDadosProcesso.do?nprot=1865092012&comboTribunal=sp

# 9967049-05.2008.6.24.0071


# http://inter03.tse.jus.br/sadpPush/Pesquisa.do?numVersao=1.6&dataVersao=01-12-2012&comboTribunal=sp&acao=pesquisarNumUnico&siglaTribunal=sp&nomeTribunal=TRE-SP&tipoPesquisa=divNumUnico&numProcesso=&numUnicoSequencial=000116193&numUnicoAno=2012&numUnicoOrigem=6260001&numProtocolo=&tipoConsultaProtocolo=sa&nomeParte=&tipoConsultaNomeParte=in&nomeAdvogado=&tipoConsultaNomeAdvogado=in&numOAB=&ufOAB=AC&numOrigem=&anoEleicao=&nomeMunicipio=
# http://inter03.tse.jus.br/sadpPush/Pesquisa.do?numVersao=1.6&dataVersao=01-12-2012&comboTribunal=sp&acao=pesquisarNumUnico&siglaTribunal=sp&nomeTribunal=TRE-SP&tipoPesquisa=divNumUnico&numProcesso=&numUnicoSequencial=000013406&numUnicoAno=2012&numUnicoOrigem=6260121&numProtocolo=&tipoConsultaProtocolo=sa&nomeParte=&tipoConsultaNomeParte=in&nomeAdvogado=&tipoConsultaNomeAdvogado=in&numOAB=&ufOAB=AC&numOrigem=&anoEleicao=&nomeMunicipio=
