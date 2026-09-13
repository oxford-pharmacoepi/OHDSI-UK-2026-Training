presentations <- data.frame(
  title = c(
    "Welcome",
    "Introduction",
    "OmopSketch",
    "CohortConstructor",
    "PhenotypeR",
    "PatientProfiles",
    "CohortCharacteristics",
    "DrugUtilisation",
    "IncidencePrevalence",
    "Final remarks"
  ),
  html = c(
    "Presentations/welcome.html",
    "Presentations/Introduction/index.html",
    "Presentations/OmopSketch/index.html",
    "Presentations/CohortConstructor/index.html",
    "Presentations/PhenotypeR/index.html",
    "Presentations/PatientProfiles/index.html",
    "Presentations/CohortCharacteristics/index.html",
    "Presentations/DrugUtilisation/index.html",
    "Presentations/IncidencePrevalence/index.html",
    "Presentations/final_remarks.html"
  ),
  pdf = c(
    "01-welcome.pdf",
    "02-introduction.pdf",
    "03-omop-sketch.pdf",
    "04-cohort-constructor.pdf",
    "05-phenotype-r.pdf",
    "06-patient-profiles.pdf",
    "07-cohort-characteristics.pdf",
    "08-drug-utilisation.pdf",
    "09-incidence-prevalence.pdf",
    "10-final-remarks.pdf"
  ),
  stringsAsFactors = FALSE
)

required_packages <- c("pagedown", "qpdf")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the missing packages before exporting PDFs: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

site_dir <- "_site"
pdf_dir <- file.path(site_dir, "Presentations", "pdfs")
dir.create(pdf_dir, recursive = TRUE, showWarnings = FALSE)

html_files <- file.path(site_dir, presentations$html)
missing_html <- html_files[!file.exists(html_files)]

if (length(missing_html) > 0) {
  stop(
    "The rendered presentation HTML was not found. Run `quarto render` first. Missing files:\n",
    paste(missing_html, collapse = "\n"),
    call. = FALSE
  )
}

as_file_url <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  encoded_path <- utils::URLencode(path, reserved = FALSE)

  if (grepl("^[A-Za-z]:/", encoded_path)) {
    paste0("file:///", encoded_path)
  } else {
    paste0("file://", encoded_path)
  }
}

browser <- pagedown::find_chrome()

if (length(browser) == 0 || is.na(browser)) {
  stop(
    "Google Chrome, Microsoft Edge, or Chromium was not found. ",
    "Install one of them, or set the PAGEDOWN_CHROME environment variable.",
    call. = FALSE
  )
}

print_options <- list(
  landscape = TRUE,
  printBackground = TRUE,
  preferCSSPageSize = TRUE,
  displayHeaderFooter = FALSE,
  marginTop = 0,
  marginRight = 0,
  marginBottom = 0,
  marginLeft = 0
)

pdf_files <- file.path(pdf_dir, presentations$pdf)

for (i in seq_len(nrow(presentations))) {
  message("Exporting ", presentations$title[[i]], " to ", pdf_files[[i]])
  unlink(pdf_files[[i]], force = TRUE)

  pagedown::chrome_print(
    input = paste0(as_file_url(html_files[[i]]), "?print-pdf"),
    output = pdf_files[[i]],
    wait = 5,
    browser = browser,
    options = print_options,
    timeout = 180,
    extra_args = c("--disable-gpu", "--allow-file-access-from-files"),
    verbose = 0,
    outline = FALSE
  )
}

combined_pdf <- file.path(pdf_dir, "all-presentations.pdf")
message("Combining presentations into ", combined_pdf)
unlink(combined_pdf, force = TRUE)
qpdf::pdf_combine(input = pdf_files, output = combined_pdf)

message("Done.")
