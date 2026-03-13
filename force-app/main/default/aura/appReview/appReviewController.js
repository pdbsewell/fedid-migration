({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017       
    * @description  initial actions on page load
    * @revision     
    *******************************************************************************/
    doInit : function(component, event, helper) {
        //retrieve the application Id from the URL
        helper.retrieveAppIdFromURL(component);

        //retrieve the application record
        helper.retrieveApplicationRecord(component);

        //retrieve the qualification list related to the application
        helper.retrieveAppQualMap(component);

        //retrieve the work experiences related to the application
        helper.retrieveAppWorkExpList(component);

        helper.retrieveCourseList(component);

        helper.retrieveDocumentList(component);

        //generates a Print Version URL
        helper.generatePrintURL(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017
    * @description  show the spinner when page is loading
    * @revision     
    *******************************************************************************/
    waiting: function(component, event, helper) {
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "block";
        }
        
    },
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  hide the spinner when finished loading
    * @revision     
    *******************************************************************************/
    doneWaiting: function(component, event, helper) {
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "none";
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  method called by button to redirect to the edit application page
    * @revision     
    *******************************************************************************/
    redirectToEditApplication : function(component, event, helper) {
        var address = '/applicationdetail?appId=' + component.get("v.appId");

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect" :true
        });

        urlEvent.fire();
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         24.May.2018         
    * @description  method called by button to redirect to the edit application page
    * @revision     
    *******************************************************************************/
    redirectToPaymentOrDec : function(component, event, helper) {
        console.log('---------------++++++');
        console.log(component.get("v.citizenship"));

        //call the check fee rule from appReviewHelper.js to determine the fee amounts
        helper.checkTheFeeRules(component); 

        var address;
        if(component.get("v.citizenship") == "INTERNATIONAL")
            address = '/applicationdeclaration?appId=' + component.get("v.appId");
        else
            address = '/applicationdeclaration?appId=' + component.get("v.appId");

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect" :true
        });

        urlEvent.fire();
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         10.May.2017         
    * @description  go to print ready form
    * @revision     
    *******************************************************************************/
    printForm: function(component, event, helper) {
        window.print();
    },
})