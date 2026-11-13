# 11 - PCA: how much of the feature space can be compressed?

X_pca <- train_data[, setdiff(names(train_data), "y")]
zero_var <- sapply(X_pca, function(col) stats::var(col) == 0)
if (any(zero_var)) X_pca <- X_pca[, !zero_var]
cat("PCA input:", nrow(X_pca), "rows x", ncol(X_pca), "columns\n")

pca <- prcomp(X_pca, center = TRUE, scale. = TRUE)

var_explained <- (pca$sdev^2) / sum(pca$sdev^2)
cum_var       <- cumsum(var_explained)
n80 <- which(cum_var >= 0.80)[1]
n90 <- which(cum_var >= 0.90)[1]
n95 <- which(cum_var >= 0.95)[1]
cat(sprintf("Components needed for 80%% / 90%% / 95%% of variance: %d / %d / %d (of %d)\n",
            n80, n90, n95, length(var_explained)))
cat(sprintf("The first 5 components explain %.1f%% of the variance\n",
            100 * cum_var[5]))

pca_table <- data.frame(
  PC            = seq_along(var_explained),
  var_explained = round(var_explained, 4),
  cum_var       = round(cum_var, 4)
)
write.csv(pca_table, file.path("outputs", "pca_variance_explained.csv"),
          row.names = FALSE)

plot_df <- head(data.frame(
  PC            = factor(pca_table$PC),
  var_explained = 100 * pca_table$var_explained,
  cum_var       = 100 * pca_table$cum_var
), 30)

p_scree <- ggplot(plot_df, aes(x = PC)) +
  geom_col(aes(y = var_explained), fill = "#1A8B86", alpha = 0.85) +
  geom_line(aes(y = cum_var, group = 1), colour = "#0F6B68", linewidth = 1.1) +
  geom_point(aes(y = cum_var), colour = "#0F6B68", size = 2) +
  geom_hline(yintercept = 80, linetype = "dashed", colour = ORANGE, linewidth = 0.6) +
  annotate("text", x = nrow(plot_df) - 1, y = 83, label = "80% variance",
           colour = ORANGE, hjust = 1, size = 3.5) +
  labs(title    = sprintf("PCA Scree: %d components reach 80%% of variance", n80),
       subtitle = sprintf("%d input features | first %d components shown",
                          ncol(X_pca), nrow(plot_df)),
       x = "Principal component", y = "Variance explained (%)") +
  theme_minimal(base_size = 11) +
  theme(plot.title    = element_text(colour = SLATE, face = "bold", size = 13),
        plot.subtitle = element_text(colour = MUTED, size = 10),
        panel.grid.minor = element_blank())
save_chart(p_scree, "11_pca_scree.png", width = 9.5, height = 4.5)
