# 05 - Model 1: Logistic Regression (interpretable baseline)

set.seed(42)
logit_model <- train(
  y ~ .,
  data      = train_data,
  method    = "glm",
  family    = "binomial",
  trControl = ctrl,
  metric    = "ROC"
)
print(logit_model)

logit_pred      <- predict(logit_model, test_data)
logit_pred_prob <- predict(logit_model, test_data, type = "prob")[, "yes"]

cm_logit <- confusionMatrix(logit_pred, test_data$y, positive = "yes")
print(cm_logit)

roc_logit <- make_roc(test_data$y, logit_pred_prob)
cat("Logistic Regression test AUC:", round(auc(roc_logit), 4), "\n")

save_base_chart("05_roc_logistic_regression.png", {
  plot(roc_logit, col = model_colours[["Logistic Regression"]], lwd = 2,
       main = "ROC Curve: Logistic Regression")
  legend("bottomright", legend = paste("AUC =", round(auc(roc_logit), 3)),
         col = model_colours[["Logistic Regression"]], lwd = 2)
}, width = 6, height = 6)

# Most significant coefficients
coefs <- summary(logit_model$finalModel)$coefficients
coefs_df <- data.frame(
  Feature  = rownames(coefs),
  Estimate = round(coefs[, "Estimate"], 3),
  P_Value  = signif(coefs[, "Pr(>|z|)"], 3),
  row.names = NULL
)
coefs_df <- coefs_df[coefs_df$Feature != "(Intercept)", ]
coefs_df <- coefs_df[order(coefs_df$P_Value), ]
print(head(coefs_df, 10), row.names = FALSE)
write.csv(coefs_df, file.path("outputs", "logit_coefficients.csv"), row.names = FALSE)
