################################################################################
# TSE candidate data
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
library(pdftools)

################################################################################
# Loading candidate data
################################################################################
# Download files
years <- c('consulta_cand_2000.zip', 'consulta_cand_2004.zip',
           'consulta_cand_2008.zip', 'consulta_cand_2012.zip',
           'consulta_cand_2016.zip')

# Url to look for files
url <- 'http://agencia.tse.jus.br/estatistica/sead/odsele/consulta_cand/'

# Download candidate files
lapply(url, paste0, years) %>%
flatten_chr() %>%
download.file(destfile = paste0('./tse/', years))

# Unzip all files
lapply(paste0('./tse/', list.files('./tse', pattern = "\\.zip")),
       unzip, exdir = './tse/txt')

# Merge files
elections.2010 <- list.files('./tse/txt', pattern = '2000|2004|2008')
elections.2012 <- list.files('./tse/txt', pattern = '2012')
elections.2016 <- list.files('./tse/txt', pattern = '2016')

# Loop and merge before 2010
for(i in 1:length(elections.2010)) {

  # Create path for reading files
  path <- paste0('./tse/txt/', elections.2010[i])

  # Define actions by sequence of files
  if (i == 1) {
    # If looping over first txt file, we want the creation of the dataset
    candidates <- read_delim(path,";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

  } else {
    # If looping over any other file, we should read in the dataset first
    append <- read_delim(path, ";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

    # And then append to 'candidates'
    candidates <- rbind(candidates, append)
  }

  # Print looping information
  print(paste0('Iteration ', i, ' of ', length(elections.2010)))

  # Delete objects at the end of loop
  if (i == length(elections.2010)) {
    # Rename last object
    candidates.2010 <- candidates

    # Delete everything else
    rm(path, i, candidates, append)
  }
}

# Loop and merge files for 2012
for (i in 1:length(elections.2012)) {

  # Create path for reading files
  path <- paste0('./tse/txt/', elections.2012[i])

  # Define actions by sequence of files
  if (i == 1) {
    # If looping over first txt file, we want the creation of the dataset
    candidates <- read_delim(path,";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

  } else {
    # If looping over any other file, we should read in the dataset first
    append <- read_delim(path, ";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

    # And then append to 'candidates'
    candidates <- rbind(candidates, append)
  }

  # Print looping information
  print(paste0('Iteration ', i, ' of ', length(elections.2012)))

  # Delete objects at the end of loop
  if (i == length(elections.2012)) {
    # Rename last object
    candidates.2012 <- candidates

    # Delete everything else
    rm(path, i, candidates, append)
  }
}

# Loop and merge files for 2016
for (i in 1:length(elections.2016)) {

  # Create path for reading files
  path <- paste0('./tse/txt/', elections.2016[i])

  # Define actions by sequence of files
  if (i == 1) {
    # If looping over first txt file, we want the creation of the dataset
    candidates <- read_delim(path,";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

  } else {
    # If looping over any other file, we should read in the dataset first
    append <- read_delim(path, ";", escape_double = FALSE, col_names = FALSE,
      locale = locale(encoding = "Latin1"), trim_ws = TRUE)

    # And then append to 'candidates'
    candidates <- rbind(candidates, append)
  }

  # Print looping information
  print(paste0('Iteration ', i, ' of ', length(elections.2016)))

  # Delete objects at the end of loop
  if (i == length(elections.2016)) {
    # Rename last object
    candidates.2016 <- candidates

    # Delete everything else
    rm(path, i, candidates, append)
  }
}

# Remove useless objects
rm(list = objects(pattern = 'elections|years|url'))

################################################################################
# Wrangling
################################################################################
# Remove all .txt files from disk
unlink('./tse/txt', recursive = TRUE)

# Read codebook pdf and select just the relevant pages where we find variable
# names
codebook <- pdf_text('./tse/LEIAME.pdf')
codebook <- strsplit(codebook, '\n')
codebook <- codebook[4:8]

# 2010 variable names
candidates.2010.columns <- c(codebook[[1]][c(7, 8, 10:14, 19:23, 26:41)],
                             codebook[[2]][c(3:6, 8:16, 18:19)])
# Correct minor problems
candidates.2010.columns     %<>% strsplit('  ') %>% lapply('[[', 1) %>% unlist()
candidates.2010.columns[28] %<>% substr(0, 30)
candidates.2010.columns     %<>% {sub('\\(\\*\\)', '', .)} %>% trimws()

# 2012 variable names
candidates.2012.columns <- c(codebook[[2]][c(23:24, 26:30, 35:39, 42)],
                             codebook[[3]][c(3:16, 18:22, 24:32, 34:35, 37)])
# Correct minor problems
candidates.2012.columns %<>% strsplit('  ') %>% lapply('[[', 1) %>% unlist()
candidates.2012.columns %<>% {sub('\\(\\*\\)', '', .)} %>% trimws()

# 2016 variable names
candidates.2016.columns <- c(codebook[[4]][c(4:5, 7:11, 16:20, 23:37, 39:43)],
                             codebook[[5]][c(4:14, 16:17, 19)])
# Correct minor problems
candidates.2016.columns %<>% strsplit('  ') %>% lapply('[[', 1) %>% unlist()
candidates.2016.columns %<>% {sub('\\(\\*\\)', '', .)} %>% trimws()

# Attribute variable names to datasets
names(candidates.2010) <- candidates.2010.columns
names(candidates.2012) <- candidates.2012.columns
names(candidates.2016) <- candidates.2016.columns

# Append all datasets
candidates.data <- bind_rows(candidates.2010, candidates.2012, candidates.2016)

# Save datasets
save(candidates.2010, file = './tse/candidates.2010.Rda')
save(candidates.2012, file = './tse/candidates.2012.Rda')
save(candidates.2016, file = './tse/candidates.2016.Rda')
save(candidates.data, file = './tse/candidates.data.Rda')

# Remove useless objects
rm(list = objects(pattern = '\\.columns|codebook'))