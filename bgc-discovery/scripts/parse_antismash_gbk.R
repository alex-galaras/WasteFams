library(dplyr)

## ---------- Helper: parse GenBank locations ----------
parse_location <- function(loc) {
  strand <- "+"
  if (grepl("^complement\\(", loc)) {
    strand <- "-"
    loc <- sub("^complement\\(|\\)$", "", loc)
  }

  coords <- strsplit(loc, "\\.\\.")[[1]]

  list(
    start  = suppressWarnings(as.integer(coords[1])),
    end    = suppressWarnings(as.integer(coords[2])),
    strand = strand
  )
}

## ---------- Helper: clean qualifier value ----------
clean_value <- function(x) {
  x <- sub(".*=", "", x)
  gsub('"', "", x)
}

## ---------- Core parser (single file) ----------
parse_gbk_file <- function(gbk_file) {

  gbk <- readLines(gbk_file, warn = FALSE)

  ## ---- Extract contig ID (prefer antiSMASH Original ID) ----
  orig_id_line <- grep("Original ID ::", gbk, value = TRUE)

  if (length(orig_id_line) > 0) {
    contig <- sub(".*Original ID ::\\s*", "", orig_id_line[1])
  } else {
    ## Fallback to LOCUS if Original ID missing
    locus_line <- gbk[grep("^LOCUS", gbk)][1]
    contig <- sub("^LOCUS\\s+(\\S+).*", "\\1", locus_line)
  }

  ## ---- FEATURES block ----
  f_start <- grep("^FEATURES", gbk)
  o_start <- grep("^ORIGIN", gbk)

  if (length(f_start) == 0 || length(o_start) == 0)
    return(NULL)

  features <- gbk[(f_start + 1):(o_start - 1)]

  rows <- list()
  current <- NULL

  for (line in features) {

    ## ---- Feature start (5 spaces) ----
    if (grepl("^ {5}(region|cand_cluster|protocluster|proto_core)\\s+", line)) {

      if (!is.null(current)) {
        rows[[length(rows) + 1]] <- current
      }

      parts <- strsplit(trimws(line), "\\s+")[[1]]
      loc <- parse_location(parts[2])

      current <- list(
        contig = contig,
        feature = parts[1],
        start = loc$start,
        end = loc$end,
        strand = loc$strand,
        product = NA_character_,
        category = NA_character_,
        region_number = NA_character_,
        protocluster_number = NA_character_,
        contig_edge = NA_character_,
        core_location = NA_character_
      )

      next
    }

    ## ---- Ignore CDS blocks (do NOT terminate feature) ----
    if (grepl("^ {5}CDS\\s+", line)) {
      next
    }

    ## ---- Qualifiers (21 spaces + /key=) ----
    if (!is.null(current) && grepl("^ {21}/", line)) {

      if (grepl("/product=", line))
        current$product <- clean_value(line)

      else if (grepl("/category=", line))
        current$category <- clean_value(line)

      else if (grepl("/region_number=", line))
        current$region_number <- clean_value(line)

      else if (grepl("/protocluster_number=", line))
        current$protocluster_number <- clean_value(line)

      else if (grepl("/contig_edge=", line))
        current$contig_edge <- clean_value(line)

      else if (grepl("/core_location=", line))
        current$core_location <- clean_value(line)
    }
  }

  ## ---- Add last feature ----
  if (!is.null(current))
    rows[[length(rows) + 1]] <- current

  if (length(rows) == 0)
    return(NULL)

  df <- bind_rows(rows)

  ## ---- Parse core_location numerically ----
  df <- df %>%
    mutate(
      core_start = ifelse(
        is.na(core_location),
        NA_integer_,
        suppressWarnings(as.integer(sub("\\[(\\d+):.*", "\\1", core_location)))
      ),
      core_end = ifelse(
        is.na(core_location),
        NA_integer_,
        suppressWarnings(as.integer(sub(".*:(\\d+)\\].*", "\\1", core_location)))
      )
    )

  df
}

## ---------- Batch processing ----------
parse_gbk_dir <- function(path, pattern = "\\.gbk$") {

  files <- list.files(path, pattern = pattern, full.names = TRUE)

  message("Found ", length(files), " GBK files")

  res <- lapply(seq_along(files), function(i) {
    if (i %% 500 == 0)
      message("Processed ", i, " files")

    parse_gbk_file(files[i])
  })

  bind_rows(res)
}
