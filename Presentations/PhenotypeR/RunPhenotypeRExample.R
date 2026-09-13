library(omock)
library(PhenotypeR)
library(CodelistGenerator)
library(CohortConstructor)

cdm <- omock::mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
cdm <- OmopConstructor::buildAchillesTables(cdm)

x <- c(list(anemia = 439777,
            rheumatoid_arthritis = 80809,
            osteoarthritis = 80180,
            pneumonia = 255848),
       getDrugIngredientCodes(cdm, c("heparin", "clopidogrel"),
                              nameStyle = "{concept_name}")) |>
  newCodelist()


cdm[["my_cohort"]] <- conceptCohort(cdm, x, name = "my_cohort")

res <- phenotypeDiagnostics(cdm[["my_cohort"]],
                            databaseDiagnostics = list("snapshot" = TRUE,
                                                       "personTableSummary" = TRUE,
                                                       "observationPeriodsSummary" = TRUE,
                                                       "clinicalRecordsSummary" = TRUE),
                            codelistDiagnostics = list(
                              "orphanCodeUse" = TRUE,
                              "cohortCodeUse" = TRUE,
                              "drugDiagnostics" = TRUE,
                              "drugDiagnosticsSample" = 20000,
                              "measurementDiagnostics" = TRUE,
                              "measurementDiagnosticsSample" = 20000),
                            cohortDiagnostics = list(
                              "cohortCount" = TRUE,
                              "cohortCharacteristics" = TRUE,
                              "largeScaleCharacteristics" = TRUE,
                              "compareCohorts" = TRUE,
                              "cohortSurvival" = TRUE,
                              "cohortSample" = NULL,
                              "matchedSample" = NULL),
                            populationDiagnostics = list(
                              "incidence" = TRUE,
                              "periodPrevalence" = TRUE,
                              "populationSample" = 1e+05,
                              "populationDateRange" = as.Date(c(NA, NA))))

exportSummarisedResult(res, minCellCount = 2)
