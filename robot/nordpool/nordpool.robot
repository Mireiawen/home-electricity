*** Settings ***
Documentation     Download the Nordpool day-ahead market data with Chrome
Resource          resource.robot
Suite Teardown    Clean Up

*** Test Cases ***
Start the Display
    Start Virtual Display  1920  1080

Open the Page
    Open Download Page
    Sleep  4 minutes
    Accept Cookies
    Sleep  10 seconds
    Acknowledge Notification
    Sleep  10 seconds
    Acknowledge Notification
    Sleep  10 seconds

Download the Sheet
    Click Download
