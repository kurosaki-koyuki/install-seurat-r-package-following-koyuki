cat("=====================================\n")
cat("  STEP 1: Force Show Token Setup Window\n")
cat("=====================================\n\n")

cran_repo <- "https://cloud.r-project.org/"

cat("Checking Shiny installation...\n")
if (!requireNamespace("shiny", quietly = TRUE)) {
  cat("  Shiny not installed, installing...\n")
  install.packages("shiny", repos = cran_repo, type = "binary", quiet = TRUE)
}

library(shiny)

cat("\n  >>> Opening GitHub Token Setup Window <<<\n")
cat("  >>> Please enter your token in the browser window <<<\n")

app <- shinyApp(
  ui = fluidPage(
    titlePanel("GitHub Access Token Setup"),
    sidebarLayout(
      sidebarPanel(
        textInput(
          inputId = "token",
          label = "Enter GitHub Personal Access Token (PAT):",
          placeholder = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
          width = "100%"
        ),
        actionButton(
          inputId = "confirm",
          label = "Confirm and Close",
          width = "100%",
          style = "background-color: #2196F3; color: white; font-weight: bold; padding: 10px;"
        ),
        hr(),
        helpText(
          "How to get a token:",
          "1. Visit https://github.com/settings/tokens",
          "2. Click 'Generate new token'",
          "3. Select 'repo' and 'read:packages' permissions",
          "4. Copy the generated token and paste it above"
        )
      ),
      mainPanel(
        h4("Instructions"),
        p("This token is used to access GitHub repositories and increase API rate limits."),
        p("Even if you already have a token, please confirm here."),
        p("Click Confirm to close this window and continue installation.")
      )
    )
  ),
  server = function(input, output, session) {
    observeEvent(input$confirm, {
      token <- isolate(input$token)
      stopApp(token)
    })
  }
)

token_input <- runApp(app, launch.browser = TRUE)

github_token <- NULL
if (!is.null(token_input) && nchar(token_input) > 0) {
  github_token <- token_input
  Sys.setenv(GITHUB_PAT = github_token)
  cat("  [OK] GitHub token set\n")
  
  if (requireNamespace("gitcreds", quietly = TRUE)) {
    tryCatch({
      gitcreds::gitcreds_set(github_token, ask = FALSE)
      cat("  [OK] GitHub token persisted\n")
    }, error = function(e) {})
  }
} else {
  cat("  [SKIP] No token entered, continuing (GitHub packages may fail)\n")
}

cat("\n")
cat("=====================================\n")
cat("  STEP 2: Install Base Dependencies\n")
cat("=====================================\n")

install_pkg <- function(pkg_name, repo = cran_repo) {
  cat(sprintf("  %s... ", pkg_name))
  
  if (pkg_name %in% installed.packages()[, "Package"]) {
    cat("already installed\n")
    return(TRUE)
  }
  
  tryCatch({
    install.packages(pkg_name, repos = repo, dependencies = TRUE, type = "binary", quiet = TRUE)
    if (pkg_name %in% installed.packages()[, "Package"]) {
      cat("success\n")
      return(TRUE)
    }
  }, error = function(e) {})
  
  tryCatch({
    install.packages(pkg_name, repos = repo, dependencies = TRUE, quiet = TRUE)
    if (pkg_name %in% installed.packages()[, "Package"]) {
      cat("success\n")
      return(TRUE)
    }
  }, error = function(e) {})
  
  cat("failed\n")
  return(FALSE)
}

install_pkg("remotes")
install_pkg("BiocManager")

cat("\n")
cat("=====================================\n")
cat("  STEP 3: Install Seurat\n")
cat("=====================================\n")

install_pkg("Seurat")

cat("\n")
cat("=====================================\n")
cat("  STEP 4: Install Signac\n")
cat("=====================================\n")

install_pkg("Signac")

cat("\n")
cat("=====================================\n")
cat("  STEP 5: Install Performance Packages\n")
cat("=====================================\n")

