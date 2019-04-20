# Craigslist Apartment Search R Shiny App

Try out the app here: [Byron Pop's Craigslist Apartment Search App](https://byronpop.shinyapps.io/CraigslistApartmentsApp/)

## App Description
This is an ongoing project to help me search for apartments in NYC or really any other city. I know Craigslist and Streeteasy have similar functionality but I wanted to make something more personalized (and learn R in the meantime). 

The app allows you to filter by the usual criteria. When you click on an apartment, it gives you the apartment's details, a bar chart showing prices of similar apartments within a 0.25 mile radius, and median prices over the past year for similar apartments in the neighborhood. Right now, it calculates subway commute time to the Federal Reserve of NY (where I work) but you could change it to be any destination (e.g., proximity to Trader Joe's).

<img width="1421" alt="Screen Shot 2019-04-20 at 9 33 59 AM" src="https://user-images.githubusercontent.com/33380363/56457936-aa2aab00-634f-11e9-8e60-afd8ea39e557.png">

## Data
The app uses apartment listings data from Craiglist, neighborhood pricing data from [Streeteasy](https://streeteasy.com/blog/data-dashboard/) and subway stop data from the [NYC MTA website](https://data.cityofnewyork.us/Transportation/Subway-Stations/arq3-7z49). 

Craigslist does not provide an API for obtaining data from their site. Therefore, I built a simple web scraper utilizing selenium and chromedriver to navigate through Craigslist to extract apartment listing information. I then use BeautifulSoup to parse the raw html of each url in a systematic fashion. You can access all of the data in the "Data" tab. 
<img width="1042" alt="Screen Shot 2019-04-10 at 10 05 20 PM" src="https://user-images.githubusercontent.com/33380363/55926159-429d8e80-5bde-11e9-8669-9d5f2834b1c5.png">

## Future Work / Next Steps 
The glaring fault with this app is that it must be manually refreshed each week or so in order be useful. In competitive markets like NYC, new listings appear daily/weekly. My next goal is to set up an AWS server that runs the Python webscraper script daily and refreshes the data.

Streeteasy data refreshes monthly, so the Python script could pull that too. 

Even better would be for me to store my own historical neighborhood pricing data from the Craigslist listings I pull. 

If you have any suggestions on how I might improve this app please let me know. This is also my first project using R, so I certainly would welcome code feedback. 

