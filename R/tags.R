# R/tags.R — shared helpers for post frontmatter and tag slugs.
# Sourced by build.R (repo root) and by posts/index.Rmd and index.Rmd
# (via relative path) during the knit itself.

read_post_meta <- function(path) {
  lines <- readLines(path, n = 30, warn = FALSE)
  delims <- which(lines == "---")
  if (length(delims) < 2) return(NULL)
  yaml_lines <- lines[(delims[1] + 1):(delims[2] - 1)]

  title <- sub('^title:\\s*[\'"]?(.+?)[\'"]?\\s*$', "\\1",
               grep("^title:", yaml_lines, value = TRUE)[1])
  date  <- sub("^date:\\s*(.+?)\\s*$", "\\1",
               grep("^date:", yaml_lines, value = TRUE)[1])

  tags_line <- grep("^tags:", yaml_lines, value = TRUE)[1]
  tags <- character(0)
  if (!is.na(tags_line)) {
    inside <- sub("^tags:\\s*\\[(.*)\\]\\s*$", "\\1", tags_line)
    if (!identical(inside, tags_line) && nzchar(trimws(inside))) {
      tags <- trimws(strsplit(inside, ",")[[1]])
      tags <- gsub('^[\'"]|[\'"]$', "", tags)
      tags <- tags[nzchar(tags)]
    }
  }

  list(title = title, date = date, tags = tags)
}

slugify <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("^-+|-+$", "", x)
}

# Markdown hashtag links for a post's tags, e.g. " [#Irish Housing](/tags/irish-housing.html)"
tag_links_md <- function(tags) {
  if (length(tags) == 0) return("")
  links <- sprintf("[#%s](/tags/%s.html)", tags, vapply(tags, slugify, character(1)))
  paste0(" ", paste(links, collapse = " "))
}
