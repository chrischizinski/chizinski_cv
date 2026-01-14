## Functions

get_current_year <- function(){
  Sys.Date() |> 
        lubridate::ymd() |> 
        year()
}

create_bibtex_key <- function(authors, title, year){
  require(stringr)

  # Common English stopwords (avoids tm package dependency)
  stopwords_en <- c("a", "an", "the", "and", "or", "but", "in", "on", "at", "to",
                    "for", "of", "with", "by", "from", "as", "is", "was", "are",
                    "were", "been", "be", "have", "has", "had", "do", "does", "did",
                    "will", "would", "could", "should", "may", "might", "must",
                    "that", "which", "who", "whom", "this", "these", "those",
                    "it", "its", "they", "their", "we", "our", "you", "your")

  first_author_name <- str_extract(authors, pattern = "\\S+\\s+(\\S+)\\s+\\S+")
  first_author_name <- str_remove(first_author_name, pattern = "^(\\S+\\s+){2}")

  title_words <- str_remove_all(tolower(title), pattern = paste0('\\b', stopwords_en, collapse = ' |'))
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


# Convert presentations to BibTeX format
# Modularizes the repeated code in pull_presentations.R
convert_presentations_to_bibtex <- function(presentations_df,
                                            output_file,
                                            species_pattern = NULL,
                                            species_replace = NULL,
                                            state_pattern = NULL,
                                            state_replace = NULL,
                                            regional_pattern = NULL,
                                            region_replace = NULL,
                                            filter_year = NULL) {
  require(glue)
  require(dplyr)
  require(stringr)

  # BibTeX template
  template <- "@inproceedings{{{key},
                title = {{{title}},
                eventtitle = {{{meeting}},
                author = {{{authors}},
                year = {{{year}}
  }}"

  # Process data
  processed <- presentations_df |>
    mutate(authors = str_replace_all(authors, c("," = " and", "  " = " ")),
           authors = str_remove_all(authors, c("\\."))) |>
    mutate(key = create_bibtex_key(authors, title, year),
           meeting = str_glue("{{{meeting}}}, {{{location}}}"))

  # Apply title case protections if patterns provided
  if (!is.null(state_pattern) && !is.null(state_replace)) {
    processed <- processed |>
      mutate(title = case_when(
        grepl(state_pattern, title, ignore.case = TRUE) ~ str_replace_all(title, state_replace),
        TRUE ~ title
      ))
  }

  if (!is.null(regional_pattern) && !is.null(region_replace)) {
    processed <- processed |>
      mutate(title = case_when(
        grepl(regional_pattern, title, ignore.case = TRUE) ~ str_replace_all(title, region_replace),
        TRUE ~ title
      ))
  }

  if (!is.null(species_pattern) && !is.null(species_replace)) {
    processed <- processed |>
      mutate(title = case_when(
        grepl(species_pattern, title, ignore.case = TRUE) ~ str_replace_all(title, species_replace),
        TRUE ~ title
      ))
  }

  # Filter by year if specified
  if (!is.null(filter_year)) {
    processed <- processed |> filter(year >= filter_year)
  }

  # Generate BibTeX entries
  processed |>
    select(-location) |>
    rowwise() |>
    summarise(bibentry = glue(template)) |>
    ungroup() |>
    pull(bibentry) |>
    write_lines(output_file)

  message(sprintf("Wrote %d BibTeX entries to %s", nrow(processed), basename(output_file)))

  return(nrow(processed))
}

