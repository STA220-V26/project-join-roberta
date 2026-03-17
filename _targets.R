library(targets)
library(tarchetypes) # For extra target archetypes

# Which packages do you need?
pkgs <- c(
  "janitor", # data cleaning
  "labelled", # labeling data
  "pointblank", # data validation and exploration
  "rvest", # get data from web pages
  "tidyverse", # Data management
  "data.table", # fast data management
  "fs", # to work wit hthe file system
  "zip", # manipulate zip files
  "tarchetypes",  
  "quarto"
)
# Install packages if you don't already have them
install.packages(setdiff(pkgs, row.names(installed.packages())))

# NOTE! The packages specified in `pkgs` will be used by the targets.
# They will, however, not be available within the interactive session unless you also load them here:
invisible(lapply(pkgs, library, character.only = TRUE))

# Set target options:
tar_option_set(
  # Packages that your targets need for their tasks:
  packages = pkgs,
  format = "qs", # Default storage format. qs (which is actually qs2) is fast.
)

# Run the R scripts stored in the R/ folder where your have stored your custom functions:
tar_source() 

# We first download the data health care data of interest
if (!fs::file_exists("data.zip")) {
  message("Downloading data.zip from GitHub")
  curl::curl_download(
    "https://github.com/STA220/cs/raw/refs/heads/main/data.zip",
    "data.zip",
    quiet = FALSE
  )
}


# Define targets pipeline ------------------------------------------------

# Help: https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

list(
  # make the zipdata object refer to the data.zip file path
  tar_target(zipdata, "data.zip", format = "file"),

  tar_target(csv_files, zip::unzip(zipdata)), # Unzipping the data

  tar_map(
    values = tibble::tibble(path = dir("data-fixed", full.names = TRUE)) |>
      dplyr::mutate(name = tools::file_path_sans_ext(basename(path))),
    tar_target(dt, fread(path)),
    names = name,
    descriptions = NULL
  ),
  # In tar_map() We manipulate the datasets in directory data-fixed.
  # It creates a data table (for handling big data),
  # values is a function in tar_map() which is a named list of data frames
  # containing extracted values and filenames from directory
  # basename() Manipulate File Paths
  # file_path_sans_ext() Utilities for listing files, and manipulating file paths.
  # Codebook: scrape variable descriptions from Synthea wiki
  tar_target(codebook, get_codebook()),

  # Data scans: build a list of all datasets, then export pointblank HTML reports
  tar_target(
    dts_fixed,
    tibble::tibble(
      path = dir("data-fixed", full.names = TRUE),
      name = tools::file_path_sans_ext(basename(path))
    ) |> dplyr::mutate(data = lapply(path, data.table::fread))
  ),
  tar_target(data_scans, export_data_scans(dts_fixed), format = "file"),

  tar_quarto(
    report,
    path = "report.qmd",
    cue = tar_cue(mode = "always")
  )
)
