require(xfun)
xfun::pkg_attach2(c("tidyverse", "scholar", "RefManageR", "tm",  "icons"), message = FALSE)
source(here::here("R", "functions.R"))

id <- 'kAdpcMUAAAAJ'

# Intelligent caching: Check if data is recent (< 24 hours old)
cache_hours <- 24  # Adjust as needed
scholar_cache_file <- here::here('data', 'scholar.rds')
scholar_raw_cache <- here::here('data', 'scholar_raw_cache.rds')
use_cache <- FALSE

if (file.exists(scholar_cache_file) && file.exists(scholar_raw_cache)) {
  cache_age_hours <- as.numeric(difftime(Sys.time(), file.info(scholar_cache_file)$mtime, units = "hours"))
  if (cache_age_hours < cache_hours) {
    message(sprintf("Using cached Scholar data (%.1f hours old). Set cache_hours to force refresh.", cache_age_hours))
    use_cache <- TRUE
  } else {
    message(sprintf("Cache is %.1f hours old (>%d hours). Refreshing from Google Scholar...", cache_age_hours, cache_hours))
  }
} else {
  message("No cache found. Fetching data from Google Scholar...")
}

# Fetch or load publications
if (use_cache) {
  pubz <- readRDS(scholar_raw_cache)
} else {
  tryCatch({
    pubz <- as.data.frame(RefManageR::ReadGS(scholar.id=id, limit = Inf, sort.by.date = TRUE, check.entries = FALSE))
    # Cache the raw data
    saveRDS(pubz, scholar_raw_cache)
    message(sprintf("Successfully fetched %d publications from Google Scholar", nrow(pubz)))
  }, error = function(e) {
    if (file.exists(scholar_raw_cache)) {
      warning(sprintf("Google Scholar API failed: %s\nUsing cached data instead.", e$message))
      pubz <- readRDS(scholar_raw_cache)
    } else {
      stop(sprintf("Google Scholar API failed and no cache available: %s", e$message))
    }
  })
}

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
filter_year <- 2019
as.BibEntry(pubz_fixed |> filter(year >= filter_year)) -> pubz_bibentry_filtered

RefManageR::WriteBib(pubz_bibentry_filtered, file = here::here('bib', 'reduced_chizinski_pubs.bib'),
                     verbose = FALSE, bibstyle = "year", keep_all = TRUE)

# scholar data with error handling
tryCatch({
  scholar_data <- get_profile(id)
  book_chapter_ids <- c("inmFHauC9wsC", "nWoA1JPTheMC", "uAPFzskPt0AC")

  citation_h <- get_publications(id) |>
    filter(!pubid %in% book_chapter_ids) |>
    distinct(pubid, .keep_all = TRUE)

  message(sprintf("Successfully fetched Scholar profile: %d total publications", nrow(citation_h)))
}, error = function(e) {
  warning(sprintf("Failed to fetch Scholar profile data: %s", e$message))
  # If we have cached data, the process can continue with potentially stale metrics
  if (!file.exists(scholar_cache_file)) {
    stop("No cached Scholar data available and API call failed.")
  }
})

reduced_pubs <- nrow(citation_h |> filter(year >= filter_year))
lifetime_pubs <- nrow(citation_h)

lifetime_citations <- prettyNum(sum(citation_h$cites), big.mark = ",")
reduced_citations <- prettyNum(citation_h |> filter(year >= filter_year) |> pull(cites) |> sum(), big.mark = ",")


publications_numbers <- glue::glue("{lifetime_pubs} lifetime.")
citation_numbers <- glue::glue("{lifetime_citations} lifetime citations.")
hindex_numbers <- glue::glue("{scholar_data$h_index} and {scholar_data$i10_index} i-10 index.")

scholar_data_out <- tibble(info = 1:3,
                       results = c(publications_numbers,citation_numbers,hindex_numbers))

write_rds(scholar_data_out,
          here::here('data', 'scholar.rds'))

message("✓ Citation processing complete!")
