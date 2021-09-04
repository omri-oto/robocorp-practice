# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Dialogs
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault
# -


*** Keywords ***
Collect url from user
    Add text input    search    label=Where is the order file?
    ${response}=    Run dialog
    [Return]    ${response.search}

*** Keywords ***
Open the robot order website
    ${secret}=  Get Secret  credentials
    Open Available Browser    ${secret}[shop]


*** Keywords ***
Get orders
    [Arguments]   ${file_url}
    Download   ${file_url}   ${CURDIR}${/}output${/}orders.csv   overwrite=True
    ${order_table}=  Read table from CSV    ${CURDIR}${/}output${/}orders.csv
    [Return]    ${order_table}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    id:order
    Click Button    OK

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value   id:head   ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    ${num_legs}=    Convert To String    ${row}[Legs]
    Input Text  xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input  ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Click order and wait
    Wait Until Element is Visible   id:order
    Click Button    id:order
    Wait Until Element Is Visible   id:receipt

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds
    ...     10x
    ...     0.5s
    ...     Click order and wait

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]  ${order_number}
    ${receipt_filepath}=    Convert To String  ${CURDIR}${/}output${/}receipts${/}receipt-${order_number}.pdf
    Wait Until Element Is Visible    id:order-completion
    ${order_completion_html}=   Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_completion_html}   ${receipt_filepath}
    [Return]    ${receipt_filepath}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${robot_snip_filepath}=  Convert to String   ${CURDIR}${/}output${/}snips${/}robo-snip-${order_number}.png
    Screenshot    id:robot-preview-image    ${robot_snip_filepath}
    [Return]    ${robot_snip_filepath}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${screenshots}=  Create List  ${pdf}    ${screenshot}
    Add Files To Pdf    ${screenshots}  ${pdf}  
    Close Pdf   ${pdf}

*** Keywords ***
Go to order another robot
    Wait Until Element Is Visible  id:order-another
    Wait Until Keyword Succeeds
    ...         5x
    ...         0.5s
    ...         Click Button    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip     ${CURDIR}${/}output${/}receipts     ${CURDIR}${/}output${/}receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${file_csv}=    Collect url from user
    Open the robot order website
    ${orders}=    Get orders    ${file_csv}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts



