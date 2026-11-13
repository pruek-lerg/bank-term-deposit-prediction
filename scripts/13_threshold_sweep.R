# 13 - Choosing a calling cutoff for the Random Forest, and what it buys
#
# The cutoff is chosen on cross-validation predictions (training data only)
# and then checked once on the test set, so the test result stays honest.

metrics_at <- function(prob_yes, actual, threshold) {
  pred_yes <- prob_yes > threshold
  tp <- sum(pred_yes  & actual == "yes"); fp <- sum(pred_yes  & actual == "no")
  fn <- sum(!pred_yes & actual == "yes"); tn <- sum(!pred_yes & actual == "no")
  precision <- if (tp + fp == 0) NA_real_ else tp / (tp + fp)
  recall    <- tp / (tp + fn)
  f1 <- if (is.na(precision) || precision + recall == 0) NA_real_ else
    2 * precision * recall / (precision + recall)
  c(threshold = threshold, accuracy = (tp + tn) / length(actual),
    precision = precision, recall = recall, f1 = f1)
}

sweep_thresholds <- function(prob_yes, actual, grid) {
  as.data.frame(do.call(rbind, lapply(grid, function(t) metrics_at(prob_yes, actual, t))))
}

grid <- seq(0.02, 0.90, by = 0.01)

# Out-of-fold predictions for the selected mtry (savePredictions = "final")
oof <- rf_model$pred
cv_sweep   <- sweep_thresholds(oof$yes, oof$obs, grid)
test_sweep <- sweep_thresholds(rf_pred_prob, test_data$y, grid)

best_t <- cv_sweep$threshold[which.max(cv_sweep$f1)]
is_t   <- function(df, t) abs(df$threshold - t) < 1e-9

threshold_summary <- rbind(
  cbind(cutoff = "default 0.50",        test_sweep[is_t(test_sweep, 0.50), ]),
  cbind(cutoff = "chosen on CV (max F1)", test_sweep[is_t(test_sweep, best_t), ])
)
threshold_summary[, -1] <- round(threshold_summary[, -1], 4)
cat("\nRandom Forest on the test set at two cutoffs:\n")
print(threshold_summary, row.names = FALSE)
write.csv(threshold_summary, file.path("outputs", "threshold_summary.csv"),
          row.names = FALSE)

sweep_out <- merge(
  setNames(cv_sweep,   c("threshold", paste0("cv_",   names(cv_sweep)[-1]))),
  setNames(test_sweep, c("threshold", paste0("test_", names(test_sweep)[-1]))),
  by = "threshold"
)
write.csv(round(sweep_out, 4), file.path("outputs", "threshold_sweep.csv"),
          row.names = FALSE)

sweep_long <- rbind(
  data.frame(threshold = cv_sweep$threshold,   f1 = cv_sweep$f1,
             Data = "Cross-validation (used to choose)"),
  data.frame(threshold = test_sweep$threshold, f1 = test_sweep$f1,
             Data = "Test set (check)")
)

p_thr <- ggplot(sweep_long, aes(x = threshold, y = f1, colour = Data, linetype = Data)) +
  geom_line(linewidth = 1.1, na.rm = TRUE) +
  geom_vline(xintercept = best_t, linetype = "dashed", colour = ORANGE, linewidth = 0.6) +
  geom_vline(xintercept = 0.50, linetype = "dotted", colour = "gray50", linewidth = 0.5) +
  annotate("text", x = best_t, y = max(sweep_long$f1, na.rm = TRUE),
           label = sprintf("  chosen = %.2f", best_t),
           hjust = 0, colour = ORANGE, fontface = "bold") +
  scale_colour_manual(values = c(TEAL, "gray40")) +
  labs(title    = "F1 vs Decision Threshold: Random Forest",
       subtitle = "Cutoff chosen on cross-validation predictions, then checked on the test set",
       x = "Probability threshold", y = "F1 score (class = yes)",
       colour = NULL, linetype = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title.position = "plot", legend.position = "bottom",
        plot.title = element_text(face = "bold", colour = SLATE))
save_chart(p_thr, "13_threshold_sweep.png", width = 8, height = 5)

# ---- Gains: if the bank calls only the top-scored clients --------------------
gains_for <- function(prob_yes, actual, model_name) {
  tibble(prob = prob_yes, actual = actual) %>%
    arrange(desc(prob)) %>%
    mutate(decile = ceiling(10 * row_number() / n())) %>%
    group_by(decile) %>%
    summarise(clients = n(), subscribers = sum(actual == "yes"), .groups = "drop") %>%
    mutate(
      Model                 = model_name,
      subscription_rate_pct = round(100 * subscribers / clients, 1),
      cum_clients_pct       = round(100 * cumsum(clients) / sum(clients), 1),
      cum_subscribers_pct   = round(100 * cumsum(subscribers) / sum(subscribers), 1),
      lift                  = round((subscribers / clients) /
                                      (sum(subscribers) / sum(clients)), 2)
    ) %>%
    select(Model, everything())
}

gains <- bind_rows(
  gains_for(logit_pred_prob, test_data$y, "Logistic Regression"),
  gains_for(rf_pred_prob,    test_data$y, "Random Forest"),
  gains_for(tree_pred_prob,  test_data$y, "Decision Tree"),
  gains_for(nnet_pred_prob,  test_data$y, "Neural Network")
)
cat("\nGains by score decile (1 = highest scores):\n")
print(as.data.frame(gains), row.names = FALSE)
write.csv(gains, file.path("outputs", "gains_table.csv"), row.names = FALSE)

gains_plot <- bind_rows(
  tibble(Model = unique(gains$Model), cum_clients_pct = 0, cum_subscribers_pct = 0),
  gains[, c("Model", "cum_clients_pct", "cum_subscribers_pct")]
)

p_gains <- ggplot(gains_plot, aes(x = cum_clients_pct, y = cum_subscribers_pct,
                                  colour = Model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "gray50") +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  scale_colour_manual(values = model_colours) +
  scale_x_continuous(breaks = seq(0, 100, 20)) +
  scale_y_continuous(breaks = seq(0, 100, 20)) +
  labs(title    = "Cumulative Gains by Model (test set)",
       subtitle = "Subscribers reached when calling in score order; dashed line = calling at random",
       x = "% of clients called (highest scores first)",
       y = "% of subscribers reached", colour = NULL) +
  theme_minimal(base_size = 12) +
  theme(plot.title.position = "plot", legend.position = "bottom",
        plot.title = element_text(face = "bold", colour = SLATE))
save_chart(p_gains, "13_cumulative_gains.png", width = 8, height = 5.5)
