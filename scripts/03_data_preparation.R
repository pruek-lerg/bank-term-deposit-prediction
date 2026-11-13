# 03 - Row-level data preparation
#
# Only steps that look at one row at a time happen here, so nothing can leak
# from the test set. Steps that learn values from the data (outlier caps,
# scaling) are fitted on the training set in 04_train_test_split.R.

bank_clean <- bank

# `duration` is only known after the call ends, so it cannot be used to decide
# who to call. Keeping it would make the model look far better than it is.
bank_clean <- bank_clean %>% select(-duration)

bank_clean$month <- factor(bank_clean$month,
                           levels = c("jan", "feb", "mar", "apr", "may", "jun",
                                      "jul", "aug", "sep", "oct", "nov", "dec"))
cat_cols <- c("job", "marital", "education", "default",
              "housing", "loan", "contact", "poutcome")
bank_clean[cat_cols] <- lapply(bank_clean[cat_cols], as.factor)
bank_clean$y <- factor(bank_clean$y, levels = c("no", "yes"))

# pdays = -1 means "never contacted before". Turn that into its own flag and
# set the placeholder to 0 so it does not act as a real number of days.
bank_clean$previously_contacted <- factor(
  ifelse(bank_clean$pdays == -1, "no", "yes"), levels = c("no", "yes"))
bank_clean$pdays[bank_clean$pdays == -1] <- 0

cat("Columns after preparation:", ncol(bank_clean), "\n")
cat("Missing values per column:\n")
print(colSums(is.na(bank_clean)))
