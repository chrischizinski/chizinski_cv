# GitHub Actions Automation Setup Guide

## Overview

Your CV system now includes **automated GitHub Actions workflows** that:

1. ✅ Regenerate your CV **automatically every month**
2. ✅ Rebuild when you update data files or CV source
3. ✅ Allow **manual triggers** anytime
4. ✅ Upload PDFs and HTML to GitHub
5. ✅ Deploy HTML version to **GitHub Pages** (optional)
6. ✅ Create releases for tagged versions

**Result**: Zero-maintenance CV that's always up-to-date!

---

## 🚀 Quick Start

### Step 1: Enable GitHub Actions

1. Push your repository to GitHub (if not already done):
   ```bash
   git add .
   git commit -m "Add GitHub Actions automation"
   git push origin main
   ```

2. GitHub Actions will automatically activate when it detects the workflow files.

### Step 2: Enable GitHub Pages (Optional but Recommended)

1. Go to your GitHub repository
2. Click **Settings** → **Pages**
3. Under "Build and deployment":
   - **Source**: GitHub Actions
   - Click **Save**

4. After the next workflow run, your CV will be live at:
   ```
   https://[your-username].github.io/chizinski_cv/
   ```

### Step 3: First Run

Trigger your first automated build:

**Option A: Push a change**
```bash
# Make any change to data
echo "" >> data/grants.csv
git add data/grants.csv
git commit -m "Trigger workflow"
git push
```

**Option B: Manual trigger**
1. Go to your repo on GitHub
2. Click **Actions** tab
3. Select "Build and Deploy CV"
4. Click **Run workflow** → **Run workflow**

---

## 📋 What Gets Automated

### 1. Scheduled Builds (Monthly)

**When**: 1st of every month at 9am UTC

**What happens**:
- Queries Google Scholar for new publications (respects 24hr cache)
- Processes presentations from CSV files
- Generates PDF and HTML versions
- Uploads to GitHub artifacts
- Deploys to GitHub Pages (if enabled)

**No action needed** - completely automatic!

### 2. Data Change Builds

**When**: You push changes to:
- Any file in `data/`
- `chizinski_cv.qmd` or `chizinski_cv.Rmd`
- Any file in `R/`
- BibTeX files in `bib/`

**What happens**:
- Immediately rebuilds CV with updated data
- Usually completes in 3-5 minutes

### 3. Manual Builds

**When**: You trigger manually (anytime)

**How**:
1. GitHub → **Actions** → **Build and Deploy CV**
2. Click **Run workflow**

**Use cases**:
- Force refresh of Scholar data
- Test workflow changes
- Need immediate update

---

## 📦 Accessing Your CV

### Method 1: GitHub Artifacts (Always Available)

1. Go to **Actions** tab
2. Click on latest successful workflow run
3. Scroll to **Artifacts** section
4. Download:
   - `cv-pdf-XXX` - PDF version
   - `cv-html` - HTML version

**Retention**: 90 days

### Method 2: GitHub Pages (Recommended)

Once enabled, always available at:
```
https://[your-username].github.io/chizinski_cv/
```

**Features**:
- Beautiful landing page
- View HTML or download PDF
- Always shows latest version
- Professional URL to share

### Method 3: GitHub Releases (For versions)

Tag a version to create a permanent release:

```bash
git tag v2026.01
git push origin v2026.01
```

Creates a release with:
- PDF attached
- HTML attached
- Permanent link (never expires)

**Use for**: Tenure packets, major milestones, archival

---

## 🔧 Customization

### Change Schedule

Edit `.github/workflows/build-cv.yml`:

```yaml
# Currently: 1st of month at 9am UTC
schedule:
  - cron: '0 9 1 * *'

# Every Monday at 9am UTC:
schedule:
  - cron: '0 9 * * 1'

# 1st and 15th of month:
schedule:
  - cron: '0 9 1,15 * *'
```

