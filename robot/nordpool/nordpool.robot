*** Settings ***
Documentation     Download the Nordpool day-ahead market data with Chrome
Resource          resource.robot

*** Test Cases ***
Download the Sheet
    Start Virtual Display  1920  1080
    Open Download Page
    Accept Cookies
    Acknowledge Notification
    Sleep  2s
    Acknowledge Notification
    Click Download
    Sleep  5s
    Close Browser
