# 06 - Model 2: Random Forest, and Model 3: Decision Tree

# ---- Random Forest: tune mtry with 10-fold CV --------------------------------
set.seed(42)
rf_model <- train(
  y ~ .,
  data      = train_data,
  method    = "rf",
  trControl = ctrl,
  tuneGrid  = expand.grid(mtry = c(3, 5, 7, 9)),
  metric    = "ROC",
  ntree     = 200
)
print(rf_model)
save_chart(ggplot(rf_model) +
             labs(title = "Random Forest: mtry Tuning (10-fold CV)") +
             theme_minimal(),
           "06_rf_mtry_tuning.png", width = 7, height = 4.5)

rf_pred      <- predict(rf_model, test_data)
rf_pred_prob <- predict(rf_model, test_data, type = "prob")[, "yes"]

cm_rf <- confusionMatrix(rf_pred, test_data$y, positive = "yes")
print(cm_rf)

roc_rf <- make_roc(test_data$y, rf_pred_prob)
cat("Random Forest test AUC:", round(auc(roc_rf), 4), "\n")

save_base_chart("06_roc_random_forest.png", {
  plot(roc_rf, col = model_colours[["Random Forest"]], lwd = 2,
       main = "ROC Curve: Random Forest")
  legend("bottomright", legend = paste("AUC =", round(auc(roc_rf), 3)),
         col = model_colours[["Random Forest"]], lwd = 2)
}, width = 6, height = 6)

# Feature importance - which client attributes drive the prediction
rf_importance <- randomForest::importance(rf_model$finalModel)
importance_df <- data.frame(
  Feature    = rownames(rf_importance),
  Importance = rf_importance[, "MeanDecreaseGini"],
  row.names  = NULL
) %>%
  arrange(desc(Importance))
write.csv(importance_df, file.path("outputs", "rf_feature_importance.csv"),
          row.names = FALSE)

p_importance <- ggplot(head(importance_df, 15),
                       aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = model_colours[["Random Forest"]], alpha = 0.85) +
  coord_flip() +
  labs(title = "Top 15 Features: Random Forest Importance",
       x = "", y = "Mean decrease in Gini") +
  theme_minimal()
save_chart(p_importance, "06_rf_feature_importance.png")

# ---- Decision Tree: tune the complexity parameter ----------------------------
set.seed(42)
tree_model <- train(
  y ~ .,
  data       = train_data,
  method     = "rpart",
  trControl  = ctrl,
  tuneLength = 15,
  metric     = "ROC"
)
print(tree_model)

# The tuned tree is too deep to read, so the chart shows only its first splits
cp_table   <- tree_model$finalModel$cptable
display_cp <- cp_table[max(which(cp_table[, "nsplit"] <= 7)), "CP"]
tree_display <- rpart::prune(tree_model$finalModel, cp = display_cp)

save_base_chart("06_decision_tree.png", {
  rpart.plot::rpart.plot(tree_display,
                         main = "Decision Tree: first splits (pruned for display)",
                         type = 4, extra = 104, fallen.leaves = TRUE, cex = 0.8)
}, width = 11, height = 6)

tree_pred      <- predict(tree_model, test_data)
tree_pred_prob <- predict(tree_model, test_data, type = "prob")[, "yes"]

cm_tree <- confusionMatrix(tree_pred, test_data$y, positive = "yes")
print(cm_tree)

roc_tree <- make_roc(test_data$y, tree_pred_prob)
cat("Decision Tree test AUC:", round(auc(roc_tree), 4), "\n")
