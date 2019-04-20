
#load up the library's
library(ggmap)
library(lubridate)
library(geosphere)
library(measurements)
library(ggplot2)
library(dplyr)
library(data.table)
library(ggrepel)
library(tidyverse)
library(gmapsdistance)
library(ggmap)
library(csv)
set.api.key("")
gmapsdistance::set.api.key("")

#-----------read in all Data-----------------
df <- read_csv("//Users/byronpoplawski/PycharmProjects/webScraper/Craigslist_Apt_Data_Week_of_4_14_2019.csv")
boroughsdf <- read_csv("/Users/byronpoplawski/Downloads/NeiborHoodNameCentroids.csv")
subwayStops <-read.csv('/Users/byronpoplawski/Downloads/DOITT_SUBWAY_ENTRANCE_01_13SEPT2010.csv')

#Load in Street Easy Median price data
AllMedianPriceDF<-as_tibble(read.csv("/Users/byronpoplawski/Downloads/medianAskingRent_All.csv", stringsAsFactors = FALSE))
OnebrMedianPriceDF<-as_tibble(read.csv("/Users/byronpoplawski/Downloads/medianAskingRent_OneBd.csv"))
TwobrMedianPriceDF<-as_tibble(read.csv("/Users/byronpoplawski/Downloads/medianAskingRent_TwoBd.csv"))
ThreebrMedianPriceDF<-as_tibble(read.csv("/Users/byronpoplawski/Downloads/medianAskingRent_ThreePlusBd.csv", stringsAsFactors =FALSE ))

#-----------Clean Apartment Dataset -------------------------------


#Date function to put date into desired format
convertDate<- function(date)
{
  d <- str_extract(date, "[0-9]{4}\\.[0-9]{2}")
  d <- strsplit(d,"[.]")
  d <- paste(d[[1]][1],"-",d[[1]][2], sep = "")
  return(d)
}

cleanStreetEasy <- function(df)
{
  #drop columns
  drops <- c("Borough", "areaType")
  df <-df[ , !(names(df) %in% drops)]
  
  #transpose data
  df <- df %>%
    gather(var, val, 2:ncol(df)) %>%
    spread(names(df)[1], val)
  
  colnames(df)[which(names(df) == "var")] <- "Date"
  df$Date <- sapply(df$Date, convertDate)
  df$Date <-as.Date(as.yearmon(df$Date), frac = 1)
  return (df)
}


AllMedianPriceDF <- cleanStreetEasy(AllMedianPriceDF)
OnebrMedianPriceDF <- cleanStreetEasy(OnebrMedianPriceDF)
TwobrMedianPriceDF <- cleanStreetEasy(TwobrMedianPriceDF)
ThreebrMedianPriceDF <- cleanStreetEasy(ThreebrMedianPriceDF)

#unlist(lapply(AllMedianPriceDF$Date, convertDate))

df <- as_tibble(df)

df <- separate(df,7, c("Latitude", "Longitude"), sep= ",", remove = TRUE, convert = TRUE)

drops <- c("Neighborhood")
df <- df[ , !(names(df) %in% drops)]

df <- tibble::rowid_to_column(df, "ApartmentID")

#df <- add_column(tibble("Dates" = c(rep(Sys.Date(), nrow(df)))))

#-----------------Find Apartment Boroughs ------------------------------------

boroughsdf$'LongLat' <- str_extract(boroughsdf$the_geom, '-.*\\b')

boroughsdf$LatLong <- c(gsub(" ", ", ", 
                             paste(boroughsdf$LongLat,
                                   sep = ",")))
#separate lat and long 
boroughsdf <- separate(boroughsdf, 10, c('Longitude','Latitude'), sep = ' ', remove = TRUE, convert = TRUE)



boroughsdf<- as_tibble(boroughsdf)

findClosestBorough <- function(latitude, longitude)
{
  i = 1
  minDist <- 100000000
  closestBorough <-""
  
  for(bDist in boroughsdf$Longitude)
  {
    distance <- distm(c(latitude,longitude), c(boroughsdf[[i,"Longitude"]], boroughsdf[[i,"Latitude"]]))
    
    if (distance<minDist) 
    {
      minDist <- distance
      closestBorough <- boroughsdf[i,"Name"]
      
    }
    
    i <- i+1
  }
  return(closestBorough)
}

j <-1
Boroughs <- tibble('Neighborhoods' =  as.character())

for(apt in df$Longitude)
{
  b <- findClosestBorough(df[[j,'Longitude']], df[[j,"Latitude"]])
  Boroughs <-bind_rows(Boroughs,b)
  j <- j+1
}

df <- bind_cols(df,Boroughs)

#--------------------Find Nearest Subway Stops-----------------------------------


#extract lat and long string in pure format from subway file

subwayStops$'Newcolumn' <-str_extract(subwayStops$the_geom, '-.*\\b')

#separate lat and long in subway file
subwayStops <- separate(subwayStops, 6, c('Latitude', 'Longitude'), sep = ' ', remove = TRUE, convert = TRUE)