cat("  BPCells:\n")
cat("    NOTE: BPCells requires manual download and local installation\n")
cat("    Download from: https://github.com/bnprks/BPCells/archive/refs/heads/main.zip\n")
cat("    First install hexbin dependency\n")

install_pkg("hexbin")

cat("\n  Please extract BPCells and enter the path (or press Enter to skip):\n")
if (interactive()) {
  bpcells_path <- readline("BPCells extracted directory path: ")
  if (nchar(bpcells_path) > 0 && dir.exists(bpcells_path)) {
    cat(sprintf("    Installing BPCells locally... "))
    tryCatch({
      install.packages(bpcells_path, type = "source", repos = NULL, quiet = TRUE)
      if ("BPCells" %in% installed.packages()[, "Package"]) {
        cat("success\n")
      } else {
        cat("failed\n")
      }
    }, error = function(e) {
      cat(sprintf("failed: %s\n", substr(conditionMessage(e), 1, 50)))
    })
  } else {
    cat("    Skipping BPCells installation\n")
  }
} else {
  cat("    Non-interactive mode, skipping BPCells installation\n")
}

install_pkg("presto")
install_pkg("glmGamPoi")

cat("\n")
cat("=====================================\n")
cat("  STEP 6: Install GitHub Packages\n")
cat("=====================================\n")

install_github_pkg <- function(repo, pkg_name) {
  cat(sprintf("  %s (%s)... ", pkg_name, repo))
  
  if (pkg_name %in% installed.packages()[, "Package"]) {
    cat("already installed\n")
    return(TRUE)
  }
  
  max_retries <- 3
  for (i in 1:max_retries) {
    tryCatch({
      remotes::install_github(repo = repo, quiet = TRUE, upgrade = 'never')
      if (pkg_name %in% installed.packages()[, "Package"]) {
        cat("success\n")
        return(TRUE)
      }
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      
      if (grepl('401|Unauthorized', error_msg) && i < max_retries) {
        cat(sprintf("failed (401), re-fetching token...\n"))
        
        app_retry <- shinyApp(
          ui = fluidPage(
            titlePanel("Token Invalid"),
            sidebarPanel(
              textInput("token", "Enter new GitHub token:", width = "100%"),
              actionButton("confirm", "Confirm", width = "100%")
            ),
            mainPanel(
              p("Previous token is invalid, please enter a new token")
            )
          ),
          server = function(input, output, session) {
            observeEvent(input$confirm, {
              stopApp(isolate(input$token))
            })
          }
        )
        
        new_token <- runApp(app_retry, launch.browser = TRUE)
        if (!is.null(new_token) && nchar(new_token) > 0) {
          Sys.setenv(GITHUB_PAT = new_token)
          gitcreds::gitcreds_set(new_token, ask = FALSE)
          cat("    [OK] Token updated\n")
        }
      }
    })
  }
  
  cat("failed\n")
  return(FALSE)
}

install_github_pkg("satijalab/seurat-data", "SeuratData")
install_github_pkg("satijalab/azimuth", "azimuth")
install_github_pkg("satijalab/seurat-wrappers", "SeuratWrappers")

cat("\n")
cat("=====================================\n")
cat("  STEP 7: Load Test\n")
cat("=====================================\n")

test_pkgs <- c("Seurat", "Signac", "presto", "glmGamPoi", "BPCells", "SeuratData", "azimuth")
test_pkgs <- test_pkgs[test_pkgs %in% installed.packages()[, "Package"]]

for (pkg in test_pkgs) {
  cat(sprintf("  library(%s)... ", pkg))
  tryCatch({
    suppressWarnings(library(pkg, character.only = TRUE, quietly = TRUE))
    cat("success\n")
  }, error = function(e) {
    cat(sprintf("failed: %s\n", substr(conditionMessage(e), 1, 50)))
  })
}

cat("\n")
cat("=====================================\n")
cat("  INSTALLATION COMPLETE\n")
cat("=====================================\n")
cat("\nIf any packages failed to install, you can manually install them:\n")
cat("  - BPCells: Download source, then install.packages('path', type='source', repos=NULL)\n")
cat("  - GitHub: Make sure token is correct, then remotes::install_github('repo')\n")