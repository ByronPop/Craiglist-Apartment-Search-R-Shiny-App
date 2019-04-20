#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

ui <- dashboardPage(
  
  dashboardHeader(
    
      title = "B-Pop's Apartment App",
      titleWidth = 275),
  
  sidebar <- dashboardSidebar(  
    
    sliderInput("SliderPrice", h1("Price"),
                min = min(df$Price, na.rm = TRUE), max = 10000, value = 10000, step = 50),
    
    sliderInput("SliderTime2Work", h1("Metro Commute Time to Fed"),
                min = min(df$Time,na.rm = TRUE), max = 60 , value = 60 , step = 1),
    
    
    radioButtons("Bedroom", 
                 h1("Bedrooms"), 
                 choices = list("1 Bedroom" = 1, 
                                "2 Bedroom" = 2, 
                                "3 Bedroom" = 3,
                                "4 Bedroom" = 4),
                 selected = character(0), inline = TRUE),
    
    
    radioButtons("Bathroom", 
                 h1("Bathrooms"), 
                 choices = list("1 Bathroom" = 1, 
                                "2 Bathroom" = 2, 
                                "3 Bathroom" = 3,
                                "4 Bathroom" = 4),
                 selected = character(0), inline = TRUE),
    
    width = 275
    
  ),
  
  
  dashboardBody(fluidPage(
    
    fluidRow(
      column(8,
             leafletOutput('map', height = 800)),
      column(4,
             plotOutput("plot")),
      
      column(4, plotOutput("plot2"))
      
      
    )
  ),

    tags$head(tags$style(HTML('
                              /* logo */
                                .skin-blue .main-header .logo {
                              background-color: 0;
                              }
                              
                              /* navbar (rest of the header) */
                              .skin-blue .main-header .navbar {
                              background-color: 0;
                              }
                              
                              /* main sidebar */
                              .skin-blue .main-sidebar {
                              background-color: 0;
                              }
                              
                              /* toggle button when hovered  */
                              .skin-blue .main-header .navbar .sidebar-toggle:hover{
                              background-color: #A020F0;
                              }
                              /* body */
                                .content-wrapper, .right-side {
                                background-color: #FFFFFF;
                                }
                              
                            
                              ')))
  )
  
)  


