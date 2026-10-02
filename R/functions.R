## Functions

create_bibtex_key <- function(authors, title, year){
  require(stringr)

  # Common English stopwords (avoids tm package dependency)
  stopwords_en <- c("a", "an", "the", "and", "or", "but", "in", "on", "at", "to",
                    "for", "of", "with", "by", "from", "as", "is", "was", "are",
                    "were", "been", "be", "have", "has", "had", "do", "does", "did",
                    "will", "would", "could", "should", "may", "might", "must",
                    "that", "which", "who", "whom", "this", "these", "those",
                    "it", "its", "they", "their", "we", "our", "you", "your")

  make_key <- function(a, t, y) {
    a <- str_squish(a)
    first_author <- str_split(a, "\\s+and\\s+")[[1]][1]
    first_author <- str_remove_all(first_author, "[{}]")
    first_author_name <- str_remove_all(stringr::word(first_author, -1), "[^A-Za-z0-9]")
    if (is.na(first_author_name) || first_author_name == "") first_author_name <- "unknown"

    title_clean <- str_replace_all(tolower(t), "[^a-z0-9\\s]", " ")
    title_clean <- str_squish(title_clean)
    title_clean <- str_remove_all(title_clean, pattern = paste0("\\b(", paste(stopwords_en, collapse = "|"), ")\\b"))
    title_clean <- str_squish(title_clean)
    first_title_word <- stringr::word(title_clean, 1)
    if (is.na(first_title_word) || first_title_word == "") first_title_word <- "untitled"

    tolower(str_squish(paste0(first_author_name, y, first_title_word)))
  }

  mapply(make_key, authors, title, year, USE.NAMES = FALSE)
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
    mutate(authors = str_replace_all(authors, c("," = " and", "\\s+" = " ")),
           authors = str_replace(authors, "^and\\s+", ""),
           authors = str_replace(authors, "\\s+and\\s+and\\s+", " and "),
           authors = str_replace(authors, "\\s+and\\s*$", ""),
           authors = str_remove_all(authors, c("\\."))) |>
    mutate(key = create_bibtex_key(authors, title, year),
           meeting = str_glue("{{{meeting}}}, {{{location}}}")) |>
    mutate(key = make.unique(key, sep = "-"))

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


# =============================================================================
# Custom CV Entry Functions for awesome-cv LaTeX class
# These replace vitae::detailed_entries() and vitae::brief_entries()
# which don't work properly with Quarto + custom document classes
# =============================================================================

#' Escape LaTeX special characters in text
#' @param text Character string to escape
#' @return Escaped string safe for LaTeX
escape_latex <- function(text) {
  if (is.na(text) || is.null(text)) return("")
  text <- as.character(text)
  # Escape special LaTeX characters (order matters: backslash is replaced with a
  # placeholder first so braces inserted by later replacements aren't re-escaped)
  text <- gsub("\\", "\007BSLASH\007", text, fixed = TRUE)
  text <- gsub("{", "\\{", text, fixed = TRUE)
  text <- gsub("}", "\\}", text, fixed = TRUE)
  text <- gsub("&", "\\&", text, fixed = TRUE)
  text <- gsub("%", "\\%", text, fixed = TRUE)
  text <- gsub("$", "\\$", text, fixed = TRUE)
  text <- gsub("#", "\\#", text, fixed = TRUE)
  text <- gsub("_", "\\_", text, fixed = TRUE)
  text <- gsub("~", "\\textasciitilde{}", text, fixed = TRUE)
  text <- gsub("^", "\\textasciicircum{}", text, fixed = TRUE)
  text <- gsub("\007BSLASH\007", "\\textbackslash{}", text, fixed = TRUE)
  text
}

#' Convert the LaTeX fragments used in CV data to HTML
#'
#' The CV data and chunk code embed LaTeX (\textbf, \studentname, \vspace,
#' escaped $ % &) for the PDF build. HTML output needs the same text rendered
#' without the LaTeX, so this escapes HTML first and then maps the macros.
#' @param x Character vector
#' @return Character vector of HTML
latex_to_html <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\\\\vspace\\*?\\{[^}]*\\}", "", x)
  x <- gsub("\\\\(textbf|textit|emph)\\{([^}]*)\\}", "<strong>\\2</strong>", x)
  x <- gsub("\\\\studentname\\{([^}]*)\\}", "<strong>\\1</strong>", x)
  x <- gsub("\\\\([$%#_{}])", "\\1", x)
  x <- gsub("\\\\&amp;", "&amp;", x)
  x <- gsub("--", "&ndash;", x, fixed = TRUE)
  trimws(x)
}

