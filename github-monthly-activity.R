library(ggplot2)
library(reshape2)



months = read.csv("month-repo-type-frequency.csv")

relevant_repos = c("decred/dcrd", "decred/dcrdocs", "decred/decrediton", "decred/dcrandroid", "decred/politeia", "decred/politeiagui", "decred/dcrwallet", "decred/dcrdata")
relevant_events = c("PushEvent", "ForkEvent", "IssuesEvent", "IssueCommentEvent", "PullRequestEvent", "PullRequestReviewCommentEvent")


months = months[months$repo_name %in% relevant_repos,]
months = months[months$event_type %in% relevant_events,]

p.monthly = ggplot(months, aes(x = month, y = event_frequency, colour = repo_name))+
  geom_line()+
  facet_wrap(~event_type, ncol = 1, scales = "free_y")

p.monthly.repo = ggplot(months, aes(x = month, y = event_frequency, colour = event_type))+
  geom_line()+
  facet_wrap(~repo_name, ncol = 1, scales = "free_y")

ggsave("2017-repo-events-monthly.png", height = 14, width = 8)

