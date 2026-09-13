# Connexion
library(CDMConnector)
library(CodelistGenerator)
library(CohortConstructor)
library(CohortCharacteristics)
library(duckdb)
library(DBI)
library(dplyr)
library(gt)
library(here)

con <- dbConnect(drv = duckdb(dbdir = here("Databases", "delphi.duckdb")))
cdm <- cdmFromCon(
  con = con,
  cdmSchema = "main",
  writeSchema = "results",
  writePrefix = "cc_"
)

# Exercise 1 ----
# Create a cohort table with two primary main cohorts: rheumatoid arthritis and pneumonia.
# Use the provided OMOP Concept IDs.
codes <- list(
  "ra" = c(80809L),
  "pneumonia"            = c(255848L)
) |> newCodelist()

cdm$base_conditions_cohort <- conceptCohort(cdm = cdm, conceptSet = codes, name = "base_conditions_cohort")

summariseCohortAttrition(cohort = cdm$base_conditions_cohort) |>
  tableCohortAttrition() |>
  gt::gtsave(filename = here::here("Presentations", "CohortConstructor", "exercise_1.png"))


# Exercise 2 ----
# Create a new cohort named "study_cohort" by applying the following criteria to the base conditions cohort:
# -   For all cohorts, require that records start between January 1, 1990, and December 31, 2011.
# -   For the Rheumatoid Arthritis cohort, exclude patients with a history of osteoarthritis
#     prior to or on the day of diagnosis.
osteoarthritisCodes <- list("osteoarthritis" = c(80180L)) |> newCodelist()

cdm$study_cohort <- cdm$base_conditions_cohort |>
  requireInDateRange(
    dateRange = as.Date(c("1990-01-01", "2011-12-31")),
    name = "study_cohort"
  ) |>
  requireConceptIntersect(
    conceptSet = osteoarthritisCodes,
    cohortId = "ra",
    window = list(c(-Inf, 0)),
    intersections = 0,
    name = "study_cohort"
  )

summariseCohortAttrition(cohort = cdm$study_cohort) |>
  tableCohortAttrition() |>
  gt::gtsave(filename = here::here("Presentations", "CohortConstructor", "exercise_2.png"))


# Exercise 3 ----
# Since Rheumatoid Arthritis is a chronic condition, define its cohort exit
# so patients remain in the cohort from first diagnostic date to the end of the patient's observation.
# For Pneumonia, assume the infection lasts for two months from the diagnosis day,
# thereby update the cohort end date to be exactly 60 days after the cohort start.

cdm$study_cohort <- cdm$study_cohort |>
  exitAtObservationEnd(
    cohortId = "ra",
    persistAcrossObservationPeriods = TRUE,
    name = "study_cohort"
  ) |>
  padCohortDate(
    days = 60,
    cohortDate = "cohort_end_date",
    cohortId = "pneumonia",
    name = "study_cohort"
  )

summariseCohortAttrition(cohort = cdm$study_cohort) |>
  tableCohortAttrition() |>
  gt::gtsave(filename = here::here("Presentations", "CohortConstructor", "exercise_3.png"), vwidth = 1500)


# Exercise 4 ----
# Create a third cohort containing patients with Pneumonia who have Rheumatoid
# Arthritis at the same time. The final cohort table should keep all original
# cohorts plus the new intersection cohort. Finally, rename cohorts so they are
# called "pneumonia", "rheumatoid_arthritis", and
# "pneumonia_and_rheumatoid_arthritis".
cdm$study_cohort <- cdm$study_cohort |>
  intersectCohorts(
    cohortId = c("ra", "pneumonia"),
    keepOriginalCohorts = TRUE,
    name = "study_cohort"
  ) |>
  renameCohort(
    newCohortName = c("pneumonia", "rheumatoid_arthritis", "pneumonia_and_rheumatoid_arthritis")
  )

summariseCohortAttrition(cohort = cdm$study_cohort) |>
  tableCohortAttrition() |>
  gt::gtsave(filename = here::here("Presentations", "CohortConstructor", "exercise_4.png"), vwidth = 1500)

CDMConnector::cdmDisconnect(cdm)
