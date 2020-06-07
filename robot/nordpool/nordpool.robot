*** Settings ***
Documentation     Download the Nordpool day-ahead market data with Chrome and upload to remote server with SCP
Resource          resource.robot
Resource          ../secrets.robot

*** Test Cases ***
Download the Sheet
    Open Download Page
    Accept Cookies
    Acknowledge Notification
    Sleep  2s
    Acknowledge Notification
    Click Download
    Sleep  5s
    Close Browser

Upload the Sheet
    Open Connection  ${SCP_HOST}  username=${SCP_USER}
    Put File         ${LOCAL_SHEET}  ${SCP_SHEET}
    Close Connection

Remove the Sheet
    Remove File      ${LOCAL_SHEET}
