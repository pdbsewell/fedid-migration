({
    init : function(component, event, helper) {
        console.log('in init');
        helper.getUserFirstName(component);
        //helper.getExistingApplications(component); MC-1157 - remove checking of existing applications
        helper.getUserType(component);
        helper.getAllowedFileType(component);
        component.set("v.filesProcessed",0);

        $("#uploadFile").click(function () {
            $("#file-upload").trigger('click');
        });
        $('#uploadDiv').on(
            'dragover',
            function(e) {
                console.log('in dragover');
                e.preventDefault();
                e.stopPropagation();
            }
        );
        $('#uploadDiv').on(
            'dragenter',
            function(e) {
                console.log('in dragenter');
                e.preventDefault();
                e.stopPropagation();
            }
        );
        $('#uploadDiv').on(
            'drop',
            function(e){
                if(e.originalEvent.dataTransfer){
                    if(e.originalEvent.dataTransfer.files.length) {
                        e.preventDefault();
                        e.stopPropagation();
                        var allowedFileTypes=component.get("v.allowedFileTypes");
                        console.log('allowedFileTypes is '+allowedFileTypes);
                        var currentFiles=component.get("v.fileList")==null?[]:component.get("v.fileList");
                        console.log(' currentFiles is '+currentFiles);
                        console.log(' e.originalEvent.dataTransfer.files.length is '+e.originalEvent.dataTransfer.files.length);
                        if(currentFiles.length+e.originalEvent.dataTransfer.files.length > 5){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type": "warning",
                                "title": "Warning!",
                                "message": "You can select only 5 files"
                            });
                            toastEvent.fire();
                            component.find("file").reset();
                            return;
                        }
                        for(var i=0;i<e.originalEvent.dataTransfer.files.length;i++) {
                            var fileName=e.originalEvent.dataTransfer.files[i].name;
                            var extension=fileName.substring(fileName.lastIndexOf(".")+1, fileName.length);
                            console.log('extension is '+extension);
                            if(allowedFileTypes.lastIndexOf(extension.toUpperCase())==-1) {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "type": "error",
                                    "title": "Error!",
                                    "message": "File Type "+extension+" is not allowed"
                                });
                                toastEvent.fire();
                                component.find("file").reset();
                                return;
                            }
                        }
                        for(var i=0;i<e.originalEvent.dataTransfer.files.length;i++) {
                            console.log('adding  file'+e.originalEvent.dataTransfer.files[i]);
                            currentFiles.push(e.originalEvent.dataTransfer.files[i]);
                        }
                        var file = currentFiles;
                        var fileNames = [];

                        if(file.length==0) {
                            $("#selectedFiles").hide();
                            component.set("v.selectedFiles",fileNames);
                            return;
                        }
                        for(var i=0;i<file.length;i++) {
                            console.log('file[i].name.length is '+file[i].name.length);
                            if(file[i].name.length>30)
                            {
                                var length=30;
                                var extension=file[i].name.substring(file[i].name.lastIndexOf("."), file[i].name.length);
                                var availablelength=length-2-extension.length;
                                fileNames.push(file[i].name.substring(0, availablelength)+'~1'+extension);
                            }
                            else {
                                fileNames.push(file[i].name);
                            }
                            console.log('>>>>>>>>>>'+file[i].name);
                        }

                        if(fileNames.length>0){
                            $("#att-heading").show();
                            component.set("v.selectedFiles",fileNames);
                        }
                        component.set("v.fileList",file);
                        component.find("file").reset();
                        //end                        
                    }
                }
            }
        );
    },
    removeFile : function(component,event,helper) {
        component.set("v.isButtonClicked",false);
        var selectedFiles=component.get("v.selectedFiles");
        var fileInput = component.find("file").getElement();
        var file = component.get("v.fileList");
        var newFileList=[];
        var fileTobeRemoved=event.getSource().get("v.value");
        console.log('fileTobeRemoved is '+fileTobeRemoved);
        for(var i=0;i<file.length;i++) {
            var fileName=file[i].name;
            if(fileName.length>30)
            {
                var length=30;
                var extension=fileName.substring(fileName.lastIndexOf("."), fileName.length);
                var availablelength=length-2-extension.length;
                fileName=fileName.substring(0, availablelength)+'~1'+extension;
            }
            if(fileName!=fileTobeRemoved) {
                newFileList.push(file[i]);
            }
            if(fileName==fileTobeRemoved) {
                console.log('file removed is '+fileName);
            }
        }
        var newFiles=[];
        for(var i=0;i<selectedFiles.length;i++)
        {
            var fileName=selectedFiles[i];
            if(fileName.length>30)
            {
                var length=30;
                var extension=fileName.substring(fileName.lastIndexOf("."), fileName.length);
                var availablelength=length-2-extension.length;
                fileName=fileName.substring(0, availablelength)+'~1'+extension;
            }
            if(fileName!=fileTobeRemoved) {
                newFiles.push(selectedFiles[i]);
            }
            if(fileName==fileTobeRemoved) {
                console.log('file removed from selected files is '+fileName);
            }
        }
        component.set("v.selectedFiles",newFiles);
        component.set("v.fileList",newFileList);
    },
    captureupload : function(component, event, helper) {

        console.log('captureLoad>>');
        var currentFiles=component.get("v.fileList")==null?[]:component.get("v.fileList");
        console.log(' currentFiles is '+currentFiles);
        var fileInput = component.find("file").getElement();
        var allowedFileTypes=component.get("v.allowedFileTypes");
        if(currentFiles.length + fileInput.files.length > 5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error!",
                "message": "You can select only 5 files"
            });
            toastEvent.fire();
            component.find("file").reset();
            return;
        }
        for(var i=0;i<fileInput.files.length;i++) {
            var extension=fileInput.files[i].name.substring(fileInput.files[i].name.lastIndexOf(".")+1, fileInput.files[i].name.length);
            if(allowedFileTypes.lastIndexOf(extension.toUpperCase())==-1) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error!",
                    "message": "File Type "+extension+" is not allowed"
                });
                toastEvent.fire();
                component.find("file").reset();
                return;
            }
        }
        for(var i=0;i<fileInput.files.length;i++) {
            currentFiles.push(fileInput.files[i]);
        }
        var file = currentFiles;
        var fileNames = [];

        if(file.length==0) {
            $("#selectedFiles").hide();
            component.set("v.selectedFiles",fileNames);
            return;
        }

        for(var i=0;i<file.length;i++) {
            console.log('file[i].name.length is '+file[i].name.length);
            if(file[i].name.length>30)
            {
                var length=30;
                var extension=file[i].name.substring(file[i].name.lastIndexOf("."), file[i].name.length);
                console.log('extension is '+extension);
                var availablelength=length-2-extension.length;
                console.log('availablelength is '+availablelength);
                console.log('file[i].name.substring(0, availablelength) is '+file[i].name.substring(0, availablelength));
                fileNames.push(file[i].name.substring(0, availablelength)+'~1'+extension);
            }
            else{
                fileNames.push(file[i].name);
            }
            console.log('from captureupload method >>>>>>>>>>'+file[i].name);
        }

        if(fileNames.length>0){
            $("#att-heading").show();
            component.set("v.selectedFiles",fileNames);
        }
        component.set("v.fileList",file);
        component.find("file").reset();
    },
    redirectPrivacyStatement: function(component, event, helper) {
        helper.redirectPrivacyStatement(component,event);
    },
    redirectHomePage: function(component,event,helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/thank-you"
        });
        urlEvent.fire();
    },
    save : function (component, event, helper) {
        if(component.get("v.isButtonClicked")!=true) {
            component.set("v.filesProcessed",0);
            component.set("v.isButtonClicked",true);
            helper.Save(component, event,helper);
        }
    },
    
    handleCheckboxChange: function (component, event, helper) {
      	var cbox = event.getSource().get("v.name");
        var ischecked = event.getSource().get("v.checked")
        console.log(cbox + ": " + ischecked);
        if(cbox === "consent"){
            component.set("v.consentCenterLink",ischecked);
        }else if(cbox === "grant-consent"){
            component.set("v.consentForm",ischecked);
        }else{
            component.set("v.consentFormVicGov",ischecked);
        }
    },
    validateRequiredFields: function(component, event, helper) {
        var isIncomplete = false; //needs to be on negative perspective for 'disabled' attribute
        var phoneField = component.find('phone').get("v.value");
        var amount = component.find('amount').get("v.value");
        
        console.log('consent ' + consent);
        console.log('grantConsent ' + grantConsent);
		if(phoneField != '' && amount != '') {
            isIncomplete = false;
        }
        component.set("v.disableSubmit", isIncomplete);
    }
})