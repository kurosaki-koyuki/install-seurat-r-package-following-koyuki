#========================================#
#   Koyuki Seurat Installation Runner
#========================================#
#
# This script runs the Seurat installation
# Works with source() or Run button in RStudio
#
# Usage:
#   source("koyuki_seurat_install_run!.R")
#

cat("========================================\n")
cat("   Koyuki Seurat Installation Script\n")
cat("========================================\n\n")

# Try multiple ways to find the installation script
find_installer <- function() {
  possible_paths <- c()
  
  # Method 1: Try to get script path from commandArgs
  args <- commandArgs(trailingOnly = FALSE)
  for (arg in args) {
    if (grepl("--file=", arg)) {
      script_path <- normalizePath(sub("--file=", "", arg))
      possible_paths <- c(possible_paths, file.path(dirname(script_path), "seurat_install_by_koyuki", "install_seurat.R"))
    }
  }
  
  # Method 2: Try rstudioapi for current document
  if (requireNamespace("rstudioapi", quietly = TRUE)) {
    tryCatch({
      doc_path <- rstudioapi::getSourceEditorContext()$path
      if (!is.null(doc_path)) {
        possible_paths <- c(possible_paths, file.path(dirname(doc_path), "seurat_install_by_koyuki", "install_seurat.R"))
      }
    }, error = function(e) {})
  }
  
  # Method 3: Try from current working directory
  possible_paths <- c(possible_paths, 
                      file.path(getwd(), "seurat_install_by_koyuki", "install_seurat.R"),
                      "seurat_install_by_koyuki/install_seurat.R")
  
  # Check each path
  for (path in possible_paths) {
    if (file.exists(path)) {
      return(normalizePath(path))
    }
  }
  
  return(NULL)
}

installer_path <- find_installer()

if (is.null(installer_path)) {
  cat("ERROR: Installation script not found\n")
  cat("Looking for: seurat_install_by_koyuki/install_seurat.R\n\n")
  cat("Possible solutions:\n")
  cat("  1. Set working directory to where this script is located:\n")
  cat("     setwd('path/to/script/directory')\n")
  cat("  2. Or directly run the installer:\n")
  cat("     source('seurat_install_by_koyuki/install_seurat.R')\n")
  stop("Installation script not found")
}

cat("Found installer at:", installer_path, "\n\n")
cat("Running installation...\n\n")
source(installer_path)