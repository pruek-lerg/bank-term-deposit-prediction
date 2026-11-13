# 00 - Setup: packages, output folders, shared colours and helpers

required_packages <- c("tidyverse", "caret", "randomForest", "rpart",
                       "rpart.plot", "pROC", "ROSE", "e1071", "nnet", "scales")
missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages) > 0) install.packages(missing_packages)

# randomForest, rpart, nnet and ROSE are called through caret or with `::`,
# so they are not attached here (randomForest would mask ggplot2::margin).
suppressPackageStartupMessages({
  library(tidyverse)
  library(caret)
  library(pROC)
})

dir.create("charts",  showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

model_colours <- c(
  "Logistic Regression" = "#3b82f6",
  "Random Forest"       = "#06d6a0",
  "Decision Tree"       = "#f59e0b",
  "Neural Network"      = "#ec4899"
)
TEAL   <- "#028090"
SLATE  <- "#1E293B"
MUTED  <- "#64748B"
ORANGE <- "#E59E3F"

# Save a ggplot to charts/
save_chart <- function(plot, filename, width = 8, height = 5) {
  ggsave(file.path("charts", filename), plot,
         width = width, height = height, dpi = 200, bg = "white")
  invisible(plot)
}

# Save a base-graphics plot to charts/ (pass the plotting code in braces)
save_base_chart <- function(filename, expr, width = 8, height = 5.5) {
  png(file.path("charts", filename),
      width = width, height = height, units = "in", res = 200)
  on.exit(dev.off())
  force(expr)
  invisible(NULL)
}

# Test-set metrics for one model, with "yes" as the positive class
get_metrics <- function(cm, roc_obj) {
  c(Accuracy  = unname(cm$overall["Accuracy"]),
    Precision = unname(cm$byClass["Precision"]),
    Recall    = unname(cm$byClass["Recall"]),
    F1        = unname(cm$byClass["F1"]),
    AUC       = as.numeric(auc(roc_obj)))
}

# ROC curve with "yes" as the positive class
make_roc <- function(actual, prob_yes) {
  roc(actual, prob_yes, levels = c("no", "yes"), direction = "<", quiet = TRUE)
}
