library(ggplot2)
library(reshape2)
library(jsonlite)

forks2016 = read.csv("dcrforks2016.csv", stringsAsFactors = FALSE)
forks2017 = read.csv("dcrforks2017.csv", stringsAsFactors = FALSE)
forks2018 = read.csv("dcrforks2018.csv", stringsAsFactors = FALSE)

forkevents = rbind(forks2016,forks2017, forks2018)
forkevents$shortname = sub(".*/", "", forkevents$repo_name)

d.forks = dcast(forkevents, repo_name ~ type)
d.forks$shortname =  sub(".*/", "", d.forks$repo_name)

d.forks.events = dcast(d.forks, shortname ~ .)

p.repo.forks = ggplot(d.forks.events[d.forks.events$. > 10,], aes(x = factor(shortname), y = .))+
  geom_bar(stat = "identity")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  labs(x = "Repository - only showing those with > 10 forks", y = "Number of Forks", title = "Number of forks (with events) per repository")

ggsave("forks-per-repo.png", width = 7, height = 4)

d.forks.event.counts = dcast(forkevents, shortname ~ type)

p.repo.forks.forks = ggplot(d.forks.event.counts[d.forks.event.counts$ForkEvent > 0,], aes(x = factor(shortname), y = ForkEvent))+
  geom_bar(stat = "identity")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  labs(x = "Repository - only showing those with forks that have been forked", y = "Number of Forks of Forks", title = "Cumulative # of Fork Events for all Forks of /decred/ repositories")


ggsave("forks-per-forks-per-repo.png", width = 7, height = 4)

pr.events = forkevents[forkevents$type == "PullRequestEvent",]

for(pr in pr.events$id[pr.events$type == "PullRequestEvent"])
{
  payload = fromJSON(pr.events$payload[pr.events$id == pr], flatten = TRUE) 
  pr.events$head[pr.events$id == pr] = payload$pull_request$head$repo$full_name
  pr.events$base[pr.events$id == pr] = payload$pull_request$base$repo$full_name
  pr.events$commits[pr.events$id == pr] = payload$pull_request$commits
  pr.events$additions[pr.events$id == pr] = payload$pull_request$additions
  pr.events$deletions[pr.events$id == pr] = payload$pull_request$deletions
  pr.events$action[pr.events$id == pr] = payload$pull_request$state
  pr.events$merged[pr.events$id == pr] = payload$pull_request$merged
  pr.events$review.comments[pr.events$id == pr] = payload$pull_request$review_comments
  pr.events$comments[pr.events$id == pr] = payload$pull_request$comments
  pr.events$pr_created_at[pr.events$id == pr] = payload$pull_request$created_at
}
  

repo_name= unique(forkevents$repo_name)
pr_closed_decred = seq(1:length(repo_name))

forks = data.frame(repo_name, pr_closed_decred)
forks$repo_name = as.character(forks$repo_name)

for(f in forks$repo_name)
{
  events = pr.events[pr.events$repo_name == f,]
  
  forks$pr_closed_decred[forks$repo_name == f]  = length(events$action[events$action == "closed" & sub("/.*", "", events$head) == "decred"])
  forks$pr_closed_other[forks$repo_name == f] = length(events$action[events$action == "closed" & sub("/.*", "", events$head) != "decred" &  events$head != events$base])
  forks$pr_closed_internal[forks$repo_name == f] = length(events$action[events$action == "closed" & events$head == events$base])
  
  forks$pr_merged_decred[forks$repo_name == f] = length(events$action[events$merged == TRUE & sub("/.*", "", events$head) == "decred"])
  forks$pr_merged_internal[forks$repo_name == f] = length(events$action[events$merged == TRUE &  events$head == events$base])
  forks$pr_merged_other[forks$repo_name == f] = length(events$action[events$merged == TRUE & sub("/.*", "", events$head) != "decred" & events$head != events$base])
  
  forks$pr_commits[forks$repo_name == f] = sum(events$commits)
  forks$pr_additions[forks$repo_name == f] = sum(events$additions)
  forks$pr_deletions[forks$repo_name == f] = sum(events$deletions)
}


