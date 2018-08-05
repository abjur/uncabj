#------------------------------------------------------------------------------#
################################ Load Packages #################################
#------------------------------------------------------------------------------#
library(magrittr)
library(tidyverse)
library(abjutils)
library(esaj)

#------------------------------------------------------------------------------#
############################### Define Functions ###############################
#------------------------------------------------------------------------------#
#' Get table with foro information
#'
#' @param inst Number of instancia (1 or 2)
#' @return A tibble with the names and corresponding IDs of foros
#'
#' @export
get_foros <- function(inst) {
  id <- dplyr::case_when(inst == 1L ~ "id_Foro", inst == 2L ~ "id_Seção")
  u  <- dplyr::case_when(inst == 1L ~ "https://esaj.tjsp.jus.br/cpopg/open.do",
                         inst == 2L ~ "https://esaj.tjsp.jus.br/cposg/open.do")
  xp <- stringr::str_glue("//select[@id='{id}']/option")
  options <- u %>%
    httr::GET(httr::config(ssl_verifypeer = FALSE)) %>%
    xml2::read_html() %>%
    xml2::xml_find_all(xp)
  options %>%
    xml2::xml_attr("value")
  tibble::tibble(name  = xml2::xml_text(options),
                 value = xml2::xml_attr(options, "value")
  ) %>%
  dplyr::slice(-1)
}

#' Download 1st degree lawsuits filed in TJSP filtering by part
#'
#' @param parte The part to filter
#' @param path Path to the directory where the lawsuit should be saved
#' @param foro The ID of the foro
#' @param nome_completo Whether or not to search by complete name
#' @return A character vector with the path to the downloaded lawsuits
#'
#' @export
download_cpopg_parte <- function(parte,
                                 path = ".",
                                 foro = "-1",
                                 nome_completo = FALSE) {

  # Download one lawsuit
  download_cpopg_parte_ <- function(page,
                                    url_encoded,
                                    path,
                                    foro,
                                    nome_completo) {

    # Query for GET
    query <- list(
      "paginaConsulta"                      = as.character(page),
      "conversationId"                      = "",
      "dadosConsulta.localPesquisa.cdLocal" = foro,
      "cbPesquisa"                          = "NMPARTE",
      "dadosConsulta.tipoNuProcesso"        = "UNIFICADO",
      "dadosConsulta.valorConsulta"         = url_encoded,
      "uuidCaptcha"                         = ""
    )

    if (nome_completo) query[["chNmCompleto"]] <- "true"

    # Run GET
    f_search <- "https://esaj.tjsp.jus.br/cpopg/search.do" %>%
      httr::GET(query = query, httr::config(ssl_verifypeer = FALSE))

    # Get links for downloads
    links <- f_search %>%
      xml2::read_html() %>%
      xml2::xml_find_all("//*[@class='nuProcesso']//a") %>%
      xml2::xml_attr("href")

    # If links exist, fetch them, otherwise just download the page
    if (length(links) != 0) {

      links <- stringr::str_c("https://esaj.tjsp.jus.br", links)

      f_lwst <- f_search %>%
        xml2::read_html() %>%
        xml2::xml_find_all("//*[@class='nuProcesso']") %>%
        xml2::xml_text() %>%
        stringr::str_extract(abjutils::pattern_cnj()) %>%
        stringr::str_remove_all("[^0-9]") %>%
        stringr::str_c(path, "/", ., ".html")

      purrr::map2(links,
                  f_lwst,
                  ~httr::GET(.x,
                             httr::config(ssl_verifypeer = FALSE),
                             httr::write_disk(.y, TRUE)
                  )
      )
    } else {

      f_lwst <- f_search %>%
        xml2::read_html() %>%
        base::as.character() %>%
        stringr::str_extract(abjutils::pattern_cnj()) %>%
        stringr::str_remove_all("[^0-9]") %>%
        stringr::str_c(path, "/", ., ".html")

      httr::GET("https://esaj.tjsp.jus.br/cpopg/search.do",
                query = query,
                httr::config(ssl_verifypeer = FALSE),
                httr::write_disk(f_lwst, TRUE)
      )
    }
    return(f_lwst)
  }

  # Handle query
  folder      <- stringr::str_remove_all(stringr::str_to_title(parte), " ")
  url_encoded <- stringr::str_replace_all(parte, " ", "+")

  # Normalize path
  path <- stringr::str_c(normalizePath(path), "/", folder)
  dir.create(path, FALSE, TRUE)

  # Query for search
  query <- list(
    "conversationId"                      = "",
    "dadosConsulta.localPesquisa.cdLocal" = foro,
    "cbPesquisa"                          = "NMPARTE",
    "dadosConsulta.tipoNuProcesso"        = "UNIFICADO",
    "dadosConsulta.valorConsulta"         = url_encoded,
    "uuidCaptcha"                         = "")

  if (nome_completo) query[["chNmCompleto"]] <- "true"

  # Run search
  f_search <- "https://esaj.tjsp.jus.br/cpopg/search.do" %>%
    httr::GET(query = query, httr::config(ssl_verifypeer = FALSE))

  if (stringr::str_detect(as.character(f_search), "muitos processos")) {
    warning(paste0("Too many lawsuits found for name ",
                   parte,
                   "! Please narrow your search with 'foro'."
            )
    )
  } else {
    # Get number of pages
    pages <- f_search %>%
      xml2::read_html() %>%
      xml2::xml_find_all("//*[@class='resultadoPaginacao']") %>%
      xml2::xml_text() %>%
      magrittr::extract(1) %>%
      stringr::str_extract("(?<=de )[0-9]+") %>%
      base::as.numeric() %>%
      magrittr::divide_by(25) %>%
      base::ceiling()

    # If theres only one page, just download, otherwise loop
    if (is.na(pages)) {
      results <- download_cpopg_parte_(1,
                                       url_encoded,
                                       path,
                                       foro,
                                       nome_completo)
    } else {
      results <- abjutils::pvec(1:pages,
                                download_cpopg_parte_,
                                url_encoded,
                                path,
                                foro,
                                nome_completo)
      if (class(try(purrr::flatten_chr(results$output))) != "try-error") {
        results <- purrr::flatten_chr(results$output)
      }
    }
    return(results)
  }
}

