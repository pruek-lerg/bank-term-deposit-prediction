# 09 - How stable is each model across the 10 cross-validation folds?

cv_results <- resamples(list(
  "Logistic Regression" = logit_model,
  "Decision Tree"       = tree_model,
  "Random Forest"       = rf_model,
  "Neural Network"      = nnet_model
))
print(summary(cv_results))

roc_long <- cv_results$values %>%
  select(Resample, ends_with("~ROC")) %>%
  pivot_longer(-Resample, names_to = "Model", values_to = "ROC") %>%
  mutate(Model = sub("~ROC", "", Model))

roc_summary <- roc_long %>%
  group_by(Model) %>%
  summarise(
    Mean_ROC   = round(mean(ROC),   4),
    Median_ROC = round(median(ROC), 4),
    SD_ROC     = round(sd(ROC),     4),
    Min_ROC    = round(min(ROC),    4),
    Max_ROC    = round(max(ROC),    4),
    .groups    = "drop"
  ) %>%
  arrange(desc(Mean_ROC))

print(as.data.frame(roc_summary), row.names = FALSE)
write.csv(roc_summary, file.path("outputs", "cv_resamples_summary.csv"),
          row.names = FALSE)

roc_long$Model <- factor(roc_long$Model, levels = rev(roc_summary$Model))

p_cv <- ggplot(roc_long, aes(x = Model, y = ROC, fill = Model)) +
  geom_boxplot(alpha = 0.85, outlier.shape = NA, width = 0.55) +
  geom_jitter(width = 0.08, size = 1.6, alpha = 0.6) +
  scale_fill_manual(values = model_colours) +
  labs(title    = "Cross-validation AUC: Spread Across 10 Folds",
       subtitle = "Each dot is one validation fold of real (unbalanced) clients",
       x = "", y = "AUC on validation fold") +
  theme_minimal() +
  theme(legend.position = "none", plot.title.position = "plot",
        axis.text.x = element_text(face = "bold"))
save_chart(p_cv, "09_cv_variance_boxplot.png")
