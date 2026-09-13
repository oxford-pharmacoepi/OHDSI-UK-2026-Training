
path <- file.path(tempdir(), "OMOP")
dir.create(path = path)

c("delphi" = "delphi-100k_5.4", "GiBleed" = "GiBleed") |>
  purrr::imap(\(x, nm) {
    options(timeout = 600)
    omock::downloadMockDataset(datasetName = x, path = path, overwrite = TRUE)

    datasetPath <- file.path(path, paste0(x, ".zip"))
    tmpFolder <- file.path(path, "source")
    dir.create(tmpFolder)

    cli::cli_inform(c(i = "Unziping DB."))
    utils::unzip(zipfile = datasetPath, exdir = tmpFolder)

    print(list.files(tmpFolder, recursive = TRUE))

    unlink(datasetPath, recursive = TRUE)

    cli::cli_inform(c(i = "Reading {.pkg {x}} tables."))
    con <- duckdb::dbConnect(drv = duckdb::duckdb(
      dbdir = here::here("Databases", paste0(nm, ".duckdb"))
    ))
    DBI::dbExecute(con, "CREATE SCHEMA results")
    DBI::dbExecute(con, "SET memory_limit = '2GB'")
    list.files(path = tmpFolder, full.names = TRUE, recursive = TRUE) |>
      purrr::map(\(x) {
        name <- tools::file_path_sans_ext(x = basename(x))
        if (!name %in% c("genomic_test", "target_gene", "variant_annotation", "variant_occurrence")) {
          cli::cli_inform(c(i = "Inserting {.pkg {name}}."))
          sql <- "CREATE TABLE {name} AS SELECT * FROM read_parquet('{x}')" |>
            glue::glue() |>
            as.character()
          DBI::dbExecute(con, sql)
        }
        unlink(x)
      }) |>
      invisible()
    DBI::dbDisconnect(con = con)

    unlink(x = tmpFolder, recursive = TRUE)
  })

unlink(path, recursive = TRUE)