#' Download 2nd degree lawsuits filed in TJSP filtering by part
#'
#' @param parte The part to filter
#' @param path Path to the directory where the lawsuit should be saved
#' @param foro The ID of the foro
#' @param nome_completo Whether or not to search by complete name
#' @return A character vector with the path to the downloaded lawsuits
#'
#' @export
download_cposg_parte <- function(parte,
                                 path = ".",
                                 foro = "-1",
                                 nome_completo = FALSE) {

  # Download one lawsuit
  download_cposg_parte_ <- function(page,
                                    url_encoded,
                                    path,
                                    foro,
                                    nome_completo) {

    # Query for GET
    query <- list(
      "paginaConsulta"        = as.character(page),
      "conversationId"        = "",
      "localPesquisa.cdLocal" = foro,
      "cbPesquisa"            = "NMPARTE",
      "tipoNuProcesso"        = "UNIFICADO",
      "dePesquisa"            = url_encoded,
      "uuidCaptcha"           = "")

    if (nome_completo) query[["chNmCompleto"]] <- "true"

    # Run GET
    f_search <- "https://esaj.tjsp.jus.br/cposg/search.do" %>%
      httr::GET(query = query, httr::config(ssl_verifypeer = FALSE))

    # Get links for downloads
    links <- f_search %>%
      xml2::read_html() %>%
      xml2::xml_find_all("//*[@class='nuProcesso']//a") %>%
      xml2::xml_attr("href")

    # If links exist, fetch them, otherwise just download the page
    if (length(links) != 0) {

      links <- stringr::str_c("https://esaj.tjsp.jus.br", links)

      f_lwst <- f_search %>%
        xml2::read_html() %>%
        xml2::xml_find_all("//*[@class='nuProcesso']") %>%
        xml2::xml_text() %>%
        stringr::str_extract(abjutils::pattern_cnj()) %>%
        stringr::str_remove_all("[^0-9]") %>%
        stringr::str_c(path, "/", ., ".html")

      purrr::map2(links,
                  f_lwst,
                  ~httr::GET(.x,
                             httr::config(ssl_verifypeer = FALSE),
                             httr::write_disk(.y, TRUE)
                  )
      )

    } else {

      f_lwst <- f_search %>%
        xml2::read_html() %>%
        base::as.character() %>%
        stringr::str_extract(abjutils::pattern_cnj()) %>%
        stringr::str_remove_all("[^0-9]") %>%
        stringr::str_c(path, "/", ., ".html")

      httr::GET("https://esaj.tjsp.jus.br/cposg/search.do",
                query = query,
                httr::config(ssl_verifypeer = FALSE),
                httr::write_disk(f_lwst, TRUE)
      )
    }
    return(f_lwst)
  }

  # Handle query
  folder      <- stringr::str_remove_all(stringr::str_to_title(parte), " ")
  url_encoded <- stringr::str_replace_all(parte, " ", "+")

  # Normalize path
  path <- stringr::str_c(normalizePath(path), "/", folder)
  dir.create(path, FALSE, TRUE)

  # Query for search
  query <- list(
    "conversationId"        = "",
    "localPesquisa.cdLocal" = foro,
    "cbPesquisa"            = "NMPARTE",
    "tipoNuProcesso"        = "UNIFICADO",
    "dePesquisa"            = url_encoded,
    "uuidCaptcha"           = "")

  if (nome_completo) query[["chNmCompleto"]] <- "true"

  # Run search
  f_search <- "https://esaj.tjsp.jus.br/cposg/search.do" %>%
    httr::GET(query = query, httr::config(ssl_verifypeer = FALSE))

  if (stringr::str_detect(as.character(f_search), "muitos processos")) {
    warning(paste0("Too many lawsuits found for name ",
                parte,
                "! Please narrow your search with 'foro'."
            )
    )
  } else {
    # Get number of pages
    pages <- f_search %>%
      xml2::read_html() %>%
      xml2::xml_find_all("//*[@class='resultadoPaginacao']") %>%
      xml2::xml_text() %>%
      magrittr::extract(1) %>%
      stringr::str_extract("(?<=de )[0-9]+") %>%
      base::as.numeric() %>%
      magrittr::divide_by(25) %>%
      base::ceiling()

    # If theres only one page, just download, otherwise loop
    if (is.na(pages)) {
      results <- download_cposg_parte_(1,
                                       url_encoded,
                                       path,
                                       foro,
                                       nome_completo)
    } else {
      results <- abjutils::pvec(1:pages,
                                download_cposg_parte_,
                                url_encoded,
                                path,
                                foro,
                                nome_completo)
      if (class(try(purrr::flatten_chr(results$output))) != "try-error") {
        results <- purrr::flatten_chr(results$output)
      }
    }
    return(results)
  }
}