#' Bibliography for one .bib file, same style in PDF and HTML
#'
#' Runs pandoc's citeproc on every entry in the .bib with the CV CSL (which
#' sorts newest first), so both formats share one citation style, and bolds
#' the CV owner's name. LaTeX output relies on the CSLReferences environment
#' defined in preamble.tex.
#' @param bib_file Path to a .bib file
#' @param csl Path to the CSL style
#' @return NULL, outputs a raw block (LaTeX or HTML) via cat()
cv_bibliography <- function(bib_file, csl = "csl/apa7-cv-jy-edition.csl") {
  latex_out <- knitr::is_latex_output()

  md <- tempfile(fileext = ".md")
  bib <- tempfile(fileext = ".bib")
  on.exit(unlink(c(md, bib)))
  writeLines(c("---", "nocite: '@*'", "link-citations: false", "---"), md)

  # Pandoc's BibLaTeX reader sentence-cases titles (lowercasing proper nouns,
  # e.g. "Nebraska") and splits institution/publisher on " and ". Double
  # braces keep those fields verbatim, as the old biblatex output did.
  bib_lines <- readLines(here::here(bib_file), warn = FALSE)
  protect <- "^(\\s*(?:title|institution|publisher|organization)\\s*=\\s*)\\{(.*)\\}(,?)\\s*$"
  writeLines(sub(protect, "\\1{{\\2}}\\3", bib_lines, perl = TRUE), bib)

  out <- system2(
    "quarto",
    c("pandoc", shQuote(md), "--citeproc",
      "--bibliography", shQuote(bib),
      "--csl", shQuote(here::here(csl)),
      "-t", if (latex_out) "latex" else "html", "--wrap=none"),
    stdout = TRUE
  )
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
    stop("pandoc citeproc failed for ", bib_file)
  }

  out <- paste(out, collapse = "\n")
  sp <- "(?:\\s|&nbsp;| |~)*"
  name <- paste0("(Chizinski,", sp, "C\\.", "(?:", sp, "J\\.)?)")
  out <- gsub(name, if (latex_out) "\\\\textbf{\\1}" else "<strong>\\1</strong>",
              out, perl = TRUE)

  # Quarto relocates any <div id="refs"> to the end of the document; four
  # bibliographies share that id, so drop it to keep each list in place.
  if (!latex_out) out <- sub('<div id="refs"', "<div", out, fixed = TRUE)

  cat("```{=", if (latex_out) "latex" else "html", "}\n", out, "\n```\n", sep = "")
  invisible(NULL)
}

#' Create CV entries for awesome-cv class
#'
#' Outputs LaTeX cventries environment with cventry commands
#' @param data Data frame with CV entry information
#' @param what Column name for title/institution (required)
#' @param when Column name for date (required)
#' @param with Column name for position/role (optional)
#' @param where Column name for location (optional)
#' @param why Column name or list-column for description items (optional)
#' @param .protect Logical, whether to escape LaTeX special characters (default TRUE)
#' @return NULL, outputs LaTeX directly via cat()
cv_entries <- function(data, what, when, with = NULL, where = NULL, why = NULL, .protect = TRUE) {
  # Capture column names
  what_col <- rlang::enquo(what)
  when_col <- rlang::enquo(when)
  with_col <- if (!missing(with)) rlang::enquo(with) else NULL
  where_col <- if (!missing(where)) rlang::enquo(where) else NULL
  why_col <- if (!missing(why)) rlang::enquo(why) else NULL

  html_out <- knitr::is_html_output()

  # Build output as character vector - one entry per line
  entries <- character()

  # Process each row
  for (i in seq_len(nrow(data))) {
    row <- data[i, ]

    # Extract values
    title <- as.character(rlang::eval_tidy(what_col, row))
    date <- as.character(rlang::eval_tidy(when_col, row))
    position <- if (!is.null(with_col)) as.character(rlang::eval_tidy(with_col, row)) else ""
    location <- if (!is.null(where_col)) as.character(rlang::eval_tidy(where_col, row)) else ""

    # Handle description (why) - simplified to single items
    description <- ""
    description_items <- character()
    if (!is.null(why_col)) {
      why_val <- rlang::eval_tidy(why_col, row)
      if (is.list(why_val)) {
        why_items <- unlist(why_val)
        why_items <- why_items[!is.na(why_items) & why_items != ""]
        if (length(why_items) > 0) {
          description_items <- why_items
          if (.protect) why_items <- sapply(why_items, escape_latex, USE.NAMES = FALSE)
          description <- paste(why_items, collapse = "; ")
        }
      } else if (!is.na(why_val) && why_val != "") {
        description_items <- why_val
        if (.protect) why_val <- escape_latex(why_val)
        description <- why_val
      }
    }

    if (html_out) {
      # HTML twin of \cventry: title | location on the first row,
      # position | date on the second, description below
      title <- latex_to_html(ifelse(is.na(title), "", title))
      date <- latex_to_html(ifelse(is.na(date), "", date))
      position <- latex_to_html(ifelse(is.na(position), "", position))
      location <- latex_to_html(ifelse(is.na(location), "", location))
      items <- latex_to_html(description_items)
      description <- paste(items[items != ""], collapse = "; ")

      row_html <- function(left, right, left_class, right_class) {
        if (left == "" && right == "") return("")
        sprintf('<div class="cv-row"><span class="%s">%s</span><span class="%s">%s</span></div>',
                left_class, left, right_class, right)
      }
      entry <- paste0(
        '<div class="cv-entry">',
        row_html(title, location, "cv-title", "cv-location"),
        row_html(position, date, "cv-position", "cv-date"),
        if (description != "") sprintf('<div class="cv-desc">%s</div>', description) else "",
        "</div>"
      )
      entries <- c(entries, entry)
      next
    }

    # Escape LaTeX if needed
    if (.protect) {
      title <- escape_latex(title)
      date <- escape_latex(date)
      position <- escape_latex(position)
      location <- escape_latex(location)
    }

    # Handle NA values
    title <- ifelse(is.na(title), "", title)
    date <- ifelse(is.na(date), "", date)
    position <- ifelse(is.na(position), "", position)
    location <- ifelse(is.na(location), "", location)

    # Build cventry: {position}{title}{location}{date}{description}
    entry <- sprintf("\\cventry{%s}{%s}{%s}{%s}{%s}",
                     position, title, location, date, description)
    entries <- c(entries, entry)
  }

  if (html_out) {
    cat("```{=html}\n", '<div class="cv-entries">', paste(entries, collapse = "\n"),
        "</div>\n```\n", sep = "")
    return(invisible(NULL))
  }

  # Combine and output
  output <- paste0("\\begin{cventries}\n", paste(entries, collapse = "\n"), "\n\\end{cventries}")
  cat(output)
  invisible(NULL)
}

