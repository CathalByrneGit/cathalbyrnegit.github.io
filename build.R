# ════════════════════════════════════════════════════════════════════
# build.R — local + CI build for the housing series
# ════════════════════════════════════════════════════════════════════

# The posts listing and homepage depend on directory contents AND today's
# date (the staged-release filter in posts/index.Rmd re-evaluates Sys.Date()
# on every build). Their own source mtime doesn't change when a post folder
# is added or when the date rolls over, so litedown's 'rebuild: outdated'
# check skips them. Deleting the rendered output forces a guaranteed rebuild —
# more reliable than touching the source, which litedown's cache can ignore.
for (idx in c("posts/index.html", "index.html")) {
  if (file.exists(idx)) {
    file.remove(idx)
    message("Removed ", idx, " to force listing rebuild")
  }
}

# ── Generate tag archive pages ────────────────────────────────────────
# One page per tag (posts/*/index.Rmd `tags:` frontmatter), e.g.
# tags/irish-housing.html, linked from the hashtags on post listings.
# Regenerated fresh on every build so renamed/removed tags don't leave
# stale pages behind; never committed (see .gitignore).
source("R/tags.R")

post_dirs <- list.dirs("posts", recursive = FALSE, full.names = FALSE)
post_dirs <- post_dirs[file.exists(file.path("posts", post_dirs, "index.Rmd"))]

posts_meta <- lapply(post_dirs, function(d) {
  meta <- read_post_meta(file.path("posts", d, "index.Rmd"))
  if (is.null(meta)) return(NULL)
  meta$dir <- d
  meta
})
posts_meta <- Filter(Negate(is.null), posts_meta)

# Staged release: same future-dated filter as posts/index.Rmd and index.Rmd.
post_dates <- as.Date(vapply(posts_meta, `[[`, character(1), "date"))
posts_meta <- posts_meta[is.na(post_dates) | post_dates <= Sys.Date()]

if (dir.exists("tags")) unlink(list.files("tags", full.names = TRUE))
dir.create("tags", showWarnings = FALSE)

all_tags <- sort(unique(unlist(lapply(posts_meta, `[[`, "tags"))))

for (tag in all_tags) {
  slug <- slugify(tag)
  matching <- Filter(function(m) tag %in% m$tags, posts_meta)
  matching <- matching[order(vapply(matching, `[[`, character(1), "date"),
                              decreasing = TRUE)]

  entries <- vapply(matching, function(m) {
    sprintf("- **[%s](/posts/%s/index.html)** &mdash; %s", m$title, m$dir, m$date)
  }, character(1))

  writeLines(c(
    "---",
    sprintf('title: "Tag: %s"', tag),
    "---",
    "",
    "[&larr; All tags](/tags/index.html)",
    "",
    sprintf("# %s", tag),
    "",
    sprintf("%d post%s tagged *%s*.",
            length(matching), if (length(matching) == 1) "" else "s", tag),
    "",
    entries
  ), file.path("tags", paste0(slug, ".Rmd")))
}

writeLines(c(
  "---",
  "title: Tags",
  "---",
  "",
  "# Tags",
  "",
  if (length(all_tags) == 0) "No tagged posts yet." else vapply(all_tags, function(tag) {
    slug <- slugify(tag)
    n <- sum(vapply(posts_meta, function(m) tag %in% m$tags, logical(1)))
    sprintf("- [%s](/tags/%s.html) (%d)", tag, slug, n)
  }, character(1))
), "tags/index.Rmd")

litedown::fuse_site(".")

# litedown writes relative asset paths that break in subdirectories.
# Fix by prepending the correct number of ../ per depth level.
html_files <- list.files(".", pattern = "\\.html$", recursive = TRUE,
                         full.names = TRUE)
html_files <- html_files[!grepl("litedown_", html_files)]

for (f in html_files) {
  rel   <- sub("^\\./", "", f)
  depth <- if (dirname(rel) == ".") 0 else length(strsplit(dirname(rel), "/")[[1]])
  if (depth == 0) next
  
  prefix <- paste(rep("../", depth), collapse = "")
  lines  <- readLines(f, warn = FALSE)
  fixed  <- gsub('(href|src)="assets/', paste0('\\1="', prefix, 'assets/'), lines)
  if (!identical(lines, fixed)) writeLines(fixed, f)
}

message("Build complete.")