#----------------Finding Nearest Subway Stop--------------------------
#function finds nearest subway stop, given a lat and long. Returns distance in meters, subway stop, and train lines

findClosestSubway <- function(latitude, longitude)
{
  info <- tibble('Distance' = as.integer(),'CurrentStop' = as.character(), 'SubwayLine'= as.character())
  i = 1
  DistancetoSubway <- 100000000
  ClosestStop <-""
  SubwayLine <- ""
  
  for(subDist in subwayStops$Longitude)
  {
    distance <- distm(c(longitude,latitude), c(subwayStops[[i,"Longitude"]], subwayStops[[i,"Latitude"]]))
    
    if (distance<DistancetoSubway) 
    {
      DistancetoSubway <- round(distance,digits = 0)
      ClosestStop <- subwayStops[i,'NAME']
      SubwayLine <- subwayStops[i,'LINE']
      #print(paste("Current Closest Stop is ", closestStop, "the line is ", subwayLine,  "And it is ", TimetoSubway, "meters away"))
    }
    
    i <- i+1
  }
  
  #information was in integer form for some reason, so I convert it to character
  ClosestStop <- as.character(ClosestStop)
  SubwayLine <-as.character(SubwayLine)
  dftemp <- tibble(DistancetoSubway,ClosestStop,SubwayLine)
  return(dftemp)
}

#Create tibble of 'distance to subway' for each apt listing
j <-1
dfDistances <- tibble(DistancetoSubway = as.integer(),ClosestStop = as.character(), SubwayLine= as.character())

for(apt in df$Longitude)
{
  closestSubwayInfo <- findClosestSubway(df[[j,'Longitude']], df[[j,"Latitude"]])
  dfDistances <- bind_rows(dfDistances,closestSubwayInfo)
  j <- j+1
}

#join columns of distance to subway with df

df <- bind_cols(df,dfDistances)

#-------------------------Find Commute Time to the Fed---------------------------

#function to calculate transit time
calculateTransTime <- function(origin, destination1)
{
  return(gmapsdistance(origin = origin, 
                       destination = destination1, 
                       mode = "transit"))
}

#function to convert seconds to minutes
tominutes <- function(seconds)
{
  minutes = (seconds)/60
  
  return(round(minutes,digits = 0))
  
}

#Destination to calculate commute time to
destination <- "33 liberty street new york NY 10045"

readableDestination <- gsub(" ", "+",destination)


#get lat long data into readable format for function
Origin <- c(gsub(" ", ", ", 
                 paste(df$Latitude,df$Longitude,
                       sep = ",")))

#create new list with all the transit times from apartment to destination
distance <- lapply(Origin,calculateTransTime, destination1 = readableDestination)

#unlist into readable format
dist_unlisted <- as.data.frame(sapply(distance, unlist))

#get just times row 
times <-dist_unlisted[1,]

#convert from list to tibble
times <- as_tibble(t(times))

#convert elements to numeric so that we can convert them from seconds to minutes
times <- as.numeric(unlist(times))

#convert element times from seconds to minutes
times <- sapply(times,tominutes,simplify = TRUE, USE.NAMES = TRUE)

#convert back to tibble
times <- as_tibble(times)

#name column TIME
colnames(times) <- "Time"

#Bind to rest of data
df <- bind_cols(df,times)


#Finalizing data - dropping random junk columns + renaming

drops <- c("Neighborhoods")
df <- df[ , !(names(df) %in% drops)]

#rename Name column to neighborhood

colnames(df)[colnames(df) == 'Name'] <- "Neighborhood"


#Final Clean + tidying up

df$Neighborhood <- ifelse(df$Neighborhood %in% c("Bedford Stuyvesant"), "Bedford-Stuyvesant", df$Neighborhood)

#convert price to numeric
df$Price<- as.numeric(as.character(df$Price))

#for some reason drop na doesnt work all the time on all the columns sooo...
df %>% drop_na()
df<- drop_na(df)

drops <- c("X1")
df <- df[ , !(names(df) %in% drops)]

df<-df[(df$Bathroom==1 | df$Bathroom==2 |df$Bathroom==3 |df$Bathroom==4), ]
df<-df[(df$Bedroom==1 | df$Bedroom==2 | df$Bedroom==3 | df$Bedroom==4), ]

#Attempt to eliminate duplicates
#df <- df[duplicated(df$Latitude), ]
#df <- df[duplicated(df$Longitude), ]
df <- df[duplicated(df$`Page Link`),]

#Write file to save work

write.csv(df, file = paste("Cleaned_Apartment_Data_for_Week_of_",Sys.Date(),sep = ""))
write.csv(AllMedianPriceDF,"Cleaned_StreetEasy_Apartment_Data_All_Bedroom.csv")
write.csv(OnebrMedianPriceDF,"Cleaned_StreetEasy_Apartment_Data_One_Bedroom.csv")
write.csv(TwobrMedianPriceDF,"Cleaned_StreetEasy_Apartment_Data_Two_Bedroom.csv")
write.csv(ThreebrMedianPriceDF,"Cleaned_StreetEasy_Apartment_Data_Three_Bedroom.csv")


