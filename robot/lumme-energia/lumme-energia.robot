*** Settings ***
Documentation     Download the Lumme-Energia electricity usage report
Resource          resource.robot
Suite Teardown    Clean Up

*** Test Cases ***
Start the Display
    Start Virtual Display  1920  1080

Report Login
    Open Report Page
    Input User  ${LUMME_USER_ID}
    Input Pass  ${LUMME_PASSWORD}
    Submit Credentials
    Sleep  10s
    Report Page Should Be Open

Download the Sheet
    Report Page Should Be Open
    Open Daily Reporting
    Sleep  2s
    Add SPOT Pricing
    Sleep  4s
    Click Date  ${LUMME_DATE}
    Sleep  5s
    Click Download
    Sleep  15s

Log Out
    Logout
    Sleep  5s
