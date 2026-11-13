# 08 - Compare the four models on the held-out test set

comparison <- rbind(
  "Logistic Regression" = get_metrics(cm_logit, roc_logit),
  "Random Forest"       = get_metrics(cm_rf,    roc_rf),
  "Decision Tree"       = get_metrics(cm_tree,  roc_tree),
  "Neural Network"      = get_metrics(cm_nnet,  roc_nnet)
)
comparison <- round(as.data.frame(comparison), 4)
comparison$Model <- rownames(comparison)
comparison <- comparison[, c("Model", "Accuracy", "Precision", "Recall", "F1", "AUC")]
rownames(comparison) <- NULL

cat("\nModel comparison (test set, n = ", nrow(test_data), "):\n", sep = "")
print(comparison[order(-comparison$AUC), ], row.names = FALSE)
write.csv(comparison, file.path("outputs", "model_comparison.csv"), row.names = FALSE)

roc_list <- list("Logistic Regression" = roc_logit, "Random Forest" = roc_rf,
                 "Decision Tree" = roc_tree, "Neural Network" = roc_nnet)

save_base_chart("08_roc_comparison.png", {
  plot(roc_list[[1]], col = model_colours[[names(roc_list)[1]]], lwd = 2.5,
       main = "ROC Curve Comparison: All Models (test set)")
  for (model_name in names(roc_list)[-1]) {
    lines(roc_list[[model_name]], col = model_colours[[model_name]], lwd = 2.5)
  }
  legend("bottomright",
         legend = sprintf("%-20s AUC = %.3f", names(roc_list),
                          sapply(roc_list, function(r) as.numeric(auc(r)))),
         col = model_colours[names(roc_list)], lwd = 2.5, cex = 0.85)
}, width = 7, height = 7)

p_auc <- ggplot(comparison, aes(x = reorder(Model, AUC), y = AUC, fill = Model)) +
  geom_col(alpha = 0.9, width = 0.65) +
  geom_text(aes(label = sprintf("%.3f", AUC)), hjust = -0.15, size = 4) +
  scale_fill_manual(values = model_colours) +
  coord_flip() +
  expand_limits(y = max(comparison$AUC) + 0.05) +
  labs(title = "Test-set AUC by Model", x = "", y = "AUC") +
  theme_minimal() +
  theme(legend.position = "none", plot.title.position = "plot")
save_chart(p_auc, "08_auc_by_model.png", width = 7, height = 4)

# Scored test set for the Power BI dashboard (not committed to GitHub)
test_scored <- test_data
test_scored$rf_prob <- rf_pred_prob
test_scored$rf_pred <- rf_pred
test_scored$logit_prob <- logit_pred_prob
test_scored$nnet_prob  <- nnet_pred_prob
write.csv(test_scored, file.path("outputs", "test_scored.csv"), row.names = FALSE)
