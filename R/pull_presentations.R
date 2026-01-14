require(xfun)
xfun::pkg_attach2(c("tidyverse", "RefManageR"), message = FALSE)
source(here::here("R", "functions.R"))


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

# Validate contributed presentations file
contrib_file <- here::here('data', 'contributed_presentations.csv')
if (!file.exists(contrib_file)) {
  stop(sprintf("Contributed presentations file not found: %s", contrib_file))
}

contr_presentations <- read_csv(contrib_file, show_col_types = FALSE)

# Validate required columns
required_cols <- c("authors", "title", "year", "meeting", "location")
missing_cols <- setdiff(required_cols, names(contr_presentations))
if (length(missing_cols) > 0) {
  stop(sprintf("Contributed presentations CSV missing required columns: %s",
               paste(missing_cols, collapse = ", ")))
}

message(sprintf("Processing %d contributed presentations...", nrow(contr_presentations)))

# Generate full contributed presentations BibTeX using helper function
lifetime_pres <- convert_presentations_to_bibtex(
  presentations_df = contr_presentations,
  output_file = here::here('bib', 'contributed_presentations.bib'),
  species_pattern = species_pattern,
  species_replace = species_replace,
  state_pattern = state_pattern,
  state_replace = state_replace,
  regional_pattern = regional_pattern,
  region_replace = region_replace
)


# reduced contributed presentations ---------------------------------------
filter_year <- 2019

# Generate reduced (since 2019) contributed presentations BibTeX using helper function
reduced_pres <- convert_presentations_to_bibtex(
  presentations_df = contr_presentations,
  output_file = here::here('bib', 'reduced_contributed_presentations.bib'),
  species_pattern = species_pattern,
  species_replace = species_replace,
  state_pattern = state_pattern,
  state_replace = state_replace,
  regional_pattern = regional_pattern,
  region_replace = region_replace,
  filter_year = filter_year
)

presentation_numbers <- glue::glue("{lifetime_pres} lifetime.")

pres_data_out <- tibble(info = 1,
                           results = c(presentation_numbers))
write_rds(pres_data_out,
          here::here('data', 'presentation_numbers.rds'))
# convert invited to bib  ------------------------------------------------------

# Validate invited presentations file
invited_file <- here::here('data', 'invited_presentations.csv')
if (!file.exists(invited_file)) {
  stop(sprintf("Invited presentations file not found: %s", invited_file))
}

invited_presentations <- read_csv(invited_file, show_col_types = FALSE)

# Validate required columns
missing_cols_invited <- setdiff(required_cols, names(invited_presentations))
if (length(missing_cols_invited) > 0) {
  stop(sprintf("Invited presentations CSV missing required columns: %s",
               paste(missing_cols_invited, collapse = ", ")))
}

message(sprintf("Processing %d invited presentations...", nrow(invited_presentations)))

# Generate full invited presentations BibTeX
convert_presentations_to_bibtex(
  presentations_df = invited_presentations,
  output_file = here::here('bib', 'invited_presentations_full.bib'),
  species_pattern = species_pattern,
  species_replace = species_replace,
  state_pattern = state_pattern,
  state_replace = state_replace,
  regional_pattern = regional_pattern,
  region_replace = region_replace
)

# Generate reduced invited presentations BibTeX
invited_reduced_count <- convert_presentations_to_bibtex(
  presentations_df = invited_presentations,
  output_file = here::here('bib', 'invited_presentations_reduced.bib'),
  species_pattern = species_pattern,
  species_replace = species_replace,
  state_pattern = state_pattern,
  state_replace = state_replace,
  regional_pattern = regional_pattern,
  region_replace = region_replace,
  filter_year = filter_year
)

# Calculate invited presentation statistics
invited_total <- nrow(invited_presentations)

inv_presentation_numbers <- glue::glue("{invited_total} lifetime and {invited_reduced_count} since {filter_year}.")

pres_data_out <- tibble(info = 1,
                        results = c(inv_presentation_numbers))
write_rds(pres_data_out,
          here::here('data', 'inv_presentation_numbers.rds'))

message("✓ Presentation processing complete!")

