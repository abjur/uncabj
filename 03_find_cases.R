#------------------------------------------------------------------------------#
# Script to process trial and appeals court cases from TJ-SP
#
# Prepared by Andre Assumpcao
# aassumpcao@unc.edu
#------------------------------------------------------------------------------#
# Remove objects in environment
rm(list = ls())

# Load function to search for names in the TJ-SP database
source("01_download_parte_aassumpcao.R")

#------------------------------------------------------------------------------#
# Load Packages
#------------------------------------------------------------------------------#
library(magrittr)
library(tidyverse)
library(abjutils)
library(esaj)

# #----------------------------------------------------------------------------#
# # Load Politician Database
# #----------------------------------------------------------------------------#
# # Load csv with names of all candidates in Brazilian elections since 2006
# candidatos <- read_delim("politicos.csv", delim = "|")

# # Filter for SP State and local elections
# candidatos.sp <- candidatos %>%
#   filter(ESTADO == "SP" & ANO_ELEICAO %in% c(2008, 2012, 2016)) %>%
#   distinct(NOME_COMPLETO, .keep_all = TRUE)

# # Save to file
# save(candidatos.sp, file = "candidatos.sp.Rdata")

# Load database
load("candidatos.sp.Rdata")

# #----------------------------------------------------------------------------#
# # Download individual cases for all politicians in database
# #----------------------------------------------------------------------------#
# # Look up and save politicians parts to judicial cases
# # Trials Court Cases Directory
# dir.create(path = "./first")

# # Define the total number of iterations (= 100 for test purposes)
# # total <- nrow(candidatos)
# total <- 100

# # Find all cases
# for (i in seq(1:total)) {
#   # Keep track of progression
#   print(paste0("Iteration ", i, " of ", total))

#   # Download each trial court case
#   download_cpopg_parte(candidatos.sp[i, "NOME_COMPLETO"],
#                        path = "./first",
#                        nome_completo = TRUE
#   )
# }

# # Appeals Court Cases Directory
# dir.create(path = "./second")

# # Find all cases
# for (i in seq(1:total)) {
#   # Keep track of progression
#   print(paste0("Iteration ", i, " of ", total))

#   # Download each appeals court case
#   download_cposg_parte(candidatos.sp[i, "NOME_COMPLETO"],
#                        path = "./second",
#                        nome_completo = TRUE
#   )
# }

#------------------------------------------------------------------------------#
# Filter politicians with case at both trial and appeals stages
#------------------------------------------------------------------------------#
# First task is listing out court cases
case.trials  <- list.files("./politicians/first",  recursive = TRUE)
case.appeals <- list.files("./politicians/second", recursive = TRUE)

# Find cases at both stages (using case ID)
cases.both <- subset(case.appeals, case.appeals %in% case.trials)

# Transform cases into dataset
cases.data <- as.tibble(cases.both) %>%
  separate(value, into = c("name", "case.number", "html"), remove = TRUE) %>%
  select(-html)

# Define end for end below
last <- nrow(cases.data)

# Download sequence of decisions
for (i in seq(1:last)) {

  # Keep track of iterations
  iteration <- paste0("Iteration ", i, " of ", last)
  print(iteration)

  # Define structure for file names
  person   <- cases.data[i,]
  folder.1 <- paste0("./politicians/cjpg/", person[1], person[2], "/")
  folder.2 <- paste0("./politicians/cjsg/", person[1], person[2], "/")

  # Download cases
  esaj::download_cjpg(as.character(person[2]), path = folder.1, max_page = 2)
  esaj::download_cjsg(as.character(person[2]), path = folder.2, max_page = 2)

  # Do not clog user's environment
  if (i == last) {rm(iteration, folder.1, folder.2, person)}
}

# Files that can be processed from html to data points
cjpg  <- list.files("./politicians/cjpg", recursive = TRUE, pattern = "page")
cjsg  <- list.files("./politicians/cjsg", recursive = TRUE, pattern = "page")

# Define folder path
dir.1 <- paste0("./politicians/cjpg/", cjpg)
dir.2 <- paste0("./politicians/cjsg/", cjsg)

# Create datasets
candidate.trial   <- esaj::parse_cjpg(dir.1)
candidate.appeals <- esaj::parse_cjsg(dir.2)

# Save datasets
save(candidate.trial,   file = "./politicians/candidate.trial.Rdata")
save(candidate.appeals, file = "./politicians/candidate.appeals.Rdata")


