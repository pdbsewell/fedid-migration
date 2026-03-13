({ 
    MAX_FILE_SIZE:  3000000,
    CHUNK_SIZE: 900 000,
    
    populatePicklist: function (component, event) {
        var populatepicklists = component.get("c.getReasonofEnquiry");
        var option = new Array();     
        
        populatepicklists.setCallback(this, function(response) {
            for(var i=0;i< response.getReturnValue().length;i++) {
                option.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }
            component.find("hrQuestion").set("v.options", option);
        });
        
        $A.enqueueAction(populatepicklists);
    }, 
    Save: function(component, event,helper) {
        
        var casRecord = component.get("v.newCase");
        var usertype = component.get("v.userType");
        //var enqType = component.get("v.enquiryType");
        
        var action = component.get("c.createCase");
        var self = this;   
        if(casRecord.Community_Status__c == '-- None --') {
                 var toastEvent = $A.get("e.force:showToast");
            	 toastEvent.setParams({
                 "title": "Error!",
                 "message": "Please select a value for Subject"
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
        } else {
       	if(usertype == 'Guest' && (casRecord.Supplied_First_Name__c == '' || casRecord.Supplied_First_Name__c == '' || casRecord.SuppliedEmail == '' || casRecord.Description == '')) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please fill all mandatory details"
            });
           	toastEvent.fire();        
            component.set("v.isButtonClicked",false);
        } else if(casRecord.Description == '') {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please enter Question details"
            });
            toastEvent.fire();
            component.set("v.isButtonClicked",false);
        } else {
            action.setParams({
                casRec : casRecord,
                //recordTypeName : enqType
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('case save state::'+state);
                if(state == "SUCCESS") {
                    component.set("v.parentId",response.getReturnValue());
                    helper.attachmentsave(component,helper);
                    console.log('Calling attachment save');
                    
                    // alert('Record is Created Successfully');
                } else if (state == "ERROR") {
                   
                    alert('Error in calling server side action');
                    component.set("v.isButtonClicked",false);
                }
            });
            $A.enqueueAction(action);
        }
     }
    },
    getUserType: function(component) {
        var action = component.get("c.getUserType");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var flag = response.getReturnValue();
                component.set("v.userType",flag);
                if(flag != 'Internal'){
                    $("#firstname").show();
                    $("#lastname").show();
                    $("#email").show();
                    $("#interim-div-hr").show();
                } 
                
            }
        });
        
        $A.enqueueAction(action);
    }, 
    handleCheckbox: function(component, event) {
        var selected = event.getSource().getLocalId(); 
        component.set("v.enquiryType", selected);
        console.log('>>>>'+selected);
        $A.util.removeClass(component.find("it-radio"), 'selected');
        $A.util.removeClass(component.find("hr-radio"), 'selected');
        $A.util.removeClass(component.find("student-radio"), 'selected');
        $A.util.removeClass(component.find("student-radio-header"), 'selected-font');
        $A.util.removeClass(component.find("hr-radio-header"), 'selected-font');
        $A.util.removeClass(component.find("it-radio-header"), 'selected-font');
        if(selected == "Student") {
            console.log('selected student');
            $A.util.addClass(component.find("student-radio"), 'selected');
            $A.util.addClass(component.find("student-radio-header"), 'selected-font');
            $A.util.addClass(component.find("question-div"), 'slds-hide');
            $A.util.removeClass(component.find("subject-div"), 'slds-hide');
        } else if(selected == "IT"){
            $A.util.addClass(component.find("it-radio"), 'selected');
            $A.util.addClass(component.find("it-radio-header"), 'selected-font');
            $A.util.addClass(component.find("question-div"), 'slds-hide');
            $A.util.removeClass(component.find("subject-div"), 'slds-hide');
        } else {
            $A.util.addClass(component.find("hr-radio"), 'selected');
            $A.util.addClass(component.find("hr-radio-header"), 'selected-font');
            $A.util.addClass(component.find("subject-div"), 'slds-hide');
            $A.util.removeClass(component.find("question-div"), 'slds-hide');
        }
    },
    getSuggestions: function(component,event){
       /* var action = component.get("c.getArticalSuggestions");
        var searchToken = component.get("v.newCase.Description");
        var articleSuggestions=[];
        var filterArticleSuggestions=[];
        action.setParams({"searchText": searchToken});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('>>>State'+state);
            if (component.isValid() && state === "SUCCESS") {
                filterArticleSuggestions = response.getReturnValue();
                for(var i=0;i<5 && i<filterArticleSuggestions.length;i++) {
                    articleSuggestions.push(filterArticleSuggestions[i]);
                }
                if(articleSuggestions.length>0) {
                    $("div#suggestedArticles").show();
                    component.set("v.suggestionArticleList", articleSuggestions);
                } else {
                    $("div#suggestedArticles").hide();
                    component.set("v.suggestionArticleList", articleSuggestions);
                }
            } 
        });
        $A.enqueueAction(action);*/
    },
    redirectToArticle: function(component, event){
       /* var idx = event.target.id;
        var action = component.get("c.getArticledetail"); 
        action.setParams({
            articleId : idx
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.suggestionArticleSummary", response.getReturnValue());
            } 
            $A.util.removeClass(component.find("artical-modal").getElement(), "slds-hide");
        });
        $A.enqueueAction(action);*/
    },
    attachmentsave : function(component,helper) {
        var fileInput = component.find("file").getElement();
        var file = fileInput.files;     
        
        if(file.length == 0){
				helper.redirectHomePage(component, event,helper);
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
				helper.redirectHomePage(component, event,helper);
                return;
            }
                component.set("v.showSpinner",true);
                console.log('calling reader'+file[i]);
            	var self = this;
            	reader(file[i],self);
            
            
        }
        
        function reader(file,self){
            var fr = new FileReader();
            
            
            fr.onload = $A.getCallback(function() { 
                var fileContents = fr.result;
                var base64Mark = 'base64,';
                var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
                
                fileContents = fileContents.substring(dataStart);
                helper.upload(component, file, fileContents,helper);
            });
            
            fr.readAsDataURL(file);
        }
    },
    upload: function(component, file, fileContents,helper) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        helper.uploadChunk(component, file, fileContents, fromPos, toPos, '',helper); 
    },
    uploadChunk : function(component, file, fileContents, fromPos, toPos, attachId,helper) {
        console.log('>>>>inside upload chunk');
        console.log('fromPos is '+fromPos);
        console.log('toPos is '+toPos);
        var action = component.get("c.saveTheChunk"); 
        var chunk = fileContents.substring(fromPos, toPos);
		action.setParams({
            parentId: component.get("v.parentId"),
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId
        });
       
        var self = this;
        console.log('parameter set');
        action.setCallback(this, function(a) {
            console.log('in callback');
            var state = a.getState();
            console.log('Chunk State>>>>::'+state);
            attachId = a.getReturnValue();            
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + self.CHUNK_SIZE);    
            if (fromPos < toPos) {
            	helper.uploadChunk(component, file, fileContents, fromPos, toPos, attachId,helper);  
            }
            else
            {
                component.set("v.showSpinner",false);
                helper.redirectHomePage(component, event,helper);
                component.set("v.showSpinner",false);
            }
        });
        $A.enqueueAction(action);    
    },
        
    getUserFirstName : function(component) {
        var action = component.get("c.getUserFirstName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.firstName", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
        
    redirectPrivacyStatement : function(component, event) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "http://www.monash.edu/privacy-monash/guidelines/collection-personal-information#monashuni"
        });
        urlEvent.fire();
    },
    redirectHomePage: function(component,event,helper) {
       var urlEvent = $A.get("e.force:navigateToURL");
       urlEvent.setParams({
             "url": "/thank-you"
       });
       urlEvent.fire();
    }
    
})