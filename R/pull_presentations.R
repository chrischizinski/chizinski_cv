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
