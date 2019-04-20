#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define server logic required to draw a histogram
shinyServer(function(input, output,session) {
  
  
  #reactive to subset data 
  subsettedData <- reactive({
    subIt(df,input$SliderPrice, input$Bedroom, input$Bathroom, input$SliderTime2Work)
  })
  
  #set up the initial map  
  output$map <- renderLeaflet({
    
    leaflet() %>%
      setView(lng = -73.9583, lat = 40.6982, zoom = 11) %>%
      addProviderTiles(providers$Wikimedia)
    
  })
  
  #leaflet proxy to update map based on inputs
  observe({
    
    aptDescription <- getAptInfo(subsettedData())
    
    leafletProxy("map", data = subsettedData()) %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      addMarkers(lng=subsettedData()$Longitude, lat=subsettedData()$Latitude,layerId = subsettedData()$ApartmentID,
                 clusterOptions = markerClusterOptions(zoomToBoundsOnClick = TRUE, 
                                                       removeOutsideVisibleBounds = TRUE), popup = aptDescription)
    
  })
  
  #Onclick function to perform price comparison of apartment relative to those within a .25 mile radius
  observe({
    click <- input$map_marker_click
    if (is.null(click))
    { return()
    }
    dataSubset <- subsettedData()
    
    #returns and prevents error if user changes parameters while apartment is clicked
    if(nrow(dataSubset) == 0)
    {
      return()
    }
    else
    {
      
      aptsNearby <-mapply(aptInRadius,dataSubset$Latitude, dataSubset$Longitude, click$lat,click$lng,.3)
      aptsNearby <- subset(dataSubset,aptsNearby)
    }
    
    
    ## Add a column indicating whether the category should be highlighted
    aptsNearby <- aptsNearby %>% 
      mutate(ToHighlight = ifelse(aptsNearby$ApartmentID == click$id, "yes", "no" ))
    
    
    #returns and prevents error from showing graph if user changes parameters while apartment is clicked
    if(is.tibble(aptsNearby) && nrow(aptsNearby) == 0)
    {
      return()
    }
   
#Plot of price comparison of apartments within 0.3 mile radius 
    output$plot <- renderPlot({
      
      ggplot(aptsNearby, aes(x = rep(1:nrow(aptsNearby)),y = Price, fill = ToHighlight)) +
        geom_bar( stat = "identity", width = 1, colour="black") +
        theme(axis.text.x=element_blank())+
        xlab("Apartments") + ylab("Price") + # Set axis labels
        theme(
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "transparent",colour = NA),
          plot.background = element_rect(fill = "transparent",colour = NA),
          axis.title.x = element_text(colour = "Black", size = 12),
          axis.title.y = element_text(colour = "Black", size = 12 ), plot.title = element_text(colour = "Black", hjust = .5, lineheight=.8, face="bold")
        ) +
        scale_fill_manual(values = c( "yes"="tomato", "no"="gray" ), guide = FALSE) +
        
        if(is.null(input$Bedroom) & is.null(input$Bathroom))
        {
          ggtitle(paste("Price Comparison of Other Nearby Apartments"))
        }
      
      else
        if(!is.null(input$Bedroom) & is.null(input$Bathroom))
        {
          ggtitle(paste("Price Comparison of Nearby", sep="\n",paste(input$Bedroom, "Bedroom Apartments")))
        }
      else
        if(!is.null(input$Bedroom) & !is.null(input$Bathroom))
        {
          ggtitle(paste("Price Comparison of Nearby", sep="\n",paste(input$Bedroom, "Bedroom", input$Bathroom, "Bathroom", "Apartments")))
        }
      
    })
    
    
  })  
  
#Onclick function to get price history of neighborhood based on apartment selected 
  observe(
    {
      
      click <- input$map_marker_click
      
      if (is.null(click))
      { return()
      }
      
      dataSubset <- subsettedData()
      
      if(nrow(dataSubset) == 0)
      {
        return()
      }
      else
      {
        
        MedianPricedf <- getMedianPriceData(input$Bedroom)
        subsetNeighborhood <- unlist(dataSubset[click$id == dataSubset$ApartmentID, "Neighborhood"], use.names = FALSE)

      }
      
      if(!length(subsetNeighborhood) == 0 && subsetNeighborhood %in% colnames(MedianPricedf))
      {
        MedianPricedf <- MedianPricedf[ ,c("Date", subsetNeighborhood)]
      }
      
      # If neighborhood of the apartment clicked on cannot be found in the streeteasy dataset, then scan nearby neighborhoods
      # and see if any of them are in the dataset. If a nearby neighborhood (within 1 mile) is in the streeteasy neighborhood, break loop and use it.
      # If this still doesnt work, use midtown manhattan as default neighborhood
      else
      {
        aptsNearby <-mapply(aptInRadius,dataSubset$Latitude, dataSubset$Longitude, click$lat,click$lng,1)
        aptsNearby <- subset(dataSubset,aptsNearby)
        nearbyNeighborhoods <- aptsNearby[!aptsNearby$Neighborhood %in% subsetNeighborhood, ]
        print(nearbyNeighborhoods$Neighborhood)
       
         for(neighborhood in nearbyNeighborhoods$Neighborhood)
        {
          if(neighborhood %in% colnames(MedianPricedf))
          {
            subsetNeighborhood <- neighborhood
            break
          }
          else
          {
            nearbyNeighborhoods <-nearbyNeighborhoods[!nearbyNeighborhoods %in% neighborhood, ]
            print(nearbyNeighborhoods$Neighborhood)
            
          }
        }
        
        if(!subsetNeighborhood %in% colnames(MedianPricedf))
        {
          print("really no nearby neighborhoods")
          subsetNeighborhood <-"All Midtown"
        }
       
        MedianPricedf <- MedianPricedf[c("Date",subsetNeighborhood)]
      }
     
      #use last 12 months of neighborhood pricing data
      MedianPricedf <- MedianPricedf[MedianPricedf$Date > (MedianPricedf[nrow(MedianPricedf),"Date"] - 366), ]
      
      #wierd workaround to change column name from neighborhood name to ns
      colnames(MedianPricedf)[colnames(MedianPricedf) == subsetNeighborhood] <- "ns"
      
      print(MedianPricedf$Date)
      #Plot of apartment price history
      output$plot2 <- renderPlot(
        {
          
          ggplot(data = MedianPricedf, aes(x = Date, y = ns, group = 1)) + geom_path(colour = "Tomato", size = 1)+
            #scale_x_date(breaks = AllMedianPriceDF$Date[seq(1, length(AllMedianPriceDF$Date), by = 5)])+
            ylab("Price ($)") + xlab("Date") +
            # set transparency
            theme(
              panel.grid.major = element_blank(), 
              panel.grid.minor = element_blank(),
              panel.background = element_rect(fill = "transparent",colour = NA),
              plot.background = element_rect(fill = "transparent",colour = NA),
              axis.title.x = element_text(colour = "Black", size = 12),
              axis.text.x = element_text(angle=90),
              axis.title.y = element_text(colour = "Black", size = 12 ), plot.title = element_text(colour = "Black", hjust = .5, lineheight=.8, face="bold")
              
            ) +
            
            if(is.null(input$Bedroom))
            {
              ggtitle(paste("Median Price of Apartments", paste("in", subsetNeighborhood, sep = "\n")))
                
            }
          else
          {
            ggtitle(paste("Median Price of",input$Bedroom, paste("Bedroom Apartments in", subsetNeighborhood, sep = "\n")))
          }
          
        })
      
    })
  
})
