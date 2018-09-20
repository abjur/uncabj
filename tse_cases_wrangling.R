################################################################################
# candidate cases and protocols script
# developed by:
# Andre Assumpcao
# andre.assumpcao@gmail.com

################################################################################
# import statements
library(magrittr)
library(tidyverse)
library(feather)

################################################################################
# load data generated at random by another R script and data scraped from the
# TSE website by python script
candidates     <- read_feather('candidates.feather')
candidateCases <- read_feather('candidateCases.feather')

# wrangle column names
names(candidateCases) <- candidateCases[1,]

# work to find last missing cases
candidateCases %>% filter(., is.na(as.numeric(.$caseNum)) == TRUE)
candidates[1000,]

# load remaining cases
remainingCases <- read_feather('remainingCases.feather')

# replace
names(remainingCases) <- candidateCases[1,]

# join
candidateCases %<>%
  filter(., is.na(as.numeric(.$caseNum)) == FALSE) %>%
  rbind(remainingCases)

# remove useless data
rm(remainingCases, candidates)

# mutate URL
candidacyDecisions <- candidateCases %>%
  mutate(protURL = protNum) %>%
  mutate(protNum = str_remove(protNum,
    'http://inter03.tse.jus.br/sadpPush/ExibirDadosProcesso.do\\?nprot=')
  ) %>%
  mutate(protNum = str_remove(protNum, '&comboTribunal=[a-z][a-z]')) %>%
  mutate(state   = str_extract(protURL, '[a-z][a-z]$'))

# save to file
save(candidateCases, file = 'candidateCases.Rda')
save(candidacyDecisions, file = 'candidacyDecisions.Rda')
write_feather(candidacyDecisions, './candidacyDecisions.feather')

# remove unnecessary dataset
rm(candidateCases)

# i now switch to the Python script and download all decisions for this sample
# of 1,000 candidacies. i find seven (7) errors with the code below

# check for errors
decisionErrors <- list.files(path = './html', pattern = 'error') %>%
  str_remove('error') %>%
  str_remove('\\.html') %>%
  match(., candidacyDecisions$protNum)

# find indexes of errors
candidacyDecisions[decisionErrors,]
unlist(candidacyDecisions[decisionErrors, 'caseNum'])

# a manual search for four people has yielded the right protocol and case
# numbers with which to correct the scraper
wrong.protocol <- c('4002002016', '1307302016', '887022016', '737012016')
right.protocol <- c('3169352016', '1292572016', '876992016', '698752016')
right.casenum  <- c('2389820166130224', '0630620166190138', '2742520166240034',
                    '4127720166060006')

# correction of numbers
correct <- match(wrong.protocol, candidacyDecisions$protNum)
candidacyDecisions[correct, 'protNum'] <- right.protocol
candidacyDecisions[correct, 'caseNum'] <- right.casenum

# we are left with 997 observations since 3 are duplicates drawn at random

################################################################################
# work with parser from python
sentencingData <- read_feather('sentencingData.feather')
names(sentencingData) <- sentencingData[1,]
sentencingData %<>% slice(-1) %>% select(protNum, everything())

# parsing table one
# let us first remove the javascript from table 1
javaStart <- lapply(sentencingData[, 2], str_locate, pattern = '\\#hintbox')
javaStart <- javaStart$basicInfo[1:996, 2] - 1
# javaEnd <- lapply(sentencingData[, 2], nchar) %>% unlist()
sentencingData[,2] <- unlist(lapply(sentencingData[,2], str_sub, 1, javaStart))

# create empty columns which will then be filled in by for loop
sentencingData %<>% mutate(judge = NA, subject = NA, stage = NA)

# clean up each observation text text using for loop
for (i in 1:nrow(sentencingData)) {
  # we transform in character, split using special markets, get rid of empty
  # elements, and pull only the relevant information by position
  text <- as.character(sentencingData[i, 2]) %>%
          str_remove_all('\t') %>%
          str_split('\n') %>%
          unlist() %>%
          str_replace_all('( )+', ' ') %>%
          str_trim()
  text <- text[text != '']

  # Then we fill in the columns in the dataset
  if (any(str_detect(text, 'RELATOR')) == TRUE) {
    sentencingData[i, 'judge'] <- text[which(str_detect(text, 'RELATOR')) + 1]
  } else {
    sentencingData[i, 'judge'] <- text[which(str_detect(text, 'ASSUNTO')) - 1]
  }
  sentencingData[i, 'subject'] <- text[which(str_detect(text, 'ASSUNTO')) + 1]
  sentencingData[i, 'stage']   <- text[which(str_detect(text, 'FASE AT')) + 1]
}

# unusual judge information
unusualJudge <- unlist(sentencingData[, 2]) %>%
                str_detect(pattern = 'JUIZ\\(A\\):') %>%
                {which(. == FALSE)}

# correction
correctionsJudge <- lapply(sentencingData[unusualJudge, 5], as.character) %>%
                    unlist() %>%
                    str_remove_all('JU[IÍ]([A-Z])+( )(SUBSTITUTO)?') %>%
                    str_remove_all('(DESEMBARGADOR[A]?) (ELEITORAL)?') %>%
                    str_remove_all('(DOUTOR[A]?)') %>%
                    str_remove_all('-') %>%
                    str_trim()

# replacement
sentencingData[unusualJudge, 'judge'] <- correctionsJudge

# parsing table two
# nothing to parse

# parsing table three
# create empty columns which will then be filled in by for loop
sentencingData %<>% mutate(sentence = NA)

# clean up each observation text text using for loop
for (i in 1:nrow(sentencingData)) {
  # we transform in character, split using special markets, get rid of empty
  # elements, and pull only the relevant information by position
  text <- as.character(sentencingData[i, 4]) %>%
          str_replace_all('\t', ' ') %>%
          str_split('\n') %>%
          unlist() %>%
          str_replace_all('( )+', ' ') %>%
          str_trim()
  text <- text[text != '']

  # now we define parameters for the next search
  searchTerms1 <- '[Rr]egistre-se|[Pp]ublique-se|[Ii]ntime-se|[Cc]omunique-se'
  searchTerms2 <- 'Sentença em [0-9][0-9]'
  searchTerms3 <- 'Despacho em [0-9][0-9]'
  sentence1 <- str_which(text, searchTerms1)
  sentence2 <- str_which(text, searchTerms2)
  sentence3 <- str_which(text, searchTerms3)

  if (length(sentence1) > 0) {
    sentencingData[i, 8] <- paste(text[1:min(sentence1)], collapse = ' ')
  } else if (length(sentence2) == 1){
    sentencingData[i, 8] <- paste(text, collapse = ' ')
  } else if (length(sentence2) > 1) {
    sentencingData[i, 8] <- paste(text[sentence2[1]:sentence2[2]], collapse=' ')
  } else if (length(sentence3) == 1){
    sentencingData[i, 8] <- paste(text, collapse = ' ')
  } else if (length(sentence3) > 1) {
    sentencingData[i, 8] <- paste(text[sentence3[1]:sentence3[2]], collapse=' ')
  } else if (is.na(unlist(sentencingData[i, 3]))) {
    sentencingData[i, 8] <-  'not available'
  } else {
    sentencingData[i, 8] <-  paste(text, collapse = ' ')
  }
}

# save processed data
sentencingData %<>% select(protNum, judge, subject, stage, sentence)
save(sentencingData, file = 'sentencingData.Rda')