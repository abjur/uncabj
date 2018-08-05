#------------------------------------------------------------------------------#
# Script to download trial and appeals court cases from TJ-SP by name
#
# Prepared by Andre Assumpcao
# aassumpcao@unc.edu
#------------------------------------------------------------------------------#
# Remove objects in environment
rm(list = ls())

# Load function to search for names in the TJ-SP database
source("./01_download_parte_aassumpcao.R")

#------------------------------------------------------------------------------#
# Load Packages
#------------------------------------------------------------------------------#
library(magrittr)
library(tidyverse)
library(abjutils)
library(esaj)

#------------------------------------------------------------------------------#
# Load Politician Database
#------------------------------------------------------------------------------#
# # Load csv with names of all candidates in Brazilian elections since 2006
# candidatos <- read_delim("politicos.csv", delim = "|")

# # Filter for SP State and local elections
# candidatos.sp <- candidatos %>%
#   filter(ESTADO == "SP" & ANO_ELEICAO %in% c(2008, 2012, 2016)) %>%
#   distinct(NOME_COMPLETO, .keep_all = TRUE)

# # Save to file
# save(candidatos.sp, file = "candidatos.sp.Rdata")

# Load database
load("./candidatos.sp.Rdata")

#------------------------------------------------------------------------------#
# Download individual cases for all politicians in database
#------------------------------------------------------------------------------#
# Look up and save politicians parts to judicial cases
# Trials Court Cases Directory
# dir.create(path = "./first")
dir.create(path = "./second")

# Define the total number of iterations (= 100 for test purposes)
total <- nrow(candidatos.sp)
# total <- 1000

# # Find trial cases
# for (i in seq(1:total)) {
#   # Keep track of progression
#   print(paste0("Trials: iteration ", i, " of ", total))

#   # Download each trial court case
#   download_cpopg_parte(candidatos.sp[i, "NOME_COMPLETO"],
#                        path = "./first",
#                        nome_completo = TRUE
#   )
# }

# Find appeals cases
for (i in seq(1:total)) {
  # Keep track of progression
  print(paste0("Appeals: iteration ", i, " of ", total))

  # Download each appeals court case
  download_cposg_parte(candidatos.sp[i, "NOME_COMPLETO"],
                       path = "./second",
                       nome_completo = TRUE
  )
}