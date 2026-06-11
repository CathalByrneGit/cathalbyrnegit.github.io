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
