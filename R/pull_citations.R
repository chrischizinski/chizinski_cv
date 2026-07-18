require(xfun)
xfun::pkg_attach2(c("tidyverse", "scholar", "RefManageR"), message = FALSE)
source(here::here("R", "functions.R"))

id <- 'kAdpcMUAAAAJ'

# Intelligent caching: refresh if cached fetch is > cache_hours old.
# The fetch timestamp is stored INSIDE the RDS (file mtime is unreliable in CI:
# git checkout resets mtimes, making committed caches always look fresh).
# Set FORCE_REFRESH=1 in the environment to bypass the cache.
cache_hours <- 24  # Adjust as needed
scholar_cache_file <- here::here('data', 'scholar.rds')
scholar_raw_cache <- here::here('data', 'scholar_raw_cache.rds')

read_raw_cache <- function(path) {
  if (!file.exists(path)) return(NULL)
  cached <- readRDS(path)
  # Backward compatibility: old caches were a bare data.frame with no timestamp
  if (is.data.frame(cached)) {
    list(fetched_at = as.POSIXct(0, origin = "1970-01-01"), pubz = cached)
  } else {
    cached
  }
}

cached <- read_raw_cache(scholar_raw_cache)
force_refresh <- Sys.getenv("FORCE_REFRESH") == "1"
use_cache <- FALSE

if (!is.null(cached) && !force_refresh) {
  cache_age_hours <- as.numeric(difftime(Sys.time(), cached$fetched_at, units = "hours"))
  if (cache_age_hours < cache_hours) {
    message(sprintf("Using cached Scholar data (%.1f hours old). Set FORCE_REFRESH=1 to force refresh.", cache_age_hours))
    use_cache <- TRUE
  } else {
    message(sprintf("Cache is %.1f hours old (>%d hours). Refreshing from Google Scholar...", cache_age_hours, cache_hours))
  }
} else if (force_refresh) {
  message("FORCE_REFRESH=1 set. Fetching data from Google Scholar...")
} else {
  message("No cache found. Fetching data from Google Scholar...")
}

# Fetch or load publications (tryCatch returns the value, so the fallback
# actually reaches `pubz` -- assignments inside an error handler would not)
pubz <- if (use_cache) {
  cached$pubz
} else {
  tryCatch({
    fetched <- as.data.frame(RefManageR::ReadGS(scholar.id = id, limit = Inf, sort.by.date = TRUE, check.entries = FALSE))
    saveRDS(list(fetched_at = Sys.time(), pubz = fetched), scholar_raw_cache)
    message(sprintf("Successfully fetched %d publications from Google Scholar", nrow(fetched)))
    fetched
  }, error = function(e) {
    if (!is.null(cached)) {
      warning(sprintf("Google Scholar API failed: %s\nUsing cached data instead.", e$message))
      cached$pubz
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
if (!exists("filter_year")) {
  filter_year <- 2020  # keep in sync with params$filter_year in chizinski_cv.qmd
}
as.BibEntry(pubz_fixed |> filter(year >= filter_year)) -> pubz_bibentry_filtered

RefManageR::WriteBib(pubz_bibentry_filtered, file = here::here('bib', 'reduced_chizinski_pubs.bib'),
                     verbose = FALSE, bibstyle = "year", keep_all = TRUE)

# scholar profile metrics with error handling: on failure, keep the existing
# data/scholar.rds (stale metrics) rather than crashing
profile_metrics <- tryCatch({
  scholar_data <- get_profile(id)
  book_chapter_ids <- c("inmFHauC9wsC", "nWoA1JPTheMC", "uAPFzskPt0AC")

  citation_h <- get_publications(id) |>
    filter(!pubid %in% book_chapter_ids) |>
    distinct(pubid, .keep_all = TRUE)

  message(sprintf("Successfully fetched Scholar profile: %d total publications", nrow(citation_h)))
  list(scholar_data = scholar_data, citation_h = citation_h)
}, error = function(e) {
  warning(sprintf("Failed to fetch Scholar profile data: %s", e$message))
  NULL
})

if (!is.null(profile_metrics)) {
  citation_h <- profile_metrics$citation_h
  scholar_data <- profile_metrics$scholar_data

  lifetime_pubs <- nrow(citation_h)
  lifetime_citations <- prettyNum(sum(citation_h$cites), big.mark = ",")

  publications_numbers <- glue::glue("{lifetime_pubs} lifetime.")
  citation_numbers <- glue::glue("{lifetime_citations} lifetime citations.")
  hindex_numbers <- glue::glue("{scholar_data$h_index} and {scholar_data$i10_index} i-10 index.")

  scholar_data_out <- tibble(info = 1:3,
                             results = c(publications_numbers, citation_numbers, hindex_numbers))

  write_rds(scholar_data_out,
            here::here('data', 'scholar.rds'))
} else if (file.exists(scholar_cache_file)) {
  message("Keeping existing data/scholar.rds (metrics may be stale).")
} else {
  stop("No cached Scholar metrics available and API call failed.")
}

message("✓ Citation processing complete!")
