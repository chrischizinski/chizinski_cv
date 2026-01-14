# CV System Quick Reference Card

## Daily Commands

### Render Your CV

```bash
# PDF (recommended for printing/submission)
quarto render chizinski_cv.qmd --to pdf

# HTML (great for web/email)
quarto render chizinski_cv.qmd --to html

# Both formats
quarto render chizinski_cv.qmd

# Use R Markdown instead (traditional)
Rscript -e "rmarkdown::render('chizinski_cv.Rmd')"
```

### Update Data

```bash
# Publications (cached 24 hours by default)
Rscript R/pull_citations.R

# Presentations (always processes fresh)
Rscript R/pull_presentations.R

# Force fresh Scholar data (ignore cache)
rm data/scholar_raw_cache.rds && Rscript R/pull_citations.R
```

### Full Workflow

```bash
# Update everything and render
Rscript R/pull_citations.R && \
Rscript R/pull_presentations.R && \
quarto render chizinski_cv.qmd --to pdf
```

## When to Update

| Update Type | Action | Frequency |
|-------------|--------|-----------|
| **New publication** | Nothing needed | Auto-updates from Scholar |
| **New grant** | Edit `data/grants.csv` | As awarded |
| **New student** | Edit `data/students_advised.csv` | As assigned |
| **New presentation** | Edit `data/contributed_presentations.csv` or `invited_presentations.csv` | After presenting |
| **New course** | Edit `data/classes_taught.csv` | Each semester |
| **New service** | Edit relevant CSV in `data/` | As needed |

## Common Scenarios

### "I got a new grant"

1. Open `data/grants.csv`
2. Add new row with: year, authors, title, funder, amount, share
3. Save file
4. Run: `quarto render chizinski_cv.qmd --to pdf`

### "I advised a new student"

1. Open `data/students_advised.csv`
2. Add new row with student details
3. Save file
4. Run: `quarto render chizinski_cv.qmd --to pdf`

### "I gave a presentation"

1. Open `data/contributed_presentations.csv` or `data/invited_presentations.csv`
2. Add new row
3. Save file
4. Run: `Rscript R/pull_presentations.R`
5. Run: `quarto render chizinski_cv.qmd --to pdf`

### "Scholar has my new paper"

1. Just render! (Auto-updates if cache > 24 hours old)
2. OR force refresh: `rm data/scholar_raw_cache.rds && quarto render chizinski_cv.qmd --to pdf`

### "I need a quick update"

```bash
# Within 24 hours of last Scholar pull - super fast!
quarto render chizinski_cv.qmd --to pdf
# Takes ~2 seconds instead of ~60 seconds
```

### "Generate both PDF and HTML"

```bash
quarto render chizinski_cv.qmd
# Creates: chizinski_cv.pdf and chizinski_cv.html
```

## File Locations

### Input Data Files
```
data/
├── education.csv
├── prof_positions.csv
├── grants.csv
├── students_advised.csv
├── grad_committe_service.csv
├── contributed_presentations.csv
├── invited_presentations.csv
├── classes_taught.csv
├── honors_awards.csv
├── journal_service.csv
├── external_review.csv
└── university_service.csv
```

### Output Files
```
chizinski_cv.pdf         # Your CV (PDF)
chizinski_cv.html        # Your CV (HTML)
chizinski_cv.tex         # LaTeX intermediate (if keep-tex: true)
```

### Generated Files (Don't Edit)
```
bib/
├── chizinski_pubs.bib                    # Your papers
├── contributed_presentations.bib         # Your talks
├── invited_presentations.bib             # Your invited talks
└── ...

data/
├── scholar.rds                           # Scholar metrics
├── scholar_raw_cache.rds                 # Scholar API cache
├── presentation_numbers.rds              # Presentation counts
└── inv_presentation_numbers.rds          # Invited talk counts
```

## Customization

### Change Cache Duration

Edit `R/pull_citations.R`, line 8:
```r
cache_hours <- 24  # Change to 48, 72, etc.
```

### Change Filter Year

Edit `chizinski_cv.qmd` or `chizinski_cv.Rmd`, around line 36:
```r
filter_year <- 2019  # Change to your tenure year, etc.
```

### Customize Appearance

PDF styling: Edit `awesome-cv.cls`
HTML styling: Add CSS to YAML header in `chizinski_cv.qmd`

## Troubleshooting

### "Command not found: quarto"
**Fix**: Install Quarto from https://quarto.org

### "Scholar API error"
**Fix**: System will automatically use cache. Or force refresh later:
```bash
rm data/scholar_raw_cache.rds
Rscript R/pull_citations.R
```

### "Missing required columns"
**Fix**: Check error message for column name, add to relevant CSV

### "Rendering is slow"
**Check**: Are you within 24 hours of last render? Should be fast!
**Fix**: Cache might be disabled. Verify `cache: true` in YAML header.

### "Want to use old R Markdown version"
**No problem**: `rmarkdown::render("chizinski_cv.Rmd")` still works!

## Cache Management

### View Cache Status
```bash
ls -lh data/scholar_raw_cache.rds
# Shows file age - if < 24 hours, cache is active
```

### Clear Cache
```bash
rm data/scholar_raw_cache.rds
# Next render will fetch fresh data from Scholar
```

### Cache Behavior
- **< 24 hours old**: Uses cache (fast!)
- **> 24 hours old**: Fetches fresh data (slower)
- **Missing**: Fetches fresh data

## Tips & Tricks

### Batch Update Multiple CSVs
```bash
# Edit multiple data files, then:
quarto render chizinski_cv.qmd --to pdf
# All changes reflected in one render!
```

### Generate Monthly
```bash
# Add to crontab for automatic monthly CV generation
0 9 1 * * cd /path/to/cv && quarto render chizinski_cv.qmd
```

### Compare Versions
```bash
# Generate different versions by changing filter_year
quarto render chizinski_cv.qmd --to pdf -o chizinski_cv_full.pdf
# (after changing filter_year)
quarto render chizinski_cv.qmd --to pdf -o chizinski_cv_recent.pdf
```

### Quick Spell Check
```bash
# Check all CSV files
cat data/*.csv | aspell list | sort -u
```

## Getting Help

1. **Read the guides**:
   - `QUARTO_MIGRATION_GUIDE.md` - Quarto details
   - `IMPROVEMENTS_SUMMARY.md` - What changed

2. **Check error messages**: Now much clearer and actionable!

3. **Quarto documentation**: https://quarto.org/docs/guide/

4. **R Markdown (if using .Rmd)**: https://rmarkdown.rstudio.com/

---

**Most Common Commands** (memorize these!):

```bash
# Render PDF CV
quarto render chizinski_cv.qmd --to pdf

# Force fresh Scholar data
rm data/scholar_raw_cache.rds && Rscript R/pull_citations.R

# Full update and render
Rscript R/pull_citations.R && Rscript R/pull_presentations.R && quarto render chizinski_cv.qmd --to pdf
```
