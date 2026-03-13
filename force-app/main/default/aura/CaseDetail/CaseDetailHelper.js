({
	MAX_FILE_SIZE:  3000000,
    CHUNK_SIZE: 900 000,
    getCaseDetails : function(component, event, helper) {
    	//component.set("v.showSpinner",true);
		var caseId=component.get("v.recordId");        
        var action = component.get("c.getCaseDetails");       
        var pageSize=2;
        action.setParams({"caseId":caseId});
        action.setCallback(this, function(a) {
            var result=a.getReturnValue();
            pageSize=result.pageSize;
            component.set("v.caseDetails",result);  
            component.set("v.AttachmentList",result.attachmentList);            
            component.set("v.emailList",result.emailMessageList);            
            component.set("v.showSpinner",false);    
            component.set("v.filesProcessed",0);
            component.set("v.fileList",null);
            component.set("v.selectedFiles",[]);
            component.set("v.showReplySection",false);
            component.set("v.showCaseAttachment",false);
            $('#replySection').hide();
            if(result.emailMessageList.length<=5) {
                component.set("v.showPrevConversation",true);
            }
        });
        $A.enqueueAction(action);
	},    
    updateEnquiry : function(component, event, helper) {
        component.set("v.showSpinner",false);
        console.log('In updateEnquiry');
        
        var enquiryClosed = component.get("v.enquiryClosed");
        var rtnValue;
        var caseId=component.get("v.recordId");      
        var action = component.get("c.updateEnq");       
        var comments =enquiryClosed==true?null:component.get("v.myComments");
        action.setParams({"comments":comments, "caseId":caseId,"enquiryClosed":enquiryClosed});
        console.log('enquiryClosed is '+enquiryClosed);
        console.log('caseId is '+caseId);
        console.log('comments is '+comments);
        action.setCallback(this, function(a) {
            console.log('in callback');
            rtnValue = a.getReturnValue();   
            console.log('case updated');
            helper.getCaseDetails(component,event,helper); 
            component.set("v.myComments",null);
            component.set("v.showSpinner",false);
       });
       $A.enqueueAction(action);   
        
	},
    showEnquiryForm : function(component, event, helper) {
        $('#enquiryButton').hide();
        $('#enquiryForm').show();         
	},
    getAllowedFileType : function(component) {
        var action = component.get("c.getAllowedFileTypes");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.allowedFileTypes", response.getReturnValue());
                console.log('response.getReturnValue() is '+response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }, 
    attachmentsave : function(component,event,helper) {
        console.log('in attachmentsave');
        var file = component.get("v.fileList");     
        if(file==null || file.length == 0){ 
            helper.updateEnquiry(component, event, helper);  
            return;
        }
        for(var i=0;i<file.length;i++){
            if (file[i].size > this.MAX_FILE_SIZE) {
                var toastEvent = $A.get("e.force:showToast");
            	toastEvent.setParams({
                	"title": "Error!",
                	"message": "We couldn't upload the selected file.The maximum file size allowed is 3MB.",
                    "duration": 9000
            	});
            	toastEvent.fire();	
                component.set("v.showSpinner",false);
                return;
            }
            var self = this;
            reader(file[i],self);            
        }
        
        function reader(file,self){
            var fr = new FileReader();
            component.set("v.showSpinner",true);
            //console.log("in reader");
            fr.onload = $A.getCallback(function() { 
                var fileContents = fr.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                //console.log("in onload");
                fileContents = fileContents.substring(dataStart);
                helper.upload(component, file, fileContents,helper,event);
                
            });
            
            fr.readAsDataURL(file);
            //component.set("v.showSpinner",false);
        }
        
    },
    upload: function(component, file, fileContents,helper,event) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        helper.uploadChunk(component, file, fileContents, fromPos, toPos, '',helper,event); 
    },
    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId,helper,event) {
        var action = component.get("c.saveTheFile"); 
        var self = this;
        var chunk = fileContents.substring(fromPos, toPos);
        var isLastchunk=fromPos+self.CHUNK_SIZE>=toPos?true:false;
        var comments=component.get("v.myComments");
        var caseId=component.get("v.recordId");
        console.log('uploading file '+file.name);
		action.setParams({
            parentId: component.get("v.recordId") ,
            fileName: '$community$'+file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId
        });
       
        
        action.setCallback(this, function(a) {
            var state = a.getState();
            attachId = a.getReturnValue();   
            console.log('attachId is '+attachId);
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);    
            if (fromPos < toPos) {
            	helper.uploadChunk(component, file, fileContents, fromPos, toPos, attachId,helper,event);  
            }
            else
            {
                console.log("filesProcessed is "+component.get("v.filesProcessed"));
                var f=component.get("v.selectedFiles");
                console.log("files is "+f);
                console.log("total files is "+f.length);
                if(component.get("v.filesProcessed")==f.length-1)
                {
                    console.log("calling update Enquiry");
                    helper.updateEnquiry(component,event,helper);
                    component.set("v.showSpinner",false);
                    return;
                }
                component.set("v.filesProcessed",component.get("v.filesProcessed")+1);                
            }
        });
        $A.enqueueAction(action);    
    }
})