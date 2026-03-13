({
    retrieveContactDocumentUrlId : function(component, event, helper) {
        //Parse the URL
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i, j;

        var retrievedContactDocumentId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'cd') { //get the app Id from the parameter
                    retrievedContactDocumentId = sParameterName[j+1];
                }
            }
        }

        if(retrievedContactDocumentId != '') {
            component.set("v.contactDocumentId", retrievedContactDocumentId);
        }
    },
    retrieveFileDetails : function(component, event, helper) {
        var action = component.get("c.retrieveContentDocumentData");
        action.setParams({
            "contactDocumentId" : component.get("v.contactDocumentId")
        });

        action.setCallback(this, function(response){
            var state = response.getState();

            if(state === 'SUCCESS'){
                var result = response.getReturnValue();
                component.set("v.contentDocumentId", result.ContentDocument.Id);
                
                component.set("v.contactDocument", result.ContactDocument);
                component.set("v.contentDocument", result.ContentDocument);
                
                component.set("v.documentName", result.DocumentName);
                component.set("v.documentFileType", result.DocumentFileType);
                
				//Set browser title
                document.title = result.DocumentName;
				
                //Set content distribution url
                component.set("v.documentLink", result.ContentDistribution.DistributionPublicUrl);

                var documentUrl;
                switch(result.DocumentFileType) {
                    case 'doctype:word':
                        documentUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId=' + result.ContentDocument.LatestPublishedVersionId + '&operationContext=CHATTER&page=0';
                        break;
                    case 'doctype:image':
                        documentUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=' + result.ContentDocument.LatestPublishedVersionId + '&operationContext=CHATTER&page=0';
                        break;
                    default:
                        //Show no preview available block
                }

                component.set('v.documentThumbnailLink', documentUrl);
            }
        });

        $A.enqueueAction(action);
    }
})