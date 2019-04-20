# import libraries
import csv
import datetime
import random
import re
import time

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

# Chrome Driver Path
chromePath = r"/Users/byronpoplawski/Downloads/chromedriver"
driver = webdriver.Chrome(chromePath)

# Opening CSV Writer
csv_file = open('Craigslist_Apt_Data_Week_of_' + str(datetime.date)+'.csv', 'w')
csv_writer = csv.writer(csv_file)
csv_writer.writerow(['Title', 'Price', 'Bedroom', 'Bathroom', 'Neighborhood', 'Page Link', 'Address'])

# Regex to extract coordinates from google maps url
p = re.compile(r'([-+]?)([\d]{1,2})(((\.)(\d+)(,)))(\s*)(([-+]?)([\d]{1,3})((\.)(\d+))?)')
g = re.compile(r'.{0,3}[a-zA-Z]{2}')


# FUNCTIONS.............................................................................

# finding page links on page (120 per page)

def FindLinks(pageHTML):
    soup = BeautifulSoup(pageHTML, "lxml")
    linksList = []
    for listing in soup.find_all("li", class_="result-row"):
        aptLink = listing.find('a', class_='result-title hdrlnk')['href'].encode('utf-8')
        linksList.append(aptLink)

    return linksList


def ScrapePage(pageHTML):
    aptInfo = []

    aptSoup = BeautifulSoup(pageHTML, "lxml")

    try:
        rawAptPrice = aptSoup.find("span", class_="price").text.encode('utf-8')
        aptPrice = str.strip(rawAptPrice, "$")
    except:
        print("No price listed")
        aptPrice = 0

    try:
        aptTitle = aptSoup.find('span', id='titletextonly').text.encode('utf-8')

    except:
        print("No title - empty listing")
        aptTitle = "N/A"

    try:
        aptNeighborhood = aptSoup.select_one('span.postingtitletext > small').text

    except:
        print("No neighbordhood listed")
        aptNeighborhood = "N/A"

    try:
        aptRooms = aptSoup.select_one("span.shared-line-bubble").text.encode('utf-8')
        rooms = aptRooms.replace(" ", "").split("/")

        if (len(rooms[0]) > 2):

            aptBedrooms = str.strip(rooms[0], "BR")

        else:

            print("NO BEDROOMS LISTED")
            aptBedrooms = "N/A"

        if (len(rooms[1]) > 2):

            aptBathrooms = str.strip(rooms[1], "Ba")

        else:
            print("NO BATHROOMS LISTED")
            aptBedrooms = "N/A"


    except:

        print("No Room information available")
        aptBedrooms = "N/A"
        aptBathrooms = "N/A"

    pagelink = driver.current_url

    aptInfo.extend((aptTitle, aptPrice, aptBedrooms, aptBathrooms, aptNeighborhood, pagelink))

    return aptInfo


# web scraper loop...................

# Timing the scraper
startTime = time.time()
requests = 0

# NY Craigslist Apartments Page
driver.get('https://newyork.craigslist.org/search/aap')
htmlStartPage = driver.page_source
soupHomePage = BeautifulSoup(htmlStartPage, "lxml")

# Find start and end indices of # of total pages in apartment listings

pageRange = int(soupHomePage.find('span', class_='rangeTo').text.encode('utf-8'))
#totalListCount = int(soupHomePage.find('span', class_="totalcount").text.encode('utf-8'))
totalListCount = 1000
# Create list, scrape apartment page for links to individual listings and fill the list with all links
# the page (120 per page)

links = []
links = FindLinks(htmlStartPage)
i = 1
j = 1
# For each apartment listing, go to link, scrape the page, click google maps section,
# open new page and scrape coordinates from google maps location of apartment

while totalListCount > 0:

    currentUrl = driver.current_url

    for link in links:

        driver.get(link)

        apthtml = driver.page_source

        # calling scrape of apartment listing
        aptInformation = ScrapePage(apthtml)

        # Wait for apartment listing page to load, go to google maps apartment
        # location page and get coordinates from link
        wait = WebDriverWait(driver, 10)
        try:
            element = wait.until(
                EC.element_to_be_clickable((By.XPATH, "/html/body/section/section/section/div[1]/div/p/small/a")))

            driver.find_element_by_xpath("/html/body/section/section/section/div[1]/div/p/small/a").click()
        except:
            print("No google location available")
            continue
        # wait for location in url to populate
        time.sleep(10)

        # This section closes the new tab created - workaround necessary to avoid closing the browser

        windowsOg = driver.window_handles[0]
        windowAfter = driver.window_handles[1]

        driver.switch_to.window(windowAfter)

        # do nothing
        # get coordinates of apartment from google maps url
        aptAddress = driver.current_url
        driver.close()

        # extract coordinates from url using regex - cleaning before input into file

        match = p.search(aptAddress)

        if match != None:

            cleanedAptAddress = match.group(0)
            print(cleanedAptAddress)
            aptInformation.append(cleanedAptAddress)

        else:
            print("Cannot Determine Address/Non available")
            aptInformation = "N/A"

        # switch back to home window
        driver.switch_to.window(windowsOg)

        # wait some time before loading the next page - avoids overwhelming craigslist servers because they will block
        # you if you make too many requests to the site
        time.sleep(random.randint(2, 6))
        requests += 1
        # print statement to check number of requests + frequency of requests
        #     elapsedTime = time.time() - startTime
        #     print('Request:{}; Frequency: {} requests/s'.format(requests, requests / elapsedTime))

        csv_writer.writerow(aptInformation)
        print("writing page: " + str(i) + "apartment: " +str(j))
        j += 1

    # switching pages to get next 120 listings
    driver.get(currentUrl)

    wait = WebDriverWait(driver, 10)
    try:
        element = wait.until(
            EC.element_to_be_clickable((By.XPATH, """//*[@id="searchform"]/div[5]/div[3]/span[2]/a[3]""")))

        driver.find_element_by_xpath("""//*[@id="searchform"]/div[5]/div[3]/span[2]/a[3]""").click()
    except:
        print("No next button to click")

    time.sleep(random.randint(2, 5))
    currentPageSource = driver.page_source

    links = FindLinks(currentPageSource)
    totalListCount -= pageRange
    i += 1

totalTime = time.time() - startTime
minutes = totalTime / 60
seconds = (totalTime / 60) % 60
print("TOTAL SCRIPT RUNNING TIME = " + str(minutes) + " Minutes, " + str(seconds) + " seconds")

csv_file.close()
