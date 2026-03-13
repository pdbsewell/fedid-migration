({
    init:function(component,event,helper){  
        component.set("v.showSpinner",true);
        component.set("v.showCaseAttachment",false);
        helper.getAllowedFileType(component);
        $("#topDiv").css("background-color","#f6f6f6");
        component.set("v.isOpen",false);        
        helper.getCaseDetails(component, event, helper);
        $('#replySection').hide();
        //console.log('upload div is '+$('#uploadDiv'));
        /*$("#uploadFile").click(function () {
            $("#file-upload").trigger('click');
        });*/
        $('#uploadDiv').on(
            'dragover',
            function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('in drag over');
            }
        );
        console.log('drag over overridden');
        $('#uploadDiv').on(
            'dragenter',
            function(e) {
                e.preventDefault();
                e.stopPropagation();
                console.log('in drag center');
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
                        var fileInput = component.find("file").getElement();
                        //start
                        var currentFiles=component.get("v.fileList")==null?[]:component.get("v.fileList");
                        if(currentFiles.length+e.originalEvent.dataTransfer.files.length > 5){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "message": "You can select only 5 files"
                            });            
                            toastEvent.fire();  
                            component.find("file").reset();            
                            return; 
                        }
                        for(var i=0;i<e.originalEvent.dataTransfer.files.length;i++) {
                            console.log('checking extension');
                            console.log('file name is '+e.originalEvent.dataTransfer.files[i].name);
                            var fileName=e.originalEvent.dataTransfer.files[i].name;
                            var extension=fileName.substring(fileName.lastIndexOf(".")+1, fileName.length);
                            console.log('extension is '+extension);
                            if(allowedFileTypes.lastIndexOf(extension.toUpperCase())==-1) {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
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
                        console.log(' currentFiles.length after is '+currentFiles.length);
                        var file = currentFiles;
                        var fileNames = [];
                        
                        if(file.length==0) {
                            $("#selectedFiles").hide();
                            component.set("v.selectedFiles",fileNames);
                            return;
                        }
                        if(file.length > 5){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "message": "You can select only 5 files"
                            });
                            toastEvent.fire();     
                            component.find("file").reset();                            
                            return; 
                        } 
                        var totalSize=0;
                        for(var i=0;i<file.length;i++) {
                            totalSize=totalSize+file[i].size;
                            if (totalSize > 3000000) {
                                var toastEvent = $A.get("e.force:showToast");
                                toastEvent.setParams({
                                    "title": "Error!",
                                    "message": "We couldn't upload the selected file.The maximum file size allowed is 3MB.",
                                    "duration": 9000
                                });                
                                toastEvent.fire();   
                                component.find("file").reset();                                
                                return;
                            }
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
                        //end       
                    }   
                }
            }
        );
        
        var num = 20;
        var num_two = 4;
        // keydown event
        $(".rttext").keydown(function(e) {
            var code = (e.keyCode ? e.keyCode : e.which);
            if(code == 13) {
                var pos = $(".threedot-btn").position();  
                $(".threedot-btn").css({
                    top: pos.top+num+"px"
                });
                $(this).height( $(".rttext")[0].scrollHeight );
            } 
        });
        
        // keyup event
        $(".rttext").keyup(function(e) {
            var code = (e.keyCode ? e.keyCode : e.which);
            if(code == 8) {
                var pos = $(".threedot-btn").position();   
                $(".threedot-btn").css({
                    top: pos.top-num_two+"px"
                });
            } 
        });
        
    },
    
    updateEnquiry : function(component, event, helper) {
        console.log('in component updateEnquiry start');
        if(component.get("v.myComments")==null || component.get("v.myComments")==''){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please add comments"
            });
            toastEvent.fire();             
            return; 
        }  
        var file = component.get("v.fileList");         
        if(file!=null && file.length>5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "You can select only 5 files"
            });
            toastEvent.fire();             
            return; 
        }
        component.set("v.showSpinner",true);
        helper.attachmentsave(component, event, helper);  
    },
    showEnquiryForm : function(component, event, helper) {
        helper.showEnquiryForm(component, event, helper);
    },
    closeEnquiry : function(component, event, helper) {
        console.log('in closeEnquiry');
        component.set('v.enquiryClosed',true);
        var caseId=component.get("v.recordId"); 
        var action = component.get("c.closeEnq");
        action.setParams({"caseId":caseId});      
        console.log(action);
        action.setCallback(this, function(a) {
            var rtnValue = a.getReturnValue();   
            console.log('in callback');
            helper.getCaseDetails(component,event,helper); 
            component.set("v.myComments",null);
            component.set("v.showSpinner",false);
       });
        console.log('caseId is111 '+caseId);
       $A.enqueueAction(action);           
       component.set("v.isOpen",true);
    },
    upload : function(component,event,helper) {
        console.log('in upload');
        var currentFiles=component.get("v.fileList")==null?[]:component.get("v.fileList");
        var fileInput = component.find("file").getElement();
        var allowedFileTypes=component.get("v.allowedFileTypes");
        if(currentFiles.length+fileInput.files.length > 5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "You can select only 5 files"
            });            
            toastEvent.fire();  
            component.find("file").reset();            
            return; 
        }
        for(var i=0;i<fileInput.files.length;i++) {
            var extension=fileInput.files[i].name.substring(fileInput.files[i].name.lastIndexOf(".")+1, fileInput.files[i].name.length);
            console.log('extension is '+extension);
            if(allowedFileTypes.lastIndexOf(extension.toUpperCase())==-1) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
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
        console.log(' currentFiles.length after is '+currentFiles.length);
        var file= currentFiles;
        if(currentFiles.length==0)
        {
            console.log('No file selected returning');
            return;
        }
        if(currentFiles.length > 5){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "You can select only 5 files"
            });            
            toastEvent.fire();  
            component.find("file").reset();            
            return; 
        }         
        var fileNames = [];
        var totalSize=0;
        for(var i=0;i<file.length;i++) {
            console.log('file[i].name.length is '+file[i].name.length);
            totalSize=totalSize+file[i].size;
            console.log('file[i].name is '+file[i].name);
            console.log('file[i].size is '+file[i].size);
            console.log('totalSize is '+totalSize);
            if (totalSize > 3000000) {
                var toastEvent = $A.get("e.force:showToast");
            	toastEvent.setParams({
                	"title": "Error!",
                	"message": "We couldn't upload the selected file.The maximum file size allowed is 3MB.",
                    "duration": 9000
            	});                
            	toastEvent.fire();	
                component.find("file").reset();                
                return;
            }
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
            component.set("v.selectedFiles",fileNames);
        }         
        component.set("v.fileList",file);             
    },
    showHideDescription: function(component,event,helper) {
        var emailClicked = event.getSource().get("v.name");
        var emailList=component.get("v.emailList");
        for(var i=0;i<emailList.length;i++) {
            if(emailList[i].emailId===emailClicked) {
                emailList[i].showBody=!emailList[i].showBody;
            }
        }        
        component.set("v.emailList",emailList);
    },
    showFullBody: function(component,event,helper) {
       var emailClicked = event.getSource().get("v.name");
        var emailList=component.get("v.emailList");
        for(var i=0;i<emailList.length;i++) {
            if(emailList[i].emailId===emailClicked) {
                emailList[i].showFullBody=!emailList[i].showFullBody;
            }
        }        
        component.set("v.emailList",emailList);        
    },
    showlastCommunication: function(component,event,helper) {  
        component.set("v.hidelastCommunication",false);
    },
    showPreviousCommunication: function(component,event,helper) {  
        var emailList=component.get("v.emailList");
        for(var i=0;i<emailList.length;i++) {
            emailList[i].isVisible=true;
        }        
        component.set("v.emailList",emailList);
        component.set("v.showPrevConversation",true);        
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
            //console.log('file[i].name is '+file[i].name);
            var fileName=file[i].name;
            if(fileName.length>30)
            {
                var length=30;
                var extension=fileName.substring(fileName.lastIndexOf("."), fileName.length);
                var availablelength=length-2-extension.length;
                fileName=fileName.substring(0, availablelength)+'~1'+extension;
            }
            //console.log('file[i].name after truncation is '+fileName);
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
            //console.log('file[i].name after truncation is '+fileName);
            if(fileName!=fileTobeRemoved) {
                newFiles.push(selectedFiles[i]);
            }        
			if(fileName==fileTobeRemoved) {
                console.log('file removed from selected files is '+fileName);           
            }            
        }
        console.log('newFiles is '+newFiles);
        console.log('newFileList is '+newFileList);
        //component.find("file").reset();
        component.set("v.selectedFiles",newFiles);
        component.set("v.fileList",newFileList);
    },
    showReplySection: function(component,event,helper) {
    	component.set("v.showReplySection",true);
        component.set("v.hidelastCommunication",true);
        component.set("v.selectedFiles",[]);
        component.set("v.fileList",null); 
        $('#replySection').show();
    },
    hideReplySection: function(component,event,helper) {
    	component.set("v.showReplySection",false);
        component.set("v.hidelastCommunication",true);
        component.set("v.selectedFiles",[]);
        component.set("v.fileList",null);
        $('#replySection').hide();
    },
    clickFileUpload : function(component,event,helper){
        $("#file-upload").trigger('click')
    },
    showHideAttachment : function (component,event,helper) {
        console.log("in showHideAttachment");
        console.log("flag is "+component.get("v.showCaseAttachment"));
        var x=component.get("v.showCaseAttachment")==false?true:false;
        console.log("x is "+x);
        component.set("v.showCaseAttachment",x);
    }
})