# 04 - Train/test split, then preparation fitted on the training set only
#
# Order matters:
#   1. Split 80/20 on the real, imbalanced data.
#   2. Learn outlier caps, dummy encoding and scaling from the training set,
#      then apply them unchanged to the test set.
#   3. Class balancing (ROSE) is NOT applied here. It runs inside each
#      cross-validation fold (sampling = "rose"), so every validation fold and
#      the test set contain real clients only.

set.seed(42)
train_idx <- createDataPartition(bank_clean$y, p = 0.8, list = FALSE)
train_raw <- bank_clean[train_idx, ]
test_raw  <- bank_clean[-train_idx, ]

# Cap outliers at the training set's 1st and 99th percentiles
winsor_cols   <- c("balance", "campaign", "previous", "pdays")
winsor_limits <- lapply(train_raw[winsor_cols], quantile,
                        probs = c(0.01, 0.99), na.rm = TRUE)
apply_winsor <- function(df) {
  for (col in winsor_cols) {
    limits    <- unname(winsor_limits[[col]])
    df[[col]] <- pmin(pmax(df[[col]], limits[1]), limits[2])
  }
  df
}
train_raw <- apply_winsor(train_raw)
test_raw  <- apply_winsor(test_raw)

# One-hot encode (k-1 dummies per factor)
predictor_cols <- setdiff(names(train_raw), "y")
dummies <- dummyVars(~ ., data = train_raw[, predictor_cols], fullRank = TRUE)
train_x <- as.data.frame(predict(dummies, newdata = train_raw[, predictor_cols]))
test_x  <- as.data.frame(predict(dummies, newdata = test_raw[, predictor_cols]))

# Centre and scale using training-set means and standard deviations
preproc <- preProcess(train_x, method = c("center", "scale"))
train_data <- predict(preproc, train_x)
test_data  <- predict(preproc, test_x)

names(train_data) <- make.names(names(train_data))
names(test_data)  <- make.names(names(test_data))
train_data$y <- train_raw$y
test_data$y  <- test_raw$y

cat("Training set:", nrow(train_data), "rows\n"); print(table(train_data$y))
cat("Test set:    ", nrow(test_data),  "rows\n"); print(table(test_data$y))

# The same 10 folds are reused for every model so they can be compared
set.seed(42)
cv_folds <- createFolds(train_data$y, k = 10, returnTrain = TRUE)

ctrl <- trainControl(
  method          = "cv",
  number          = 10,
  index           = cv_folds,
  classProbs      = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final",
  sampling        = "rose"      # balance the training part of each fold only
)
