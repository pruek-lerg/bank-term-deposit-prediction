# =============================================================================
# run_all.R - runs the full pipeline in order
#
# How to use:
#   1. Open bank-term-deposit-prediction.Rproj in RStudio (sets the working
#      directory to the project root).
#   2. Put bank-full.csv in the data/ folder (see data/README.md).
#   3. Run:  source("run_all.R")
#
# Charts are written to charts/ and result tables to outputs/.
# Expect roughly 30-60 minutes; the Random Forest and Neural Network
# cross-validation steps take most of that time.
# =============================================================================

scripts <- c(
  "00_setup.R",
  "01_load_and_explore.R",
  "02_eda_charts.R",
  "03_data_preparation.R",
  "04_train_test_split.R",
  "05_logistic_regression.R",
  "06_random_forest_decision_tree.R",
  "07_neural_network.R",
  "08_model_comparison.R",
  "09_cv_variance.R",
  "10_kmeans_segmentation.R",
  "11_pca.R",
  "12_confusion_matrices.R",
  "13_threshold_sweep.R"
)

pipeline_start <- Sys.time()
for (script in scripts) {
  cat("\n========== ", script, " ==========\n", sep = "")
  step_start <- Sys.time()
  source(file.path("scripts", script))
  cat(sprintf("[%s finished in %.1f min]\n", script,
              as.numeric(difftime(Sys.time(), step_start, units = "mins"))))
}

writeLines(capture.output(sessionInfo()), file.path("outputs", "session_info.txt"))
cat(sprintf("\nPipeline complete in %.1f minutes.\n",
            as.numeric(difftime(Sys.time(), pipeline_start, units = "mins"))))
cat("Charts are in charts/ and tables are in outputs/.\n")