fork.events =  forkevents[forkevents$type == "ForkEvent",]  

forks$forked = 0

for(f in forks$repo_name)
{
  forks$forked[forks$repo_name == f] = nrow(fork.events[fork.events$repo_name == f,])
   
}

push.events = forkevents[forkevents$type == "PushEvent",]

for(push in push.events$id)
{
  payload = fromJSON(push.events$payload[push.events$id == push], flatten = TRUE) 
  push.events$head[push.events$id == push] 
}

  
for(f in forks$repo_name)
{
  events = push.events[push.events$repo_name == f,]
  forks$pushes[forks$repo_name == f] = nrow(events)  
}

#start and end

forkevents$created_pos = as.POSIXct(forkevents$created_at)
for(f in forks$repo_name)
{
  events = forkevents[forkevents$repo_name == f,]
  forks$firstevent[forks$repo_name == f] = min(events$created_at)
  forks$lastevent[forks$repo_name == f] = max(events$created_at)
}

forks$duration = as.POSIXct(forks$lastevent) - as.POSIXct(forks$firstevent)
forks$durationdays = forks$duration/(30*60*24)


#decred org events

events2016 = read.csv("dcr_events_2016.csv", stringsAsFactors = FALSE)
events2017 = read.csv("dcr_events_2017.csv", stringsAsFactors = FALSE)
events2018 = read.csv("dcr_events_2018.csv", stringsAsFactors = FALSE)

dcr.events = rbind(events2016, events2017, events2018)

dcr.pr.events = dcr.events[dcr.events$type == "PullRequestEvent",]

#these don't have head repos, remove them
dcr.pr.events = dcr.pr.events[dcr.pr.events$id != 4854211755,]
dcr.pr.events = dcr.pr.events[dcr.pr.events$id != 4848078022,]
dcr.pr.events = dcr.pr.events[dcr.pr.events$id != 6274134239,]
dcr.pr.events = dcr.pr.events[dcr.pr.events$id != 6722058001,]
dcr.pr.events = dcr.pr.events[dcr.pr.events$id != 5321818466,]

for(pr in dcr.pr.events$id[dcr.pr.events$type == "PullRequestEvent"])
{
  payload = fromJSON(dcr.pr.events$payload[dcr.pr.events$id == pr], flatten = TRUE) 
  if(length(payload$pull_request$head$repo$full_name) > 0){
  dcr.pr.events$head[dcr.pr.events$id == pr] = payload$pull_request$head$repo$full_name
  dcr.pr.events$base[dcr.pr.events$id == pr] = payload$pull_request$base$repo$full_name
  dcr.pr.events$commits[dcr.pr.events$id == pr] = payload$pull_request$commits
  dcr.pr.events$additions[dcr.pr.events$id == pr] = payload$pull_request$additions
  dcr.pr.events$deletions[dcr.pr.events$id == pr] = payload$pull_request$deletions
  dcr.pr.events$action[dcr.pr.events$id == pr] = payload$pull_request$state
  dcr.pr.events$merged[dcr.pr.events$id == pr] = payload$pull_request$merged
  dcr.pr.events$review.comments[dcr.pr.events$id == pr] = payload$pull_request$review_comments
  dcr.pr.events$comments[dcr.pr.events$id == pr] = payload$pull_request$comments
  dcr.pr.events$pr_created_at[dcr.pr.events$id == pr] = payload$pull_request$created_at
  }
}

dcr.pr.events2 = dcr.pr.events[!is.na(dcr.pr.events$head),]

for(f in forks$repo_name)
{
  events = dcr.pr.events2[dcr.pr.events2$head == f,]
  if(nrow(events) > 0)
  {
  
  forks$dcr_pr_merged[forks$repo_name == f] = length(events$action[events$merged == TRUE ])

  forks$dcr_pr_commits[forks$repo_name == f] = sum(events$commits)
  forks$dcr_pr_additions[forks$repo_name == f] = sum(events$additions)
  forks$dcr_pr_deletions[forks$repo_name == f] = sum(events$deletions)
  }
}



