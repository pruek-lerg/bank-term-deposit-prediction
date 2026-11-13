# 07 - Model 4: Neural Network (single hidden layer)

set.seed(42)
nnet_model <- train(
  y ~ .,
  data      = train_data,
  method    = "nnet",
  trControl = ctrl,
  tuneGrid  = expand.grid(size = c(3, 5, 7), decay = c(0.01, 0.1)),
  metric    = "ROC",
  trace     = FALSE,
  maxit     = 200,
  MaxNWts   = 5000
)
print(nnet_model)
save_chart(ggplot(nnet_model) +
             labs(title = "Neural Network: Size and Decay Tuning (10-fold CV)") +
             theme_minimal(),
           "07_nnet_tuning.png", width = 7, height = 4.5)

nnet_pred      <- predict(nnet_model, test_data)
nnet_pred_prob <- predict(nnet_model, test_data, type = "prob")[, "yes"]

cm_nnet <- confusionMatrix(nnet_pred, test_data$y, positive = "yes")
print(cm_nnet)

roc_nnet <- make_roc(test_data$y, nnet_pred_prob)
cat("Neural Network test AUC:", round(auc(roc_nnet), 4), "\n")
