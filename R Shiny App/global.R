library(shinydashboard)
library(ggplot2)
library(tidyverse)
library(tidyr)
library(shiny)
library(leaflet)
library(pracma)

#-----------read in all Data-----------------
df <- read_csv("Cleaned_Apartment_Data_for_Week_of_2019-04-14.csv")

#Load in Street Easy Median price data
AllMedianPriceDF<-as_tibble(read_csv("Cleaned_StreetEasy_Apartment_Data_All_Bedroom.csv"))
OnebrMedianPriceDF<-as_tibble(read_csv("Cleaned_StreetEasy_Apartment_Data_One_Bedroom.csv"))
TwobrMedianPriceDF<-as_tibble(read_csv("Cleaned_StreetEasy_Apartment_Data_Two_Bedroom.csv"))
ThreebrMedianPriceDF<-as_tibble(read_csv("Cleaned_StreetEasy_Apartment_Data_Three_Bedroom.csv"))

#subset dataset based on inputs
subIt <- function(df, price, bedroom = NULL, bathroom = NULL, time2Work)
{
  
  ifelse(is.null(bedroom) && is.null(bathroom),
         {
           return(subset(df,Price <price & Time<= time2Work))
         },
         
         ifelse(is.null(bathroom),
                
                {
                  return(subset(df,Price<price & Bedroom == bedroom & Time <= time2Work))
                },
                ifelse(is.null(bedroom),
                       {
                         return(subset(df,Price<price & Bathroom == bathroom & Time <= time2Work))
                       },
                       
                       return(subset(df,Price<price & Bathroom == bathroom & Bedroom == bedroom & Time <= time2Work))
                       
                )
         )
  )
  
}

subsetRadius <- function(df,neighborhood)
{
  
  return(df[df$Name %in% neighborhood, ])
}

#Function to build description of apartment
getAptInfo <- function(df)
{
  
  return(
    paste(sep = "<br/>",df$Title,
          paste("Price:$",df$Price),
          paste("Bedrooms:",df$Bedroom),
          paste("Bathrooms:",df$Bathroom),
          paste("Time to work by subway:",df$Time, "minutes"),
          paste("Subway Line:",df$SubwayLine),
          paste0("<a href='",df$`Page Link`,"'>","Link to apartment listing","</a>"))
  )
}


getBoundingCoords<- function(centralLat, centralLong, radius)
{
  #north south distance in degrees - approx.
  dlat <- radius/69
  #east west distance in degrees - approx
  dlong <- dlat/cosd(centralLat)
  
  southMostLat <- centralLat - dlat
  northMostLat <- centralLat + dlat
  westMostLong <- centralLong - dlong
  eastMostLong <- centralLong + dlong
  
  return (c(southMostLat,northMostLat,westMostLong,eastMostLong))
  
}

aptInRadius <- function(aptLat, aptLong, centerAptLat,centerAptLong, radius)
{
  boundingCoords <- getBoundingCoords(centerAptLat,centerAptLong,radius)
  if(aptLat >= boundingCoords[1] && aptLat <= boundingCoords[2] & aptLong >= boundingCoords[3] && aptLong <= boundingCoords[4])
  {
    return(TRUE)
  }
  else
  {
    return(FALSE)
  }
  
}

getMedianPriceData <-function(x)
{
  
  #Select data set based on bedroom selected
  if(is.null(x))
  {
    return(AllMedianPriceDF)
  }
  if(x == 1)
  {
    return(OnebrMedianPriceDF)
  }
  if(x== 2)
  {
    return(TwobrMedianPriceDF)
  }
  if(x == 3)
  {
    return(ThreebrMedianPriceDF)
  }
  if(x == 4)
  {
    return(AllMedianPriceDF)
  }
}
  