[Cron syntax reference](https://crontab.guru/)

### Add Email Notifications

Add to workflow after build succeeds:

```yaml
- name: Send notification
  if: success()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: ${{ secrets.EMAIL_USERNAME }}
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: CV Updated Successfully
    to: your-email@example.com
    from: GitHub Actions
    body: Your CV has been regenerated and is available at...
```

### Change Artifact Retention

Default: 90 days

```yaml
- name: Upload PDF artifact
  uses: actions/upload-artifact@v4
  with:
    name: cv-pdf-${{ github.run_number }}
    path: chizinski_cv.pdf
    retention-days: 180  # Change to 180 days
```

### Add Slack/Discord Notifications

Use webhook actions to notify team channels:

```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🔍 Monitoring

### View Workflow Status

**GitHub UI**:
1. Go to **Actions** tab
2. See all workflow runs with status:
   - ✅ Green = Success
   - ❌ Red = Failed
   - 🟡 Yellow = In progress

**Status Badge** (Add to README):
```markdown
![CV Build](https://github.com/[username]/chizinski_cv/workflows/Build%20and%20Deploy%20CV/badge.svg)
```

### Check Logs

1. Click on any workflow run
2. Click on job name (e.g., "build-cv")
3. Expand steps to see detailed logs

**Useful for**:
- Debugging failures
- Seeing what changed
- Verifying Scholar data was updated

### GitHub Pages Status

After enabling Pages:
1. **Settings** → **Pages**
2. See deployment status and URL
3. Click **Visit site** to preview

---

## 🐛 Troubleshooting

### Workflow Not Running

**Check**:
1. Workflows enabled? **Settings** → **Actions** → **General**
2. Branch is `main`? Workflows only run on main branch
3. Syntax errors in YAML? Check workflow file

**Fix**:
```bash
# Test workflow syntax locally
brew install actionlint
actionlint .github/workflows/*.yml
```

### Build Failing

**Common causes**:

**1. R Package Installation Failed**
- **Symptom**: Failure at "Install R packages" step
- **Fix**: Add missing package to workflow or update version

**2. Scholar API Error**
- **Symptom**: "Failed to fetch Scholar data"
- **Fix**: Workflow designed to handle this! Uses cached data automatically.

**3. LaTeX Compilation Error**
- **Symptom**: Quarto render failed
- **Fix**: Check CV source for syntax errors locally first

**4. Quarto Version Mismatch**
- **Symptom**: "Unknown option"
- **Fix**: Update Quarto version in workflow:
  ```yaml
  - name: Setup Quarto
    uses: quarto-dev/quarto-actions/setup@v2
    with:
      version: '1.4.550'  # Specify exact version
  ```

### Artifact Download Failed

**Issue**: "Artifact not found"

**Causes**:
- Workflow failed before upload step
- Artifact expired (90 day retention)

**Fix**: Re-run workflow or use GitHub Pages for permanent access

### GitHub Pages Not Deploying

**Checklist**:
1. ✅ Pages enabled in Settings?
2. ✅ Source set to "GitHub Actions"?
3. ✅ Build workflow completed successfully?
4. ✅ Deploy workflow triggered?

**Fix**:
```bash
# Manually trigger deploy
# Go to Actions → Deploy CV to GitHub Pages → Run workflow
```

---

## 💡 Pro Tips

### 1. Test Locally Before Push

Ensure your CV renders locally:
```bash
quarto render chizinski_cv.qmd --to pdf
```

If it works locally, it'll work in Actions!

### 2. Use Workflow Dispatch for Testing

Don't wait for scheduled runs or push changes:
- **Actions** → **Run workflow** → instant test

### 3. Cache Duration Strategy

**For frequent updates**:
```r
# R/pull_citations.R, line 8
cache_hours <- 12  # More frequent Scholar queries
```

**For stability**:
```r
cache_hours <- 168  # Weekly Scholar queries (7 days)
```

### 4. Version Your CV

Create versions for major milestones:
```bash
# For tenure packet
git tag v2026.01-tenure
git push origin v2026.01-tenure

# For grant application
git tag v2026.02-grant-nsf
git push origin v2026.02-grant-nsf
```

Each tag creates a permanent release with attached PDF!

### 5. Multiple CV Variants

Add parallel builds for different versions:

```yaml
- name: Render Full CV
  run: quarto render chizinski_cv.qmd --to pdf -o chizinski_cv_full.pdf

- name: Render Short CV
  run: |
    # Modify filter_year for short version
    quarto render chizinski_cv.qmd --to pdf -o chizinski_cv_short.pdf -P filter_year:2019
```

---

## 📊 Workflow Architecture

### Build Workflow (`build-cv.yml`)

```
Trigger (Schedule/Push/Manual)
         ↓
    Checkout Code
         ↓
    Install R + Quarto
         ↓
    Install R Packages
         ↓
  Update Citations (w/ fallback)
         ↓
  Update Presentations
         ↓
    Render PDF + HTML
         ↓
  Upload Artifacts (90 days)
         ↓
  Create Release (if tagged)
```

**Runtime**: ~3-5 minutes

### Deploy Workflow (`deploy-pages.yml`)

```
Build Workflow Completes
         ↓
    Checkout Code
         ↓
    Install Dependencies
         ↓
    Render HTML Version
         ↓
   Create Landing Page
         ↓
  Deploy to GitHub Pages
```

**Runtime**: ~2-3 minutes

**Total**: 5-8 minutes from trigger to live website!

---

## 🎯 Success Criteria

You'll know it's working when:

✅ **Actions tab** shows green checkmarks
✅ **Artifacts** appear after each run
✅ **GitHub Pages** URL shows your CV
✅ **No manual intervention** needed for monthly updates
✅ **Data changes** auto-trigger rebuilds

---

## 🔗 Additional Resources

**GitHub Actions**:
- [Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Cron Schedule Tool](https://crontab.guru/)

**R + Quarto in Actions**:
- [r-lib/actions](https://github.com/r-lib/actions)
- [quarto-dev/quarto-actions](https://github.com/quarto-dev/quarto-actions)

**GitHub Pages**:
- [Pages Documentation](https://docs.github.com/en/pages)
- [Custom Domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

---

## 🎊 You're Done!

Your CV system is now **fully automated**:

- ✅ Updates monthly automatically
- ✅ Rebuilds on data changes
- ✅ Available via permanent URL
- ✅ Zero maintenance required

**Next Steps**:
1. Enable GitHub Pages for public URL
2. Add status badge to README
3. Create your first tagged release
4. Share your GitHub Pages URL!

**Questions?** Check the troubleshooting section or open an issue on GitHub.

---

## 📅 Maintenance Schedule

| Task | Frequency | Automated? |
|------|-----------|------------|
| Update publications | Monthly | ✅ Yes |
| Regenerate CV | Monthly | ✅ Yes |
| Check workflow status | As needed | Manual |
| Update R packages | Yearly | Manual (1 hour) |
| Review/update data | As needed | Manual |

**Time investment**: ~1 hour/year for maintenance 🎉
