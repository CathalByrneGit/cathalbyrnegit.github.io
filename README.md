# cathalbyrnegit.github.io

Personal website and blog, built with [litedown](https://pkg.yihui.org/litedown/).

Live at **[cathalbyrnegit.github.io](https://cathalbyrnegit.github.io)**

---

## Current series: The Architecture of Profit in Irish Housing

An eight-part analysis of Irish property developer profitability, built entirely from primary public data — CSO National Accounts (CNAPA01), Eurostat Structural Business Statistics (sbs\_ovw\_act), CSO land price series (ARA02, RZLPA01), and company filings.

| Post | Title | Date |
|------|-------|------|
| 0 | Overview, methodology and series map | 2026-06-10 |
| 1 | 81 Cents: What Ireland's Developers Actually Keep | 2026-06-10 |
| 2 | Seventh in Europe, and Falling Further Behind | 2026-06-11 |
| 3 | The Permission and the Profit | 2026-06-12 |
| 4 | 61 Representations a Year | 2026-06-13 |
| 5 | €15 Million In, €525 Million Out | 2026-06-14 |
| 6 | Reaping Where They Never Sowed | 2026-06-15 |
| 7 | The Oldest Idea in Economics | 2026-06-16 |

Posts release daily. All figures are independently verifiable from the cited primary sources.

---

## Structure

```
posts/
  YYYY-MM-DD-slug/
    index.Rmd        source
    index.html       rendered (committed)
    data/            frozen primary data (rds + csv mirrors)
assets/
  style.css          site theme
data/
  refresh.R          the only place API calls live — run manually
_litedown.yml        site config
build.R              local and CI build script
```

## Data freeze

All primary data is committed as frozen `.rds` files under `posts/2026-06-10-housing_1/data/`. The site build makes no network calls — published figures cannot change unless `data/refresh.R` is run deliberately, the diff is reviewed, and the result is committed. See `data/MANIFEST.csv` for MD5 hashes and refresh dates.

To refresh:

```r
Rscript data/refresh.R   # from the repo root
# review the printed diff and git diff posts/.../data/csv/
# check post prose still matches, then commit
```

## Local build

```r
install.packages(c("litedown","lt","gglite","xfun","csodata","eurostat",
                   "dplyr","tidyr","stringr","ggplot2","ggrepel","ggtext"))
remotes::install_github("davidsjoberg/ggbump")  # not on CRAN
litedown::fuse_site(".")
```

## Deploy

Pushes to `main` trigger a GitHub Actions build and deploy to `gh-pages`. Posts dated in the future are excluded from each deployment automatically — the full series can sit on `main` and release itself daily at 06:30 UTC.

---
