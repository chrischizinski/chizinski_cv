# Quarto Migration Guide

## Overview

Your CV system now has two versions:
- **`chizinski_cv.Rmd`** - Original R Markdown version (still functional)
- **`chizinski_cv.qmd`** - New Quarto version (recommended)

## Key Improvements in Quarto Version

### 1. **Multiple Output Formats**
```bash
# Generate PDF (same as before)
quarto render chizinski_cv.qmd --to pdf

# NEW: Generate HTML version
quarto render chizinski_cv.qmd --to html

# Generate both
quarto render chizinski_cv.qmd
```

### 2. **Built-in Caching**
The Quarto version includes `cache: true` in the YAML header, which speeds up subsequent renders by caching R code chunks that haven't changed.

### 3. **Better Error Messages**
Quarto provides clearer, more actionable error messages when things go wrong.

### 4. **Modern YAML Structure**
- Organized `author` and `affiliations` metadata
- Multiple format outputs in single document
- Better documentation structure

### 5. **Active Development**
Quarto is actively developed by Posit (RStudio), ensuring long-term support and new features.

## Installation

If you haven't installed Quarto yet:

```bash
# macOS
brew install quarto

# Or download from https://quarto.org/docs/get-started/
```

## Rendering Your CV

### Option 1: Command Line (Recommended)

```bash
# PDF output (uses awesome-cv template)
quarto render chizinski_cv.qmd --to pdf

# HTML output (interactive, great for web)
quarto render chizinski_cv.qmd --to html

# Both formats
quarto render chizinski_cv.qmd
```

### Option 2: RStudio

1. Open `chizinski_cv.qmd` in RStudio
2. Click the "Render" button (replaces "Knit")
3. Choose output format from dropdown

### Option 3: R Console

```r
quarto::quarto_render("chizinski_cv.qmd", output_format = "pdf")
quarto::quarto_render("chizinski_cv.qmd", output_format = "html")
```

## Workflow Changes

### Data Update Workflow

**Before (R Markdown):**
```r
source("R/pull_citations.R")
source("R/pull_presentations.R")
rmarkdown::render("chizinski_cv.Rmd")
```

**After (Quarto - with caching):**
```bash
# First render: runs all code, including pull scripts
quarto render chizinski_cv.qmd --to pdf

# Subsequent renders: uses cached data (unless data files change)
quarto render chizinski_cv.qmd --to pdf

# Force fresh data pull:
quarto render chizinski_cv.qmd --to pdf --cache-refresh
```

### Cache Behavior

The intelligent caching in `pull_citations.R` works with Quarto's caching:

1. **First run**: Queries Google Scholar, caches for 24 hours
2. **Within 24 hours**: Uses cached Scholar data, Quarto caches R chunks
3. **After 24 hours**: Automatically refreshes Scholar data
4. **Manual refresh**: Delete `data/scholar_raw_cache.rds` to force API call

## HTML Output Benefits

The HTML version offers several advantages:

- **Interactive**: Clickable table of contents
- **Searchable**: Built-in browser search
- **Responsive**: Mobile-friendly design
- **Shareable**: Single self-contained HTML file
- **No LaTeX Required**: Recipients don't need PDF reader

Example use cases:
- Share via email for easy reading
- Post on personal website
- Quick review on mobile devices

## Compatibility Notes

### What Works the Same
- All R code chunks (already using modern `#|` syntax)
- CSV data files and structure
- BibTeX bibliography files
- `vitae` package functions
- LaTeX commands in PDF output

### What's Different
- YAML front matter structure (more organized)
- Can specify format-specific options
- Built-in caching (no manual setup needed)
- Multiple output formats from single source

## Troubleshooting

### Issue: "Quarto not found"
**Solution:** Install Quarto from https://quarto.org

### Issue: "awesome-cv class not found"
**Solution:** Ensure `awesome-cv.cls` is in project directory (it is)

### Issue: "Scholar data outdated"
**Solution:**
```bash
# Delete cache to force refresh
rm data/scholar_raw_cache.rds
quarto render chizinski_cv.qmd --to pdf
```

### Issue: "Want to use R Markdown instead"
**Solution:** The original `chizinski_cv.Rmd` still works! Use whichever you prefer.

## Recommendation

**For PDF CV Generation:**
Both R Markdown and Quarto work identically - choose based on preference.

**For Multiple Formats:**
Use Quarto to generate both PDF and HTML from one source.

**For Future Projects:**
Quarto is recommended as it represents the future of reproducible documents in R.

## Phase 1 Improvements (Apply to Both Versions)

The following improvements work with both .Rmd and .qmd:

1. **Intelligent caching** - Scholar API queries cached for 24 hours
2. **Error handling** - Graceful failures with informative messages
3. **Data validation** - CSV structure checks before processing
4. **Modular functions** - DRY principle applied to BibTeX generation
5. **Better logging** - Clear messages about processing status

These improvements are in the R scripts (`R/pull_citations.R`, `R/pull_presentations.R`, `R/functions.R`), so both document formats benefit from them.

## Next Steps

1. **Try the HTML output**: See how your CV looks in a browser
2. **Test the caching**: Run render multiple times to see speed improvements
3. **Customize as needed**: Both versions are fully customizable
4. **Keep both versions**: No need to delete .Rmd if you're comfortable with it

---

**Questions?** The Quarto documentation is excellent: https://quarto.org/docs/guide/
