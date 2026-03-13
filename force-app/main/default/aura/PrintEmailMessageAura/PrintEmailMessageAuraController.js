/**
 * Created by tom on 27/11/2024.
 */

({
    doInit : function(component, event, helper) {
        // Get the recordId from the URL
        const urlParams = new URLSearchParams(window.location.search);
        const recordId = urlParams.get('recordId');
        if(recordId) {
            component.set("v.recordId", recordId);
        }
    },

    handleRecordUpdated: function(component, event, helper) {
        const emailMessage = component.get("v.emailMessage");
        if (emailMessage && emailMessage.HtmlBody) {

            // Create email metadata
            const metadata = [
                { label: 'From', value: emailMessage.FromAddress },
                { label: 'To', value: emailMessage.ToAddress }
            ];

            if (emailMessage.CcAddress) {
                metadata.push({ label: 'Cc', value: emailMessage.CcAddress });
            }
            if (emailMessage.BccAddress) {
                metadata.push({ label: 'Bcc', value: emailMessage.BccAddress });
            }

            metadata.push({ label: 'Subject', value: emailMessage.Subject });

            const localDate = new Date(emailMessage.CreatedDate).toLocaleString('en-AU', {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                timeZoneName: 'short'
            });
            metadata.push({ label: 'Date', value: localDate });

            component.set('v.emailMetadata', metadata);

            document.title = `EmailMessage_${emailMessage.Id}`;

            // Set the email body
            const printArea = component.find("printArea").getElement();
            printArea.innerHTML = emailMessage.HtmlBody;

            // Small timeout to allow content to render
            setTimeout(function() {
                helper.waitForImages(component)
                    .then(function() {
                        component.set("v.isLoaded", true);
                        helper.printAndClose(component);
                    });
            }, 100);

        }
    },

    handlePrintClick: function(component, event, helper) {
        window.print();
    },

    handleCloseClick: function(component, event, helper) {
        window.close();
    }
})