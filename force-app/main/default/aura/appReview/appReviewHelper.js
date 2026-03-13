({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  retrieve the application Id from URL and set it to v.appId
    * @revision     
    *******************************************************************************/
    retrieveAppIdFromURL : function(component) {
	    var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
	    var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
	    var sParameterName;
	    var i;

	    var retrievedAppId = '';
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                }
            }
        }
        if (retrievedAppId != '') {
            component.set("v.appId", retrievedAppId);
        }
	},

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  retrieve the application record
    * @revision     
    *******************************************************************************/
    retrieveApplicationRecord : function(component) {
        var action = component.get("c.retrieveApplication");
        
        action.setParams({ "appId"   : component.get("v.appId") });
        action.setCallback(this, function(a) {
            // Recieved from server
            console.log("+++++++++++++++++");
            console.log(a.getReturnValue().Applicant__r.Citizenship__c);
            component.set("v.citizenship", a.getReturnValue().Applicant__r.Citizenship__c);
            component.set("v.appRecord", a.getReturnValue());
        });
        $A.enqueueAction(action);
	},

	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  retrieve the qualifications related to application and put it on
    					the map
    * @return 		Map<String, List<Application_Qualification_Provided__c>>
    * @revision     Ant Custodio, 21.Jun.2017 - calls the credit intention section
                        if there's at least 1 Tertiary Education present
    *******************************************************************************/
    retrieveAppQualMap : function(component) {
    	var applicationId = component.get("v.appId");
	    var action = component.get("c.retrieveApplicationQualMap");
        action.setParams({ "appId"   : applicationId });
        action.setCallback(this, function(a) {
            var qualRecMap = a.getReturnValue();
            component.set("v.qualMap", qualRecMap);
            if (qualRecMap.Tertiary_Education != null && qualRecMap.Tertiary_Education != undefined) {
                if (qualRecMap.Tertiary_Education.length > 0) {
                    var childCmp = component.find("appCredIntention");
                    childCmp.initialise();
                }
            }
        });
        $A.enqueueAction(action);
	},

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  retrieve the qualifications related to application and put it on
                        the map
    * @return       Map<String, List<Application_Qualification_Provided__c>>
    * @revision     
    *******************************************************************************/
    retrieveAppWorkExpList : function(component) {
        var applicationId = component.get("v.appId");
        var action = component.get("c.retrieveApplicationWorkExpList");
        action.setParams({ "appId"   : applicationId });
        action.setCallback(this, function(a) {
            component.set("v.workExpList", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         23.May.2017         
    * @description  retrieve the Application course preferences
    * @return       List<CourseWrapper>
    * @revision     
    *******************************************************************************/
    retrieveCourseList : function(component) {
        var applicationId = component.get("v.appId");
        var action = component.get("c.retrieveApplicationCourses");
        action.setParams({ "appId"   : applicationId });
        action.setCallback(this, function(a) {
            component.set("v.coursePrefList", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         23.May.2017         
    * @description  retrieve the Application Documents
    * @revision     
    *******************************************************************************/
    retrieveDocumentList : function(component) {
        var applicationId = component.get("v.appId");
        var action = component.get("c.retrieveAppDocuments");
        action.setParams({ "appId"   : applicationId });
        action.setCallback(this, function(a) {
            component.set("v.appDocList", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         23.May.2017         
    * @description  retrieves the URL of the Print version of the application
    * @revision     
    *******************************************************************************/
    generatePrintURL : function(component) {
        var applicationId = component.get("v.appId");
        component.set("v.printURL", "applicationprint?appId="+applicationId);
    },

    /*******************************************************************************
    * @author      Andrew Yeo
    * @date                  
    * @description  Check for the fee rules
    * @revision     
    *******************************************************************************/
   checkTheFeeRules : function(component) {
       console.log('appReviewHelper.js is called');
        
       var applicationId = component.get("v.appId");
        console.log('applicationId is: ' + applicationId);
        var action = component.get("c.determineFeeRule");
        action.setParams({ "applicationId"   : applicationId });
        action.setCallback(this, function(a) {
            
        });
        $A.enqueueAction(action);
        console.log('appReviewHelper.js is ended');
    }
})