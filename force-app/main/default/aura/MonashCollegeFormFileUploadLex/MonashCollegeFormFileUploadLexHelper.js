({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,     //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event) {
        //Show spinner
        this.show(component, event);
        
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]  
        var file = fileInput[0];
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        if (file.size > self.MAX_FILE_SIZE) {
            //hide spinner
            this.hide(component, event);
            component.set("v.fileName", 'Error : File size cannot exceed ' + self.MAX_FILE_SIZE/1000000 + ' MB.' + ' Selected file size: ' + (file.size/1000000).toFixed(2) + ' MB.');
            return;
        }
 
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
 
            fileContents = fileContents.substring(dataStart);
            // call the uploadProcess method 
            self.uploadProcess(component, file, fileContents);
        });
 
        objFileReader.readAsDataURL(file);
    },
 
    uploadProcess: function(component, file, fileContents) {
        // set a default size or startpostiton as 0 
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
 
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '');
    },
 
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId) {
        // call the apex method 'saveChunk'
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get("c.saveChunk");
        action.setParams({
            parentId: component.get("v.parentId"),
            fileName: component.get("v.fileCategory") + ' - ' + file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileId: attachId
        });

        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    //Retrieve all documents related to the application
                    this.retrieveContentDocuments(component, event);
                    
                    //Reset uploader
                    component.set("v.fileName","");
                    component.find("fileId").get("v.files","");
                    
                    //Hide spinner
                    this.hide(component, event);
                }
                
                // handle the response errors        
            } else if (state === "INCOMPLETE") {
                  console.log('Error');
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    
    retrieveContentDocuments: function(component, event) {
        //Only run when there is a parent id on the lightning component
        if(component.get("v.parentId")){
            //Show spinner
            this.show(component,event);
    	    
    	    //Initialize Action
            var action = component.get("c.getAttachments");
            
            //Set Id of Application
            action.setParams({ parentId : component.get("v.parentId") });
            
            // Create a callback that is executed after the server-side action returns
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //Set ids and names of documents
                    var documentItems = [];
                    var documentNames = []; 
                    
                    //Reset variables
                    component.set("v.uploadedContentDocuments", null);
                    component.set("v.uploadedContentDocumentNames", null);
                    
                    //Return uploaded files details
                    for(var uploadedDocumentCounter in response.getReturnValue()){
                        var documentTitle = response.getReturnValue()[uploadedDocumentCounter].Title;
    
                        if(documentTitle.includes(component.get("v.fileCategory"))){
                            documentNames.push(documentTitle);
                        }
                        
                        if(documentTitle.includes(component.get("v.fileCategory"))){
                            documentItems.push(response.getReturnValue()[uploadedDocumentCounter]);
                        }
                    }
                    
                    var validFileTypes = [];
                    validFileTypes.push('ai');
                    validFileTypes.push('attachment');
                    validFileTypes.push('audio');
                    validFileTypes.push('box_notes');
                    validFileTypes.push('csv');
                    validFileTypes.push('eps');
                    validFileTypes.push('excel');
                    validFileTypes.push('exe');
                    validFileTypes.push('flash');
                    validFileTypes.push('folder');
                    validFileTypes.push('gdoc');
                    validFileTypes.push('gdocs');
                    validFileTypes.push('gform');
                    validFileTypes.push('gpres');
                    validFileTypes.push('gsheet');
                    validFileTypes.push('html');
                    validFileTypes.push('image');
                    validFileTypes.push('keynote');
                    validFileTypes.push('library_folder');
                    validFileTypes.push('link');
                    validFileTypes.push('mp4');
                    validFileTypes.push('overlay');
                    validFileTypes.push('pack');
                    validFileTypes.push('pages');
                    validFileTypes.push('pdf');
                    validFileTypes.push('ppt');
                    validFileTypes.push('psd');
                    validFileTypes.push('quip_doc');
                    validFileTypes.push('quip_sheet');
                    validFileTypes.push('rtf');
                    validFileTypes.push('slide');
                    validFileTypes.push('stypi');
                    validFileTypes.push('txt');
                    validFileTypes.push('unknown');
                    validFileTypes.push('video');
                    validFileTypes.push('visio');
                    validFileTypes.push('webex');
                    validFileTypes.push('word');
                    validFileTypes.push('xml');
                    validFileTypes.push('zip');
                    validFileTypes.push('jpg');
                    validFileTypes.push('jpeg');
                    validFileTypes.push('png');
                    validFileTypes.push('gif');
                    
                    var validImageFileTypes = [];
                    validImageFileTypes.push('png');
                    validImageFileTypes.push('jpg');
                    validImageFileTypes.push('jpeg');
                    validImageFileTypes.push('tiff');
                    validImageFileTypes.push('tif');
                    validImageFileTypes.push('gif');
                    validImageFileTypes.push('xps');
                    
                    //Default file extension
                    for(var documentItemCounter in documentItems){
                        //Image files
                        if(validImageFileTypes.includes(documentItems[documentItemCounter].FileExtension)){
                            documentItems[documentItemCounter].FileExtension = 'image';
                        }
                        //Default to unknown
                        if(!validFileTypes.includes(documentItems[documentItemCounter].FileExtension)){
                            documentItems[documentItemCounter].FileExtension = 'unknown';
                        }
                        //Remove name title type
                        var splitTitle = documentItems[documentItemCounter].Title.split(' - ');
                        documentItems[documentItemCounter].Title = splitTitle[1];
                        //Remove extension from name
                        var splitTitle = documentItems[documentItemCounter].Title.split('.');
                        documentItems[documentItemCounter].Title = splitTitle[0];
                    }
                    
                    //Pass values to component
                    component.set("v.uploadedContentDocuments", documentItems);
                    component.set("v.uploadedContentDocumentNames", documentNames);
                    
                    //Hide spinner
                    this.hide(component, event);
                }
                else if (state === "INCOMPLETE") {
                    // do something
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                     errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
    
            $A.enqueueAction(action);
        }
    },
    
    show: function (component, event) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
    
    hide:function (component, event) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    }
})