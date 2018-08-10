#------------------------------------------------------------------------------#
# Script to download trial and appeals court decisions from TJ-SP by name
#
# Prepared by Andre Assumpcao
# aassumpcao@unc.edu
#------------------------------------------------------------------------------#
# Remove objects in environment
rm(list = ls())

#------------------------------------------------------------------------------#
# Load Packages
#------------------------------------------------------------------------------#
library(magrittr)
library(tidyverse)
library(abjutils)
library(esaj)

#------------------------------------------------------------------------------#
# Run web scraper
#------------------------------------------------------------------------------#
# Load database
load("cases.data.Rda")

# Define end for end below
last <- nrow(cases.data)

# Download sequence of decisions
for (i in seq(1:last)) {

  # Keep track of iterations
  iteration <- paste0("Iteration ", i, " of ", last)
  print(iteration)

  # Define structure for file names
  person   <- cases.data[i,]
  folder.2 <- paste0("./cjsg/", person[1], person[2], "/")

  # Download cases
  esaj::download_cjsg(as.character(person[2]), path = folder.2, max_page = 2)

}