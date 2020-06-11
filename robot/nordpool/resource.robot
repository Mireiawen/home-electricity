*** Settings ***
Documentation     A resource file with reusable keywords and variables.
Library           SeleniumLibrary
Library           XvfbRobot

*** Variables ***
${BROWSER}        Chrome
${DOWNLOAD_URL}   https://www.nordpoolgroup.com/Market-data1/Dayahead/Area-Prices/FI/Hourly/?view=table

*** Keywords ***
Open Download Page
    Open Browser  ${DOWNLOAD_URL}  ${BROWSER}
    Maximize Browser Window
    Download Page Should Be Open

Download Page Should Be Open
    Title Should Be  Market data | Nord Pool

Accept Cookies
    Click Button  class:pure-button

Acknowledge Notification
    ${element} =  Get WebElement  class:notificationAcknowledge
    Click Image  ${element}

Click Download
    Click Element  class:export-xls

Clean Up
    Close Browser
