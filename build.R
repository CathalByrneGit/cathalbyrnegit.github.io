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