# 12 - Confusion-matrix charts for the four models (test set, cutoff 0.50)
# Percentages in each cell are shares of the actual class (row percentages).

plot_cm <- function(cm_obj, model_label, accent_colour) {
  cm_df <- as.data.frame(cm_obj$table)
  names(cm_df) <- c("Prediction", "Actual", "n")

  cm_df <- cm_df %>%
    mutate(Actual     = factor(Actual,     levels = c("no", "yes")),
           Prediction = factor(Prediction, levels = c("no", "yes"))) %>%
    group_by(Actual) %>%
    mutate(
      pct      = 100 * n / sum(n),
      cell_lbl = case_when(
        Actual == "no"  & Prediction == "no"  ~ "TN",
        Actual == "no"  & Prediction == "yes" ~ "FP",
        Actual == "yes" & Prediction == "no"  ~ "FN",
        Actual == "yes" & Prediction == "yes" ~ "TP"
      ),
      fill_colour = case_when(
        cell_lbl == "TP" ~ accent_colour,
        cell_lbl == "TN" ~ "#E2F2F1",
        TRUE             ~ "#FBE3E1"
      ),
      text_colour = ifelse(cell_lbl == "TP", "white", SLATE)
    ) %>%
    ungroup()

  header_lbl <- sprintf("Recall %.1f%%  |  Precision %.1f%%",
                        100 * cm_obj$byClass[["Sensitivity"]],
                        100 * cm_obj$byClass[["Pos Pred Value"]])

  ggplot(cm_df, aes(x = Prediction, y = Actual)) +
    geom_tile(aes(fill = fill_colour), colour = SLATE, width = 0.92, height = 0.85) +
    geom_text(aes(label = format(n, big.mark = ","), colour = text_colour),
              fontface = "bold", size = 9, vjust = -0.3) +
    geom_text(aes(label = sprintf("%s | %.1f%%", cell_lbl, pct),
                  colour = text_colour), size = 3.4, vjust = 2.5) +
    scale_fill_identity() +
    scale_colour_identity() +
    scale_y_discrete(limits = rev) +
    labs(title = model_label, subtitle = header_lbl,
         x = "Predicted class", y = "Actual class") +
    coord_equal(clip = "off") +
    theme_minimal(base_size = 11) +
    theme(plot.title    = element_text(colour = SLATE, face = "bold", size = 14),
          plot.subtitle = element_text(colour = accent_colour, face = "bold", size = 11),
          axis.title    = element_text(colour = MUTED, size = 10),
          axis.text     = element_text(colour = MUTED, size = 11),
          panel.grid    = element_blank(),
          plot.margin   = ggplot2::margin(10, 14, 8, 10))
}

cms <- list("Logistic Regression" = cm_logit, "Random Forest" = cm_rf,
            "Decision Tree" = cm_tree, "Neural Network" = cm_nnet)

for (model_label in names(cms)) {
  fname <- paste0("12_cm_", gsub(" ", "_", tolower(model_label)), ".png")
  save_chart(plot_cm(cms[[model_label]], model_label, model_colours[[model_label]]),
             fname, width = 4.6, height = 3.8)
}
