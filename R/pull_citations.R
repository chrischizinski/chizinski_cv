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
