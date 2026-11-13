# 10 - Client segmentation with k-means (unsupervised)
#
# Segments describe the whole client book, so all 45,211 clients are used.
# The target `y` is not used to form the clusters, only to profile them.

clust_features <- c("age", "balance", "campaign", "previous", "pdays")

bank_seg <- bank_clean
for (col in c("balance", "campaign", "previous", "pdays")) {
  limits <- quantile(bank_seg[[col]], probs = c(0.01, 0.99), na.rm = TRUE)
  bank_seg[[col]] <- pmin(pmax(bank_seg[[col]], limits[[1]]), limits[[2]])
}
X_seg <- scale(bank_seg[, clust_features])

# Elbow method to choose k
wss <- sapply(2:8, function(k) {
  set.seed(42)
  kmeans(X_seg, centers = k, nstart = 25, iter.max = 50)$tot.withinss
})
elbow_df <- data.frame(k = 2:8, wss = wss)

p_elbow <- ggplot(elbow_df, aes(x = k, y = wss)) +
  geom_line(colour = TEAL, linewidth = 1.2) +
  geom_point(colour = TEAL, size = 3.5) +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Elbow Method: Choosing k",
       x = "Number of clusters (k)",
       y = "Total within-cluster sum of squares") +
  theme_minimal(base_size = 13) +
  theme(plot.title.position = "plot")
save_chart(p_elbow, "10_kmeans_elbow.png", width = 7, height = 4.5)

k_best <- 4
set.seed(42)
km <- kmeans(X_seg, centers = k_best, nstart = 25, iter.max = 50)
cat("Cluster sizes:\n"); print(km$size)
cat("Cluster centres (z-scores):\n"); print(round(km$centers, 2))

bank_seg$cluster <- factor(km$cluster, levels = 1:k_best,
                           labels = paste0("Segment ", 1:k_best))

profile <- bank_seg %>%
  group_by(cluster) %>%
  summarise(
    n                = n(),
    pct_of_book      = round(100 * n() / nrow(bank_seg), 1),
    subs_count       = sum(y == "yes"),
    subs_rate_pct    = round(100 * mean(y == "yes"), 1),
    mean_age         = round(mean(age), 1),
    median_balance   = round(median(balance), 0),
    mean_campaign    = round(mean(campaign), 1),
    pct_prev_success = round(100 * mean(poutcome == "success"), 1),
    .groups = "drop"
  ) %>%
  arrange(desc(subs_rate_pct))

print(as.data.frame(profile))
write.csv(profile, file.path("outputs", "kmeans_segments.csv"), row.names = FALSE)

overall_rate <- round(100 * mean(bank_seg$y == "yes"), 1)

p_segments <- ggplot(profile, aes(x = reorder(cluster, subs_rate_pct),
                                  y = subs_rate_pct, fill = cluster)) +
  geom_col(width = 0.6, alpha = 0.9) +
  geom_hline(yintercept = overall_rate, linetype = "dashed",
             colour = "gray40", linewidth = 0.6) +
  annotate("text", x = 0.6, y = overall_rate + 0.5,
           label = paste0("Overall ", overall_rate, "%"),
           colour = "gray40", hjust = 0, size = 3.5, fontface = "italic") +
  geom_text(aes(label = paste0(subs_rate_pct, "%")),
            hjust = -0.15, size = 5, fontface = "bold", colour = SLATE) +
  scale_fill_manual(values = c("#028090", "#00A896", "#02C39A", "#80E5D0")) +
  coord_flip() +
  expand_limits(y = max(profile$subs_rate_pct) + 5) +
  labs(title = "Subscription Rate by Client Segment",
       x = "", y = "Subscription rate (%)") +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none", plot.title.position = "plot",
        panel.grid.major.y = element_blank())
save_chart(p_segments, "10_segment_subscription_rate.png", width = 8, height = 4.5)

job_mix <- bank_seg %>%
  count(cluster, job) %>%
  group_by(cluster) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup()

p_jobmix <- ggplot(job_mix, aes(x = cluster, y = pct, fill = job)) +
  geom_col() +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Job Mix by Segment", x = "", y = "% of segment", fill = "Job") +
  theme_minimal(base_size = 12) +
  theme(plot.title.position = "plot")
save_chart(p_jobmix, "10_segment_job_mix.png")