#' Create brief CV entries for awesome-cv class
#'
#' Simpler version without position/location for grant-style entries
#' @param data Data frame with CV entry information
#' @param what Column name for main content (required)
#' @param when Column name for date (required)
#' @param .protect Logical, whether to escape LaTeX special characters (default TRUE)
#' @return NULL, outputs LaTeX directly via cat()
cv_brief_entries <- function(data, what, when, .protect = TRUE) {
  # Capture column names
  what_col <- rlang::enquo(what)
  when_col <- rlang::enquo(when)

  # Build entries as character vector
  entries <- character()

  # Process each row
  for (i in seq_len(nrow(data))) {
    row <- data[i, ]

    # Extract values
    content <- as.character(rlang::eval_tidy(what_col, row))
    date <- as.character(rlang::eval_tidy(when_col, row))

    # Escape LaTeX if needed
    if (.protect) {
      content <- escape_latex(content)
      date <- escape_latex(date)
    }

    # Handle NA values
    content <- ifelse(is.na(content), "", content)
    date <- ifelse(is.na(date), "", date)

    # Build cventry so the date aligns with the content line
    entry <- sprintf("\\cventry{%s}{}{}{%s}{}", content, date)
    entries <- c(entries, entry)
  }

  # Combine and output
  output <- paste0("\\begin{cventries}\n", paste(entries, collapse = "\n"), "\n\\end{cventries}")
  cat(output)
  invisible(NULL)
}

#' Create CV honors entries for awesome-cv class
#'
#' Uses cvhonors environment for awards/honors
#' @param data Data frame with honors information
#' @param what Column name for award name (required)
#' @param when Column name for year (required)
#' @param with Column name for description/type (optional)
#' @param where Column name for institution (optional)
#' @param .protect Logical, whether to escape LaTeX special characters (default TRUE)
#' @return NULL, outputs LaTeX directly via cat()
cv_honors <- function(data, what, when, with = NULL, where = NULL, .protect = TRUE) {
  # Capture column names
  what_col <- rlang::enquo(what)
  when_col <- rlang::enquo(when)
  with_col <- if (!missing(with)) rlang::enquo(with) else NULL
  where_col <- if (!missing(where)) rlang::enquo(where) else NULL

  # Build entries as character vector
  entries <- character()

  # Process each row
  for (i in seq_len(nrow(data))) {
    row <- data[i, ]

    # Extract values
    award <- as.character(rlang::eval_tidy(what_col, row))
    year <- as.character(rlang::eval_tidy(when_col, row))
    desc <- if (!is.null(with_col)) as.character(rlang::eval_tidy(with_col, row)) else ""
    inst <- if (!is.null(where_col)) as.character(rlang::eval_tidy(where_col, row)) else ""

    # Escape LaTeX if needed
    if (.protect) {
      award <- escape_latex(award)
      year <- escape_latex(year)
      desc <- escape_latex(desc)
      inst <- escape_latex(inst)
    }

    # Handle NA values
    award <- ifelse(is.na(award), "", award)
    year <- ifelse(is.na(year), "", year)
    desc <- ifelse(is.na(desc), "", desc)
    inst <- ifelse(is.na(inst), "", inst)

    # Build cvhonor: {award}{description}{institution}{year}
    entry <- sprintf("\\cvhonor{%s}{%s}{%s}{%s}", award, desc, inst, year)
    entries <- c(entries, entry)
  }

  # Combine and output
  output <- paste0("\\begin{cvhonors}\n", paste(entries, collapse = "\n"), "\n\\end{cvhonors}")
  cat(output)
  invisible(NULL)
}
