# Future Improvements: Research-Based Recommendations

Based on research of modern CV generation systems in 2025/2026, here are recommended enhancements organized by priority and complexity.

---

## 🔥 High Priority (Quick Wins - Next 2-4 weeks)

### 1. GitHub Actions Automation ⭐⭐⭐

**What**: Automated CV generation on schedule or when data changes

**Benefits**:
- CV automatically updates monthly without manual intervention
- Always have latest version accessible via URL
- Version history tracked automatically

**Implementation**:
```yaml
# .github/workflows/build-cv.yml
name: Build CV
on:
  schedule:
    - cron: '0 9 1 * *'  # 9am on 1st of each month
  push:
    branches: [main]
    paths:
      - 'data/**'
      - 'chizinski_cv.qmd'
  workflow_dispatch:  # Manual trigger

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: r-lib/actions/setup-r@v2
      - uses: quarto-dev/quarto-actions/setup@v2

      - name: Install R packages
        run: |
          install.packages(c('tidyverse', 'vitae', 'here', 'scholar'))
        shell: Rscript {0}

      - name: Render CV
        run: quarto render chizinski_cv.qmd --to pdf

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: cv-pdf
          path: chizinski_cv.pdf

      - name: Release
        uses: softprops/action-gh-release@v1
        if: startsWith(github.ref, 'refs/tags/')
        with:
          files: chizinski_cv.pdf
```

