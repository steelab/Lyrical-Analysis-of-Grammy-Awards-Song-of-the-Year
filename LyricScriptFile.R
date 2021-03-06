
library(rvest)
library(tidyverse)
library(tidytext)
library(genius)
library(dplyr)
library(gridExtra)
data("stop_words")

#Please refer to RMD, this is just raw code from a notebook file

# read webpage for Grammy Awards
webpage <- read_html("https://en.wikipedia.org/wiki/Grammy_Award_for_Record_of_the_Year")

# copy xpath for table of 1980s
XPATH80 <- '/html/body/div[3]/div[3]/div[5]/div[1]/table[5]'
XPATH90 <- '/html/body/div[3]/div[3]/div[5]/div[1]/table[6]'
XPATH00 <- '/html/body/div[3]/div[3]/div[5]/div[1]/table[7]'
XPATH10 <- '/html/body/div[3]/div[3]/div[5]/div[1]/table[8]'
# run the following to create table of songs from 1980s
table_1980 <- 
  webpage %>%
  html_nodes(xpath = XPATH80) %>%
  html_table(fill = TRUE)
# run the following to create table of songs from 1980s
table_1990 <- 
  webpage %>%
  html_nodes(xpath = XPATH90) %>%
  html_table(fill = TRUE)
table_2000 <- 
  webpage %>%
  html_nodes(xpath = XPATH00) %>%
  html_table(fill = TRUE)
table_2010 <- 
  webpage %>%
  html_nodes(xpath = XPATH10) %>%
  html_table(fill = TRUE)

d1980 <- table_1980[[1]]
d1990 <- table_1990[[1]]
d2000 <- table_2000[[1]]
d2010 <- table_2010[[1]]







#Omitting all NA columns
d1980<- na.omit(d1980)
d1990<- na.omit(d1990)
d2000<- na.omit(d2000)
d2010<- na.omit(d2010)

#Renaming columns
names(d1980)[1] <- "year"
names(d1990)[1] <- "year"
names(d2000)[1] <- "year"
names(d2010)[1] <- "year"

names(d1980)[2] <- "track"
names(d1990)[2] <- "track"
names(d2000)[2] <- "track"
names(d2010)[2] <- "track"

names(d1980)[3] <- "artist"
names(d1990)[3] <- "artist"
names(d2000)[3] <- "artist"
names(d2010)[3] <- "artist"

#Dropping Production Team Column
d1980$`Production team`<- NULL
d1990$`Production team`<- NULL
d2000$`Production team`<- NULL
d2010$`Production team`<- NULL






#Removing the brackets in the year column
d1980$year <- gsub("[^0-9.-]", "", d1980$year)
d1990$year <- gsub("[^0-9.-]", "", d1990$year)
d2000$year <- gsub("[^0-9.-]", "", d2000$year)
d2010$year <- gsub("[^0-9.-]", "", d2010$year)

#Removing the last 2 numbers from the rows to give us the Year
d1980$year <- substr(d1980$year,1,4)
d1990$year <- substr(d1990$year,1,4)
d2000$year <- substr(d2000$year,1,4)
d2010$year <- substr(d2010$year,1,4)





 
lyrics80 <- d1980%>%
  add_genius(artist, track, type = "lyrics")
lyrics90 <- d1990%>%
  add_genius(artist, track, type = "lyrics")
lyrics00 <- d2000%>%
  add_genius(artist, track, type = "lyrics")
lyrics10 <- d2010%>%
  add_genius(artist, track, type = "lyrics")





#combining all lyrical dataframes from 1980's-2010's
lyricsCombined<- do.call("rbind", list(lyrics80,lyrics90,lyrics00,lyrics10))




#Creating a decades column
lyricsCombined$Decade = ""
lyricsCombined$Decade <- substr(lyricsCombined$year,1,3)
lyricsCombined$Decade <- paste0(lyricsCombined$Decade, "0s")




 
#creates a df with each row corresponding to a word in the lyric
verse_words <- lyricsCombined %>%
  unnest_tokens(word, lyric)

#aggregating all of the words to find song word count
verse_words <-
  verse_words %>%
  group_by(track,Decade) %>%
  summarise(totalWords= n())



###Graph 1

