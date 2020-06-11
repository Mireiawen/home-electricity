*** Settings ***
Documentation     Download the Nordpool day-ahead market data with Chrome
Resource          resource.robot
Suite Teardown    Clean Up

*** Test Cases ***
Start the Display
    Start Virtual Display  1920  1080

Open the Page
    Open Download Page
    Accept Cookies
    Acknowledge Notification
    Sleep  2s
    Acknowledge Notification
    Sleep  1s

Download the Sheet
    Click Download
