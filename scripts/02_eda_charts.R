# 02 - Exploratory charts: who subscribes?

eda <- bank
eda$month <- factor(eda$month,
                    levels = c("jan", "feb", "mar", "apr", "may", "jun",
                               "jul", "aug", "sep", "oct", "nov", "dec"))
fill_yes_no <- scale_fill_manual(values = c("no" = "#334155", "yes" = "#06d6a0"))

p_job <- ggplot(eda, aes(x = reorder(job, table(job)[job]), fill = y)) +
  geom_bar(position = "fill") +
  coord_flip() +
  scale_y_continuous(labels = scales::percent) +
  fill_yes_no +
  labs(title = "Subscription Rate by Job Type",
       x = "", y = "Share of clients", fill = "Subscribed") +
  theme_minimal()
save_chart(p_job, "02_subscription_by_job.png")

p_month <- ggplot(eda, aes(x = month, fill = y)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  fill_yes_no +
  labs(title = "Subscription Rate by Month of Last Contact",
       x = "Month", y = "Share of clients", fill = "Subscribed") +
  theme_minimal()
save_chart(p_month, "02_subscription_by_month.png")

p_age <- ggplot(eda, aes(x = age, fill = y)) +
  geom_histogram(binwidth = 5, alpha = 0.8, position = "identity") +
  scale_fill_manual(values = c("no" = "#334155", "yes" = "#3b82f6")) +
  labs(title = "Age Distribution by Subscription Outcome",
       x = "Age", y = "Clients", fill = "Subscribed") +
  theme_minimal()
save_chart(p_age, "02_age_distribution.png")

p_balance <- ggplot(eda, aes(x = y, y = balance, fill = y)) +
  geom_boxplot(outlier.alpha = 0.2) +
  scale_fill_manual(values = c("no" = "#ef4444", "yes" = "#06d6a0")) +
  labs(title = "Account Balance vs Subscription",
       x = "Subscribed", y = "Balance (euros)") +
  theme_minimal() +
  theme(legend.position = "none")
save_chart(p_balance, "02_balance_by_subscription.png", width = 6, height = 4.5)

p_poutcome <- ggplot(eda, aes(x = poutcome, fill = y)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("no" = "#334155", "yes" = "#f59e0b")) +
  labs(title = "Previous Campaign Outcome vs Subscription Rate",
       x = "Previous outcome", y = "Share of clients", fill = "Subscribed") +
  theme_minimal()
save_chart(p_poutcome, "02_subscription_by_previous_outcome.png")

p_calls <- ggplot(eda %>% filter(campaign <= 15), aes(x = campaign, fill = y)) +
  geom_histogram(binwidth = 1, position = "fill") +
  scale_y_continuous(labels = scales::percent) +
  fill_yes_no +
  labs(title = "Subscription Rate by Number of Calls in This Campaign",
       x = "Number of contacts", y = "Share of clients", fill = "Subscribed") +
  theme_minimal()
save_chart(p_calls, "02_subscription_by_calls.png")