**References**:
- [autoCV GitHub Actions](https://github.com/jitinnair1/autoCV)
- [Awesome CV Builder Action](https://github.com/marketplace/actions/awesome-cv-builder)
- [GitHub Actions Resume Tutorial](https://bas.codes/posts/github-actions-resume/)

**Effort**: 2-3 hours
**Maintenance**: Zero (fully automated)

---

### 2. Multiple CV Variants

**What**: Generate different CV versions from same data

**Benefits**:
- Short CV (2-page) for quick submissions
- Full CV for tenure/promotion
- Industry resume format
- Teaching-focused vs research-focused

**Implementation**:
```yaml
# chizinski_cv_short.qmd
---
title: "Short CV"
params:
  include_all_pubs: false
  years_back: 5
  max_pages: 2
---

# Or use conditional rendering
```r
# In chunks:
if (params$include_all_pubs) {
  bibliography_entries("bib/chizinski_pubs.bib")
} else {
  bibliography_entries("bib/reduced_chizinski_pubs.bib")
}
```

**Effort**: 3-4 hours
**Maintenance**: Low

---

### 3. Metrics Dashboard Section

**What**: Visual summary of academic impact metrics

**Benefits**:
- Professional data visualization
- Quick overview of career trajectory
- Impressive for review committees

**Implementation**:
```r
# Add to CV
## Career Metrics {.page-break-before}

```{r metrics-viz}
library(ggplot2)
library(patchwork)

# Publication timeline
pub_timeline <- citation_h %>%
  count(year) %>%
  ggplot(aes(year, n)) +
  geom_col(fill = "#d00000") +
  labs(title = "Publications per Year", x = NULL, y = "Count") +
  theme_minimal()

# Citations over time
citation_trend <- get_citation_history(id) %>%
  ggplot(aes(year, cites)) +
  geom_line(color = "#d00000", size = 1.5) +
  geom_point(color = "#d00000", size = 3) +
  labs(title = "Citations per Year", x = NULL, y = "Citations") +
  theme_minimal()

# H-index progression
h_index_history <- get_profile(id) %>%
  # Historical h-index data if available
  ...

# Combine plots
pub_timeline | citation_trend
```

**References**:
- [Impactio Visualizations](https://www.impactio.com/blog/build-an-effective-academic-resume-in-minutes)
- [H-Index Visualization](https://digitalagencybook.org/visualizations/h-index/)
- [Research Impact Metrics](https://libraryguides.umassmed.edu/research_impact/metrics_for_cvs_aprs)

**Effort**: 4-6 hours
**Maintenance**: Auto-updates with data

---

## 🚀 Medium Priority (Next 1-2 months)

### 4. ORCID Integration (Replace Google Scholar)

**What**: Pull publications from ORCID instead of/in addition to Scholar

**Benefits**:
- More reliable than Scholar scraping
- Better metadata quality
- Official academic identifier
- No rate limiting issues
- Includes funding data

**Implementation**:
```r
# R/pull_orcid.R
library(rorcid)

# Get publications
orcid_id <- "0000-0001-2345-6789"  # Your ORCID
pubs <- orcid_works(orcid_id)

# Convert to BibTeX
works_list <- pubs$`0000-0001-2345-6789`$works
# Process and convert to BibTeX format

# Get funding (bonus!)
funding <- orcid_fundings(orcid_id)
```

**Alternative Tool**: [ORCID-to-CV Python script](https://codeberg.org/LabABI/ORCID-to-CV)

**References**:
- [ORCID API Documentation](https://info.orcid.org/documentation/integration-and-api-faq/)
- [ORCID-to-CV Tool](https://codeberg.org/LabABI/ORCID-to-CV)

**Effort**: 6-8 hours
**Maintenance**: Low (more stable than Scholar)

---

### 5. Quarto Typst Backend (Modern Alternative)

**What**: Use Typst instead of LaTeX for PDF generation

**Benefits**:
- **Much faster** compilation (seconds vs minutes)
- Simpler syntax than LaTeX
- Better error messages
- Modern font handling
- Easier to customize

**Implementation**:
```yaml
# chizinski_cv_typst.qmd
---
format:
  typst:
    font-family: "Roboto"
    theme: "academic"
---
```

**References**:
- [Quarto + Typst CV Template](https://github.com/christopherkenny/quarto-cv)
- [Typst Documentation](https://typst.app/)

**Effort**: 3-4 hours to convert
**Maintenance**: Same as current

---

### 6. Multi-Format Publishing with Auto-Links

**What**: One-click generation of PDF, HTML, and DOCX with cross-links

**Benefits**:
- PDF for official submissions
- HTML for website/sharing
- DOCX for collaborative editing
- Automatic format links (PDF links to HTML, etc.)

**Implementation**:
```yaml
# chizinski_cv.qmd
---
format:
  html:
    embed-resources: true
  pdf:
    pdf-engine: xelatex
  docx:
    reference-doc: custom-reference.docx
---
```

Quarto 1.3+ automatically adds format links!

**References**:
- [Quarto Multi-Format Publishing](https://www.cynthiahqy.com/posts/cv-html-pdf/)

**Effort**: 2-3 hours
**Maintenance**: Zero (automatic)

---

### 7. Citation Context from Altmetrics

**What**: Add alternative metrics (social media mentions, news coverage, policy citations)

**Benefits**:
- Shows broader impact beyond academia
- Increasingly valued by promotion committees
- Demonstrates public engagement

**Implementation**:
```r
# Using rAltmetric package
library(rAltmetric)

# Get altmetrics for each paper
altmetrics_data <- map(dois, altmetrics)

# Display badges or scores in CV
```

**References**:
- [Altmetrics for CVs](https://libguides.ucd.ie/bibliometrics/researcherimpact)

**Effort**: 4-5 hours
**Maintenance**: Auto-updates with render

---

## 💡 Advanced Features (Next 3-6 months)

### 8. Interactive HTML Dashboard

**What**: Rich HTML version with interactive charts, searchable content, and filtering

**Benefits**:
- Modern, impressive presentation
- Filter publications by year/topic
- Interactive citation graphs
- Mobile-responsive
- Great for personal website

**Implementation**:
```yaml
format:
  html:
    theme: cosmo
    toc: true
    toc-depth: 3
    code-tools: false
    page-layout: full
```

Add JavaScript for interactivity:
```js
// Filter publications by year
function filterPubs(year) { ... }
```

**Effort**: 12-16 hours
**Maintenance**: Low

---

### 9. Automated Publication Categorization

**What**: ML-based automatic categorization of publications by topic

**Benefits**:
- Group papers by research area
- Show evolution of research interests
- Create topic-specific CVs automatically

**Implementation**:
```r
library(textmineR)
library(topicmodels)

# Topic modeling on abstracts
topics <- LDA(abstracts, k = 5)
paper_categories <- topics(topics)

# Add to CV sections
```

**Effort**: 16-20 hours
**Maintenance**: Re-runs automatically

---

### 10. RenderCV-Style YAML System

**What**: Complete rewrite using YAML-first approach like RenderCV

**Benefits**:
- All data in one YAML file
- Extremely portable
- Easy to edit
- Version control friendly
- JSON Schema validation

**Implementation**:
```yaml
# cv_data.yaml
cv:
  name: Christopher Chizinski
  sections:
    - type: education
      entries:
        - degree: Ph.D.
          institution: University of Nebraska
          year: 2008
    - type: publications
      source: orcid
      orcid_id: "0000-..."
```

**References**:
- [RenderCV](https://github.com/rendercv/rendercv)

**Effort**: 40+ hours (complete rewrite)
**Maintenance**: Much simpler long-term

---

### 11. Collaboration Network Visualization

**What**: Visual map of co-author network and collaborations

**Benefits**:
- Shows breadth of collaborations
- Impressive visualization
- Demonstrates network building

**Implementation**:
```r
library(igraph)
library(visNetwork)

# Extract co-authors from publications
coauthors <- extract_coauthors(pubz)

# Build network
net <- graph_from_data_frame(coauthors)

# Visualize
visNetwork(nodes, edges) %>%
  visOptions(highlightNearest = TRUE)
```

**Effort**: 10-12 hours
**Maintenance**: Auto-updates

---

### 12. GitHub Pages Deployment

**What**: Auto-deploy HTML CV to personal website

**Benefits**:
- Always up-to-date online CV
- Professional web presence
- Easy to share URL
- Free hosting

**Implementation**:
```yaml
# Add to GitHub Actions workflow
- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: .
    publish_branch: gh-pages
```

Access at: `https://username.github.io/cv`

**Effort**: 2-3 hours
**Maintenance**: Zero (fully automated)

---

## 📊 Comparison with Current System

| Feature | Current | After Phase 1+2 | With Recommendations |
|---------|---------|-----------------|----------------------|
| **Automation** | Manual run | Manual run | Fully automated |
| **Formats** | PDF only | PDF + HTML | PDF + HTML + DOCX + Web |
| **Data Source** | Scholar (fragile) | Scholar (cached) | ORCID + Scholar |
| **Visualization** | Text only | Text only | Rich graphics + interactive |
| **Variants** | 1 version | 1 version | Multiple variants |
| **Publishing** | Local files | Local files | Auto web deployment |
| **Maintenance** | Medium | Low | Very low |
| **Speed** | Slow | Fast (cached) | Very fast (Typst) |

---

## 📋 Recommended Implementation Roadmap

### Phase 3 (Next Month)
1. **GitHub Actions automation** (2-3 hours) - Highest ROI
2. **Multiple CV variants** (3-4 hours) - High practical value
3. **Metrics visualization** (4-6 hours) - Professional impact

**Total**: ~10-13 hours over 4 weeks
**Benefit**: Fully automated, multiple variants, impressive visuals

### Phase 4 (Months 2-3)
4. **ORCID integration** (6-8 hours) - Better data quality
5. **Multi-format publishing** (2-3 hours) - More flexibility
6. **GitHub Pages deployment** (2-3 hours) - Web presence

**Total**: ~10-14 hours
**Benefit**: More reliable, accessible everywhere, professional website

### Phase 5 (Months 4-6)
7. **Interactive HTML dashboard** (12-16 hours) - Impressive presentation
8. **Altmetrics integration** (4-5 hours) - Show broader impact
9. **Collaboration network viz** (10-12 hours) - Research breadth

**Total**: ~26-33 hours
**Benefit**: Cutting-edge CV, shows impact beyond citations

### Phase 6 (Optional - Long-term)
10. **Typst migration** (3-4 hours) - Faster, modern
11. **RenderCV-style rewrite** (40+ hours) - Ultimate portability
12. **ML categorization** (16-20 hours) - Advanced features

---

## 🎯 My Top 3 Recommendations

Based on effort vs. impact:

### 1. **GitHub Actions Automation** ⭐⭐⭐⭐⭐
- **Effort**: 2-3 hours
- **Impact**: HUGE - set and forget
- **ROI**: Best of all options

### 2. **Metrics Visualization Dashboard** ⭐⭐⭐⭐⭐
- **Effort**: 4-6 hours
- **Impact**: Very impressive for promotion/tenure
- **ROI**: Excellent

### 3. **ORCID Integration** ⭐⭐⭐⭐
- **Effort**: 6-8 hours
- **Impact**: More reliable, future-proof
- **ROI**: Very good

---

## 🔗 Key Resources

**Quarto CV Systems**:
- [schochastics/quarto-cv](https://github.com/schochastics/quarto-cv) - Multiple templates
- [mps9506/quarto-cv](https://github.com/mps9506/quarto-cv) - Academic-focused
- [christopherkenny/quarto-cv](https://github.com/christopherkenny/quarto-cv) - Typst-based

**Automation Tools**:
- [RenderCV](https://github.com/rendercv/rendercv) - YAML to PDF
- [autoCV](https://github.com/jitinnair1/autoCV) - GitHub Actions template
- [Awesome CV Action](https://github.com/marketplace/actions/awesome-cv-builder)

**Data Sources**:
- [ORCID API](https://info.orcid.org/documentation/integration-and-api-faq/)
- [ORCID-to-CV Tool](https://codeberg.org/LabABI/ORCID-to-CV)
- [rorcid R Package](https://cran.r-project.org/web/packages/rorcid/)

**Visualization**:
- [Impactio Platform](https://www.impactio.com/blog/build-an-effective-academic-resume-in-minutes)
- [Research Impact Metrics](https://libraryguides.umassmed.edu/research_impact/metrics_for_cvs_aprs)

**Multi-format Publishing**:
- [Quarto Multi-format Guide](https://www.cynthiahqy.com/posts/cv-html-pdf/)
- [Creating CVs with Quarto](https://blog.schochastics.net/posts/2023-07-17_create-a-cv-with-quarto/)

---

## 💬 Next Steps

Which phase interests you most? I can help implement any of these features:

1. **Quick win**: Set up GitHub Actions (2-3 hours, huge impact)
2. **Visual impact**: Add metrics dashboard (4-6 hours)
3. **Reliability**: Migrate to ORCID (6-8 hours)
4. **Show me examples**: Create proof-of-concept for any feature

Your CV system is already excellent after Phases 1 & 2. These recommendations would make it absolutely state-of-the-art for 2026!
