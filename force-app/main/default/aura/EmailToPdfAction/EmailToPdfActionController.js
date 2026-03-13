/**
 * @author          Tom Gangemi
 * @description    	Aura component for HTML to PDF print button
 * @revision        2022-10-17 - Tom Gangemi - SA-1878 Initial version
 */

({
    doInit : function(cmp) {
        const recordId = cmp.get('v.recordId');
        var callbackHandled = false;
        console.log('Called: EmailToPdfAction.doInit');

        const b64toBlob = function(b64Data, contentType) {
            const byteCharacters = atob(b64Data);
            const byteArrays = []; // array of Uint8Array
            const sliceSize = 512;

            for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
                const slice = byteCharacters.slice(offset, offset + sliceSize);

                const byteNumbers = new Array(slice.length);
                for (let i = 0; i < slice.length; i++) {
                    byteNumbers[i] = slice.charCodeAt(i);
                }
                // convert array of byte values into a typed byte array
                const byteArray = new Uint8Array(byteNumbers);
                byteArrays.push(byteArray);
            }

            // construct blob from byte array
            const blob = new Blob(byteArrays, {type: contentType});
            return blob;
        }

        // setup call to Apex method
        const action = cmp.get("c.getEmailAsBase64PdfBlob");
        action.setParams({ emailMessageId : recordId });
        action.setCallback(this, function(response) {
            if(callbackHandled) {
                // skipped duplicate callback
                return;
            }
            callbackHandled = true;

            var message = 'Error Generating PDF';
            var state = response.getState();

            if (state === 'SUCCESS') {
                const data = response.getReturnValue();
                console.log('PDF Blob Retrieved OK');

                // convert base64 string into blob
                const pdfBlob = b64toBlob(data, 'application/pdf');
                const fileURL = window.URL.createObjectURL(pdfBlob);

                // set link and download it
                const link = cmp.find('link').getElement();
                link.href = fileURL;
                link.download = 'EmailMessage_'+recordId+'.pdf';
                link.click();

                // close modal
                var dismissActionPanel = $A.get('e.force:closeQuickAction');
                dismissActionPanel.fire();

                message = 'Starting Download';
            }
            else if (state === 'INCOMPLETE') {
                message = 'Network Error - Try Again';
            }
            else if (state === 'ERROR') {
                var errors = response.getError();
                let errMsg = 'Unknown';
                if (errors && errors[0] && errors[0].message) {
                    errMsg = errors[0].message;
                    if(errMsg.toLowerCase().startsWith('you do not have access')) {
                        message = 'You do not have access to this feature';
                    }
                }
                console.log('Error:', errMsg);
            }

            // update UI
            cmp.set('v.loading', false);
            cmp.set('v.message', message);
        });

        // call apex
        $A.enqueueAction(action);
    }
});