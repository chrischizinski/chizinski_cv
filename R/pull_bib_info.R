## Functions

get_current_year <- function(){
  Sys.Date() |> 
        lubridate::ymd() |> 
        year()
}

create_bibtex_key <- function(authors, title, year){
  require(stringr)
  require(tm)
  # requires stringr and tm packages

  first_author_name <- str_extract(authors, pattern = "\\S+\\s+(\\S+)\\s+\\S+")
  first_author_name <- str_remove(first_author_name, pattern = "^(\\S+\\s+){2}")

  title_words <- str_remove_all(tolower(title), pattern = paste0('\\b', tm::stopwords('english'), collapse = ' |'))
  first_title_word <- str_extract(title_words, pattern = "\\b\\w+")

  key <- tolower(str_squish(paste0(first_author_name, year, first_title_word)))
  return(key)

}


separate_number_scholar <- function(number){
  volume <- str_squish(str_extract(number, pattern =  "([[:digit:]]+)\\s"))


  issue <- str_extract(number, pattern = "\\((\\d+)\\),")
  issue <- str_remove_all(issue, pattern = "\\(|\\)|\\,")

pgs <- str_extract(number, pattern = "\\b(\\d+)-(\\d+)\\b")

paste(volume, issue, pgs, sep = "|")
}

## pull citations

  require(xfun)
  xfun::pkg_attach2(c("tidyverse", "scholar", "RefManageR", "tm",  "icons"), message = FALSE)
  source("/Users/cchizinski2/Documents/git/chizinski_cv/R/functions.R")
  
  id <- 'kAdpcMUAAAAJ'
  
  pubz <- as.data.frame(RefManageR::ReadGS(scholar.id =id, limit = Inf, sort.by.date = TRUE, check.entries = FALSE))
  
  # edit some citations -----------------------------------------------------
  
  # remove book chapters
  pubz$id <- rownames(pubz)
  book_chapter <- c("graham2021marketing", "gruntorad2021hunter", "stuber2019multivariate")
  
  # correct a few citations
  pubz[pubz$id == "hinrichs2023strangers", c("bibtype", "journal", "pages", "institution", "type")] <- c("Article", "Journal of Fish and Wildlife Management",
                                                                                                         "{https://doi.org/10.3996/JFWM-23-012}", NA_character_, NA_character_)
  pubz[pubz$id == "chizinski2011breeding", c("bibtype", "journal", "pages", "volume","number")] <- c("Article", "Forest Ecology and Management",
                                                                                                     "{1892--1900}", 261, 11)
  pubz[pubz$id == "chizinski2003importance", c("bibtype", "journal", "pages", "institution", "type")] <- c("Article", "Texas Journal of Science",
                                                                                                           "{263--270}", 55, 3)
  
  dir.create(here::here('bib'), showWarnings = FALSE)
  
  ## full merged file 
  
  
  
  as.BibEntry(pubz) -> pubz_full
  
  RefManageR::WriteBib(pubz_full, file = here::here('bib', 'chizinski_full.bib'),
                       verbose = FALSE, bibstyle = "year", keep_all = TRUE)
  
  ## full manuscript file
  
  pubz |> 
    filter(!id %in% book_chapter) |> # remove book chapters, separate bib file
    select(-id) -> pubz_fixed
  
  as.BibEntry(pubz_fixed) -> pubz_bibentry
  
  
  
  RefManageR::WriteBib(pubz_bibentry, file = here::here('bib', 'chizinski_pubs.bib'),
                       verbose = FALSE, bibstyle = "year", keep_all = TRUE)
  
  ## reduced file
  filter_year <- 2020
  as.BibEntry(pubz_fixed |> filter(year >= filter_year)) -> pubz_bibentry_filtered
  
  RefManageR::WriteBib(pubz_bibentry_filtered, file = here::here('bib', 'reduced_chizinski_pubs.bib'),
                       verbose = FALSE, bibstyle = "year", keep_all = TRUE)
  
  # scholar data
  scholar_data <- get_profile(id)
  
  book_chapter_ids <- c("inmFHauC9wsC", "nWoA1JPTheMC", "uAPFzskPt0AC")
  
  citation_h <- get_publications(id) |> 
    filter(!pubid %in% book_chapter_ids) |> 
    distinct(pubid, .keep_all = TRUE)
  
  reduced_pubs <- nrow(citation_h |> filter(year >= filter_year))
  lifetime_pubs <- nrow(citation_h)
  
  lifetime_citations <- prettyNum(sum(citation_h$cites), big.mark = ",")
  reduced_citations <- prettyNum(citation_h |> filter(year >= filter_year) |> pull(cites) |> sum(), big.mark = ",")
  
  
  publications_numbers <- glue::glue("{lifetime_pubs} lifetime and {reduced_pubs} since {filter_year}.")
  citation_numbers <- glue::glue("{lifetime_citations} lifetime and {reduced_citations} citations on manuscripts published since {filter_year}.")
  hindex_numbers <- glue::glue("{scholar_data$h_index} and {scholar_data$i10_index} i-10 index.")
  
  scholar_data_out <- tibble(info = 1:3,
                             results = c(publications_numbers,citation_numbers,hindex_numbers))
  
  write_rds(scholar_data_out,
            here::here('data', 'scholar.rds'))

