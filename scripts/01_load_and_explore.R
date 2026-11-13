# 01 - Load the UCI Bank Marketing data and check the class balance

data_path <- file.path("data", "bank-full.csv")
if (!file.exists(data_path)) {
  stop("data/bank-full.csv not found. See data/README.md for the download link.")
}

bank <- read.csv(data_path, sep = ";", stringsAsFactors = FALSE)

cat("Rows x columns:", paste(dim(bank), collapse = " x "), "\n")
str(bank)
print(summary(bank))

class_counts <- table(bank$y)
class_pct    <- round(100 * prop.table(class_counts), 1)
print(class_counts)
print(class_pct)

p_class <- ggplot(bank, aes(x = y, fill = y)) +
  geom_bar() +
  scale_fill_manual(values = c("no" = "#ef4444", "yes" = "#06d6a0")) +
  labs(title    = "Class Distribution: Term Deposit Subscription",
       subtitle = sprintf("Imbalanced target: %.1f%% no vs %.1f%% yes",
                          class_pct[["no"]], class_pct[["yes"]]),
       x = "Subscribed", y = "Clients") +
  theme_minimal() +
  theme(legend.position = "none")
save_chart(p_class, "01_class_distribution.png", width = 6, height = 4.5)
