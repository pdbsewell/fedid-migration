({
	doInit : function(component, event, helper) {
		var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var sParamId = '';
        var i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for(var x = 0; x < sParameterName.length; x++){
                if(sParameterName[x] === 'appId'){
                   sParamId = sParameterName[x+1] === undefined ? 'Not found' : sParameterName[x+1];
                }
            }
        }

        if(!sParamId){
            sParamId = component.get("v.applicationId");
        }else{
            //redirect to the new app form url
            window.location.href = '/admissions/s/application/' + sParamId;
        }

        component.set("v.appId", sParamId);

        if (sParamId != '') {
	        var action_retrieveAppRecord = component.get("c.retrieveApplication");
	        action_retrieveAppRecord.setParams({ "applicationId"   : sParamId });
	        action_retrieveAppRecord.setCallback(this, function(a) {
	            var appRecord = a.getReturnValue();
	            console.log(appRecord.Source_System__c)
				component.set("v.appRecord", appRecord);
                var showcc = (appRecord.Source_System__c !='AgentPortal' &&
                               appRecord.Fee_Payment_Mode__c == 'Credit Card' && appRecord.Fee_Payment__c == false);
                component.set("v.showCCButton",  showcc);
				component.set("v.citizenship", appRecord.Applicant__r.Citizenship__c);
	            if (appRecord.Status__c != 'Draft' && !component.get('v.applicationId')) {
	            	//redirect to dashboard
        			helper.gotoURL("/");
	            }
                // handle Mononymous names
                if (appRecord.Applicant__r.First_Name__c && appRecord.Applicant__r.First_Name__c.trim())
                {
                    component.set("v.fullname",  appRecord.Applicant__r.First_Name__c + ' ' +appRecord.Applicant__r.Last_Name__c);
                }else{
					component.set("v.fullname", appRecord.Applicant__r.Last_Name__c);
                }
	        });

	        $A.enqueueAction(action_retrieveAppRecord);
        }
        else {
        	//redirect to dashboard
        	//helper.gotoURL("/");
        }
	},

	backToPaymentOrReview : function(component, event, helper) {
		var applicationId = component.get("v.appId");
		helper.navigateBack(component, applicationId);
	},

	submitApplication : function(component, event, helper) {
		//var appbutton = component.find("acceptButton");
        //$A.util.addClass(appbutton.getElement(), 'disabled');
        //
        component.set("v.backDisabled", true);
        component.set("v.submitDisabled", true);

		var applicationRecord = component.get("v.appRecord");

        var applicationId = applicationRecord.Id;
		var actionSubmitApplication = component.get("c.validateAndSubmitApplication");
		actionSubmitApplication.setParams({"applicationId" : applicationId});
		actionSubmitApplication.setCallback(this, function(response) {

            var objResponse = response.getReturnValue();
            console.log("appDeclarationFormController:" + objResponse);

            var arrErrors = objResponse.errors;
            if(arrErrors && arrErrors.length > 0)
            {
                component.set("v.showErrors", true);
                component.set("v.backDisabled", false);
        		component.set("v.submitDisabled", false);
                helper.showErrors(component, arrErrors, applicationId);
            }
            else
            {
                // on success
                var status = objResponse.application_status;
				var sectionName = 'receipt';
				var parentComponent = component.get("v.parent");
				parentComponent.changeSection(sectionName);

            }
		});

		$A.enqueueAction(actionSubmitApplication);
	},

	pay : function(component, event, helper)
    {
        var applicationRecord = component.get("v.appRecord");

      var action = component.get("c.validateApplication");
      action.setParams({"applicationId" : applicationRecord.Id});
      action.setCallback(this, function(response){
          var objResponse = response.getReturnValue();
          console.log(objResponse)
          var arrErrors = objResponse.errors;
          if(arrErrors && arrErrors.length > 0)
          {
              component.set("v.showErrors", true);
              component.set("v.backDisabled", false);
              component.set("v.submitDisabled", false);
              helper.showErrors(component, arrErrors, applicationRecord.Id);
          }else{
              //Process Payment
              component.set("v.showPayment", true);
          }
      });
      $A.enqueueAction(action);
    },

    closePayment : function(component)
    {
        component.set("v.showPayment", false);
    },

    onClickCloseAlert: function(component, event, helper)
    {
        component.set("v.showErrors", false);
    },
    navigateToSection: function(component, event, helper) {
        var sectionName = event.target.id;
        sectionName = sectionName.replace('errorSection:::', '');

        var parentComponent = component.get("v.parent");
        parentComponent.changeSection(sectionName);
    },
    saveandExit: function(component, event, helper)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
        "url": "/",
        "isredirect" :false
        });
        urlEvent.fire();
    },

    sendToAgent : function(component, event, helper) {
		//var appbutton = component.find("acceptButton");
        //$A.util.addClass(appbutton.getElement(), 'disabled');
        console.log('sendToagent************');
        component.set("v.backDisabled", true);
        component.set("v.acceptDisabled", true);
		var applicationRecord = component.get("v.appRecord");
        var applicationId = applicationRecord.Id;
		var validateApplication = component.get("c.validateApplication");
		validateApplication.setParams({"applicationId" : applicationId});
		validateApplication.setCallback(this, function(response) {
        var objResponse = response.getReturnValue();
        var arrErrors = objResponse.errors;
            //Check for validation errors
            if(arrErrors && arrErrors.length > 0)
            {
                    component.set("v.showErrors", true);
                    component.set("v.backDisabled", false);
                    component.set("v.submitDisabled", false);
                    helper.showErrors(component, arrErrors, applicationId);
            }
            else
            {       //no errors - invoke update application
                    var actionStudentDeclaration = component.get("c.updateApplicationWithStudentDeclarationAccepted");
                    actionStudentDeclaration.setParams({"applicationId" : applicationId});
                    actionStudentDeclaration.setCallback(this, function(response) {
                    var objRes = response.getReturnValue();
                    //Check for errors during the update
                    var arrErrors = objRes.errors;
                    if(arrErrors && arrErrors.length > 0)
                    {
                        component.set("v.showErrors", true);
                        component.set("v.backDisabled", false);
                        component.set("v.acceptDisabled", false);
                        helper.showErrors(component, arrErrors, applicationId);
                    }
                    else
                    {
                        var sectionName = 'receipt';
                        var parentComponent = component.get("v.parent");
                        parentComponent.changeSection(sectionName);
                    }
                });

                $A.enqueueAction(actionStudentDeclaration);
            }

        });
        $A.enqueueAction(validateApplication);

    }

})