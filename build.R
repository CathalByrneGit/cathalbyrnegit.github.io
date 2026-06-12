# The posts listing depends on the directory contents, not its own source,
# so litedown's 'outdated' check never triggers when a post is added.
# Touch the listing pages whenever any post is newer than the rendered index.
touch_if_stale <- function(index_rmd, watch_glob) {
  index_html <- sub("\\.Rmd$", ".html", index_rmd)
  if (!file.exists(index_rmd)) return(invisible())
  sources <- Sys.glob(watch_glob)
  if (!length(sources)) return(invisible())
  newest <- max(file.mtime(sources))
  if (!file.exists(index_html) || newest > file.mtime(index_html)) {
    Sys.setFileTime(index_rmd, Sys.time())
    message("Touched ", index_rmd, " (posts changed)")
  }
}

touch_if_stale("posts/index.Rmd", "posts/*/index.Rmd")
touch_if_stale("index.Rmd",       "posts/*/index.Rmd")  # if the homepage lists posts

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