## pull presentations
  
  require(xfun)
  xfun::pkg_attach2(c("tidyverse", "RefManageR"), message = FALSE)
  source("/Users/cchizinski2/Documents/git/chizinski_cv/R/functions.R")
  
  # contributed presentations clean up -------------------------------------------
  
  # contr_presentations <- read_csv(here::here('data', 'contributed_presentations_fixed.csv'))
  #   
  # contr_presentations |> 
  #   separate_wider_delim(cols = authors, names = c("temp1", "temp2", "temp3"), delim = ",", too_few = "align_start", too_many = "merge" ) |> 
  #   mutate(temp2 = str_trim(temp2),
  #          temp3 = str_trim(temp3),
  #          temp3 = str_remove(temp3, "[.]$"),
  #          temp3 = str_remove(temp3, "and"),
  #          authors = glue::glue("{temp2} {temp1}, {temp3}")) |> 
  #   select(-contains("temp")) |> 
  #   mutate(authors = str_remove(authors, ", NA")) -> temp_csv 
  # temp_csv$authors
  # 
  # write_csv(temp_csv, file = here::here('data', 'contributed_presentations.csv'))
  
  
  # invited presentations clean up -----------------------------------------------
  # invited_presentations <- read_csv(here::here('data', 'invited_presentations_fixed.csv'))
  # 
  # invited_presentations |>
  #   separate_wider_delim(cols = authors, names = c("temp1", "temp2", "temp3"), delim = ",", too_few = "align_start", too_many = "merge" ) |>
  #   mutate(temp2 = str_trim(temp2),
  #          temp3 = str_trim(temp3),
  #          temp3 = str_remove(temp3, "[.]$"),
  #          temp3 = str_remove(temp3, "and"),
  #          authors = glue::glue("{temp2} {temp1}, {temp3}")) |>
  #   select(-contains("temp")) |>
  #   mutate(authors = str_remove(authors, ", NA")) -> temp_csv
  # temp_csv$authors
  # #
  # write_csv(temp_csv, file = here::here('data', 'invited_presentations.csv'))
  
  
  # templates for conversion to bib -----------------------------------------
  
  # Special patterns - modify as necessary - for titles
  species_pattern <- c("Menidia|Morone|Centrarchidae|White Perch|Gizzard Shad|Ambloplites|Cunner|Green Sunfish|Inland Silverside|Largemouth|Spotted|Zebrafish|Common Carp|Slimy Sculpin") 
  
  species_replace <- c("Menidia"="{Menidia}",
                       "Morone"="{Morone}",
                       "Centrarchidae" = "{Centrarchidae}",
                       "White Perch" = "{White Perch}",
                       "Gizzard Shad" = "{Gizzard Shad}",
                       "Ambloplites" = "{Ambloplites}",
                       "Cunner" = "{Cunner}",
                       "Tautogolabrus" = "{Tautogolabrus}",
                       "green sunfish" = "{Green Sunfish}",
                       "inland silverside" = "{Inland Silverside}",
                       "Inland silverside" = "{Inland Silverside}",
                       "largemouth" = "{Largemouth}",
                       "spotted" = "{Spotted}",
                       "bass" = "{Bass}",
                       "zebrafish" = "{Zebrafish}",
                       "common carp" = "{Common Carp}",
                       "slimy sculpin" = "{Slimy Sculpin}")
  
  state_pattern <- c("South Dakota|Nebraska|New Mexico|Texas|Lake Kemp|Minnesota")
  
  state_replace <- c("Nebraska"="{Nebraska}",
                     "South Dakota"="{South Dakota}",
                     "New Mexico" = "{New Mexico}",
                     "Texas" = "{Texas}",
                     "Lake Kemp" = "{Lake Kemp}",
                     "Minnesota" = "{Minnesota}")
  
  regional_pattern <- c("Great Plains|United States|Central Flyway|Altamont Pass Wind Resource Area|North America")
  
  region_replace <- c("Great Plains"="{Great Plains}",
                      "United States"="{United States}",
                      "Central Flyway" = "{Central Flyway}",
                      "Altamont Pass Wind Resource Area" = "{Altamont Pass Wind Resource Area}",
                      "North America" = "{North America}")
  
  # bib template for glue 
  template <- "@inproceedings{{{key},
                title = {{{title}},
                eventtitle = {{{meeting}},
                author = {{{authors}},
                year = {{{year}}
  }}"
  
  # convert contributed to bib  --------------------------------------------------
  contr_presentations <- read_csv(here::here('data', 'contributed_presentations.csv'))
  #
  # contr_presentations |>
  #   select(title) |>
  #   mutate() |>
  #   as.data.frame()
  
  contr_presentations |>
    mutate(authors = str_replace_all(authors, c("," = " and", "  " = " ")),
           authors = str_remove_all(authors, c("\\."))) |>
    mutate(key = create_bibtex_key(authors, title, year),
           meeting = str_glue("{{{meeting}}}, {{{location}}}"),
           title = case_when(grepl(state_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, state_replace),
                             grepl(regional_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, region_replace),
                             grepl(species_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, species_replace),
                             TRUE ~ title)) |>
    select(-location) |>
    rowwise() |>
    summarise(bibentry = glue::glue(template)) |>
    ungroup() |>
    pull(bibentry) |>
    write_lines(here::here('bib', 'contributed_presentations.bib'))
  
  
  # reduced contributed presentations ---------------------------------------
  filter_year <- 2020
  contr_presentations <- read_csv(here::here('data', 'contributed_presentations.csv'))
  lifetime_pres <- nrow(contr_presentations)
  contr_presentations |>
    filter(year >= filter_year) |> 
    mutate(authors = str_replace_all(authors, c("," = " and", "  " = " ")),
           authors = str_remove_all(authors, c("\\."))) |>
    mutate(key = create_bibtex_key(authors, title, year),
           meeting = str_glue("{{{meeting}}}, {{{location}}}"),
           title = case_when(grepl(state_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, state_replace),
                             grepl(regional_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, region_replace),
                             grepl(species_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, species_replace),
                             TRUE ~ title)) |>
    select(-location) |>
    rowwise() |>
    summarise(bibentry = glue::glue(template)) |>
    ungroup() -> reduced_presentation_list
  
  reduced_pres <- nrow(reduced_presentation_list)
  
  reduced_presentation_list |> 
    pull(bibentry) |>
    write_lines(here::here('bib', 'reduced_contributed_presentations.bib'))
  
  presentation_numbers <- glue::glue("{lifetime_pres} lifetime and {reduced_pres} since {filter_year}.")
  
  pres_data_out <- tibble(info = 1,
                          results = c(presentation_numbers))
  write_rds(pres_data_out,
            here::here('data', 'presentation_numbers.rds'))
  # convert invited to bib  ------------------------------------------------------
  invited_presentations <- read_csv(here::here('data', 'invited_presentations.csv'))
  # 
  invited_presentations |>
    mutate(authors = str_replace_all(authors, c("," = " and", "  " = " ")),
           authors = str_remove_all(authors, c("\\."))) |>
    mutate(key = create_bibtex_key(authors, title, year),
           meeting = str_glue("{{{meeting}}}, {{{location}}}"),
           title = case_when(grepl(state_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, state_replace),
                             grepl(regional_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, region_replace),
                             grepl(species_pattern, title,
                                   ignore.case = TRUE) ~str_replace_all(title, species_replace),
                             TRUE ~ title)) |>
    select(-location) |>
    rowwise() |>
    summarise(bibentry = glue::glue(template)) |>
    ungroup() |>
    pull(bibentry) |>
    write_lines(here::here('bib', 'invited_presentations.bib'))