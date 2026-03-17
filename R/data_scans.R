# Data scans -------------------------------------------------------------

# Add table scans
# Slow! Follow: https://github.com/rstudio/pointblank/issues/550

# For one data set at the time
export_data_scan <- function(dt, name, max_rows = 1e3) {
  data <- if (!is.null(max_rows) && nrow(dt) > max_rows) {
    warning("Only useing a sample of the data!")
    dt[sample.int(nrow(dt), max_rows)]
  } else {
    copy(dt)
  }
  # Does not work with the IDate format it seems
  data[, names(.SD) := lapply(.SD, as.Date), .SDcols = is.Date]

  # Create folder if it does not already exist
  if (!fs::dir_exists("data_scans")) {
    fs::dir_create("data_scans")
  }
  outname <- paste0("data_scans/", name, ".html")
  scan_data(data, sections = "OMSV") |> # don't work with all default sections
    export_report(outname)
  outname # return file name
}

# for a list of multiple data sets
export_data_scans <- function(dts_fixed) {
  with(dts_fixed, setNames(data, name)) |>
    iwalk(export_data_scan, .progress = TRUE)
  "data_scans" # return folder name
}
