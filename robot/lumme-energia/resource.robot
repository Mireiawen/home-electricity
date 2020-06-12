*** Settings ***
Documentation     A resource file with reusable keywords and variables.
Library           SeleniumLibrary
Library           XvfbRobot

*** Variables ***
${REPORT_URL}      https://helmi.sssoy.fi/EnergyReporting/EnergyReporting
${LUMME_USER_ID}   1234
${LUMME_PASSWORD}  xxxx
${LUMME_DATE}      2020-01-01

*** Keywords ***
Open Report Page
    Open Browser  ${REPORT_URL}  Chrome
    Maximize Browser Window
    Login Page Should Be Open

Login Page Should Be Open
    Title Should Be  Authentication

Report Page Should Be Open
    Title Should Be  EnergyReporting

Input User
    [Arguments]  ${username}
    Input Text   id:UserName  ${username}

Input Pass
    [Arguments]  ${password}
    Input Password  id:Password  ${password}

Submit Credentials
    Click Button  id:bLogin

Open Daily Reporting
    ${dailyreport}=  Get WebElement  css:div#DeliverysiteReportContainer label
    Click Element    ${dailyreport}

Add SPOT Pricing
    Click Element  id:opt-SPOT

Click Date
    [Arguments]  ${date}
    Click Link   jquery:a[data-moment='${date}']

Click Download
    Click Button  id:ActionGroupDownload

Logout
    Report Page Should Be Open
    Click Element  css:span.glyphicon-off

Clean Up
    Close Browser
