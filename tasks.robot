*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             Browser
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser
Library             RPA.Windows
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         5x
${GLOBAL_RETRY_INTERVAL}=       5s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
        Log    ${row}
    END
    [Teardown]    Create a ZIP file of the receipts

Minimal task
    Log    Done.


*** Keywords ***
Open the robot order website
    Browser.Open Browser
    Log    Open the robot order website
    ${website}=    Get Secret    OrderBotSite
    New Page    ${website}[website]
    #    New Page    https://robotsparebinindustries.com/#/robot-order

Input form dialog
    Add heading    Send feedback
    Add text input    orders    label=CSV file link
    Add text input    message
    ...    label=Feedback
    ...    placeholder=Enter feedback here
    ...    rows=5
    ${result}=    Run dialog
    RETURN    ${result.orders}    ${result.message}

Get orders
    Log    Get orders
    ${result}=    Input form dialog
    RPA.HTTP.Download    ${result}[0]    overwrite=True
    #    RPA.HTTP.Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${CURDIR}/orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Log    Close the annoying modal
    Browser.Click    css=button[class="btn btn-dark"]

Fill the form
    [Arguments]    ${row}
    Log    Fill the form
    Select Options By    select[name=head]    value    ${row}[Head]
    Check Checkbox    id=id-body-${row}[Body]
    Fill Text    css=input[type="number"]    ${row}[Legs]
    Fill Text    id=address    ${row}[Address]

Preview the robot
    Log    Preview the robot
    Browser.Click    id=preview

Order the robot
    Browser.Click    id=order
    Wait For Elements State    id=receipt    visible    timeout=5 s

Submit the order
    Log    Submit the order
    TRY
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Order the robot
    EXCEPT
        Order the robot
    END

Store the receipt as a PDF file
    [Arguments]    ${Order Number}
    Log    Store the receipt as a PDF file
    ${receipt_html}=    Browser.Get Element    id=receipt
    ${receipt_html}=    Browser.Get Property    id=receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_results_${Order Number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}receipt_results_${Order Number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order Number}
    Log    Take a screenshot of the robot
    Take Screenshot    ${OUTPUT_DIR}${/}receipts${/}screenshot    id=robot-preview-image
    RETURN    ${OUTPUT_DIR}${/}receipts${/}screenshot.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    Embed the robot screenshot to the receipt PDF file
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    #    Close Pdf    ${pdf}

Go to order another robot
    Log    Go to order another robot
    Browser.Click    id=order-another
    Wait For Elements State    css=div[class="modal-body"]    visible    timeout=5 s

Create a ZIP file of the receipts
    Log    Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_file_name}
