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
library(magrittr)  # 1.5
library(tidyverse) # 1.2.1
library(abjutils)  # 0.2.1.9
library(esaj)      # 0.1.2.9
library(ssh)       # 0.2
library(parallel)  # 3.5.1

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

#----------------------------------------------------------------------------#
# Download individual cases for all politicians in database
#----------------------------------------------------------------------------#
# Connect to UNC server to download politician files. You will not be able to
# do this on your own because you are not authorized to use my account.
# Nevertheless, this is necessary for record keeping.
session <- ssh_connect("aa2015@longleaf.unc.edu")

# Upload trial and appeals R scripts to server
scp_upload(session, files   = ".",
                    to      = "/pine/scr/a/a/aa2015/politicians/",
                    verbose = TRUE)

# Issue command to run shell script
ssh_exec_wait(session, c("cd /pine/scr/a/a/aa2015/politicians/",
                         "sbatch tjsp-appeals.sh",
                         "sbatch tjsp-trials.sh"))


# Download files to local folder. Saved in different folder than the git repo.
scp_download(session, files   = "/pine/scr/a/a/aa2015/politicians/first",
                      to      = "../politicians",
                      verbose = TRUE)
scp_download(session, files   = "/pine/scr/a/a/aa2015/politicians/second",
                      to      = "../politicians",
                      verbose = TRUE)

# # Disconnect from server
# ssh_disconnect(session)

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

# Save database for web scraper
save(cases.data, file = "cases.data.Rda")



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


