library(ggplot2)
library(reshape2)

relevant_repos = c("decred/dcrd", "decred/dcrdocs", "decred/decrediton", "decred/dcrandroid", "decred/politeia", "decred/politeiagui", "decred/dcrwallet", "decred/dcrdata", "decred/dcrtime", "decred/dcrweb")
relevant_events = c("PushEvent", "ForkEvent", "IssuesEvent", "IssueCommentEvent", "PullRequestEvent", "PullRequestReviewCommentEvent")
relevant_events = c("PushEvent", "ForkEvent", "IssuesEvent",  "PullRequestEvent")

events.month.2017 = read.csv("2017-monthly-event-data.csv", stringsAsFactors = FALSE)
events.month.2018 = read.csv("2018-monthly-event-data.csv", stringsAsFactors = FALSE)

events.month.2017$year = "2017"
events.month.2018$year = "2018"


months = rbind(events.month.2017, events.month.2018)


months = months[months$repo_name %in% relevant_repos,] 


months = months[months$event_type %in% relevant_events,]

months$day = paste(months$month, "-01", sep="")
months$daya = as.POSIXct(months$day, format = "%Y-%m-%d")

months = months[months$month != "2019-01",]


p.monthly.repo = ggplot(months, aes(x = daya, y = event_frequency, colour = event_type))+
  geom_line()+
  facet_wrap(~repo_name, ncol = 1, scales = "free_y")+
  xlab("Month")+
  ylab("Event Frequency")+
  labs(colour = "Event Type")
  

ggsave("2017-18-decred-repo-events-monthly.png", height = 14, width = 8)




#explore detailed monthly data

detail = read.csv("detailed-monthly-data.csv", stringsAsFactors = FALSE)
detail$action = as.character(detail$action)

#remove extraneous events (i.e. only want to consider PR opens, not closes and reopens)
detail.s = detail[!detail$action == "\"closed\"",]
detail.s = detail.s[!detail.s$action == "\"reopened\"",]

months = detail.s
months = months[months$repo_name %in% relevant_repos,] 

months = months[months$event_type %in% relevant_events,]

months$day = paste(months$month, "-01", sep="")
months$daya = as.POSIXct(months$day, format = "%Y-%m-%d")

months = months[months$month != "2019-01",]

p.monthly = ggplot(months, aes(x = daya, y = event_frequency, colour = repo_name))+
  geom_line()+
  facet_wrap(~event_type, ncol = 1, scales = "free_y")

p.monthly.repo = ggplot(months, aes(x = daya, y = event_frequency, colour = event_type))+
  geom_line()+
  facet_wrap(~repo_name, ncol = 1, scales = "free_y")+
  scale_colour_manual(values = c("red", "purple", "green", "blue"), 
                    name = "Event Type", 
                    labels = c("Forks Created","Issues Opened", "Pull Requests Opened", "Pushes to master"))+
  labs(x = "Month (2018)", y = "Event frequency (monthly)")



ggsave("2018-repo-events-monthly.png", height = 14, width = 8)