#Graph #1
verse_words %>%
  ggplot(aes(x=Decade,y=totalWords,fill=Decade)) +
  geom_boxplot(show.legend = FALSE) +
  ylab("Words per Song") + 
  ggtitle("Boxplots of Words per Grammy Nominated Song by Decade")



###Removing Stopwords

#removing stop words
df_Stopwords_removed <- lyricsCombined %>%
  unnest_tokens(word, lyric)

#Anti Join (Removing) stop words 
df_Stopwords_removed <- df_Stopwords_removed %>%
  anti_join(stop_words)

#Reading in txt file with more stop words
x<- read.csv("AdditionalStopWords.txt",header = FALSE)

#renaming columns so anti_join works
x$word= x$V1
x$V1 = NULL
df_Stopwords_removed <- df_Stopwords_removed %>%
  anti_join(x)

#Counting top 10 frequent words
topten <- df_Stopwords_removed %>%
  count(word, sort = FALSE) %>%
  top_n(10)





#Graph Number 2
topten %>% 
  ggplot() +
  geom_col(aes(reorder(word,-n),n))+
  labs(title = "Ten Most Popular Words of Grammy Nominated Songs from 1980 - 2019",
       x="Word",y="Count")



topyear <- df_Stopwords_removed %>% 
  group_by(Decade) %>%
  count(word, sort = TRUE) %>%
  top_n(10)


#Creating Graph #3
#We must create 4 separate graphs then combine them



g3_80s <- topyear %>% 
  filter(Decade == "1980s")%>%
  ggplot(aes()) +
  geom_col(aes(reorder(word,-n),n))+
  labs(title = "1980's",
       x="Word",y="Count")

g3_90s <- topyear %>% 
  filter(Decade == "1990s")%>%
  ggplot() +
  geom_col(aes(reorder(word,-n),n),fill = "#FF6666")+
  labs(title = "1990's",
       x="Word",y="Count")

g3_00s <- topyear %>% 
  filter(Decade == "2000s")%>%
  ggplot() +
  geom_col(aes(reorder(word,-n),n),fill="red")+
  labs(title = "2000's",
       x="Word",y="Count")

g3_10s <- topyear %>% 
  filter(Decade == "2010s")%>%
  ggplot() +
  geom_col(aes(reorder(word,-n),n),fill = "#69b3a2")+
  labs(title = "2010's",
       x="Word",y="Count")


#Combining 4 graphs
grid.arrange(top="Top Ten Words by Decade",g3_80s, g3_90s,g3_00s,g3_10s, ncol=2)






#Joining sentiment from tidytext to our filtered df 
df_sentiments <- df_Stopwords_removed %>%
  inner_join(sentiments)


#mapping 0 to negative and 1 to positive in the sentiment column
df_sentiments$sentiment[df_sentiments$sentiment=="negative"] <-0
df_sentiments$sentiment[df_sentiments$sentiment=="positive"] <-1
df_sentiments$sentiment <- as.numeric(df_sentiments$sentiment)

#Aggregating data to calculate net sentiment
df_sentiments <-df_sentiments %>%
  group_by(year,Decade) %>%
  summarise(total = sum(sentiment)) 

#Graph #4
df_sentiments %>%
  ggplot(aes(x=year,y=total,fill= Decade))+
  geom_col() +
  labs(title = "Net Seniment Score by Year",y="Net Sentiment",x="Year")+
  scale_x_discrete(breaks = seq(1980, 2020, by = 10))






#Graph 5
df_sentiments %>%
  group_by(Decade)%>%
  summarise(meanSentiment = sum(total)/10)%>%
  ggplot(aes(x=Decade,y=meanSentiment)) + 
  geom_col(fill="blue") + 
  labs(title = "Mean Sentiment Score by Decade",x="Decade",y="Mean Sentiment Score")




#Graph 5
df_sentiments$year <- as.numeric(df_sentiments$year)
df_sentiments %>%
  ggplot(aes(x=year,y=total,color=Decade))+
  geom_point() + 
  geom_smooth(method="lm",color="red")+
  labs(title = "Net Sentiment Score by Year of Grammy Nominated Records 
       from 1980 - 2019 with Linear Model Fit",x="Year",y="Net Sentiment")+
  scale_x_discrete(breaks = seq(1980, 2020, by = 10))



