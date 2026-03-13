({

    /**
     * Show/Hide the spinner
     * @param component
     * @param toShow
     */
    showOffersSpinner: function(component, toShow)
    {
        component.set("v.showSpinner", toShow);
    }
    /**
         * Mock Full offer - For Conditional offer matching some criteria.
         * @param component
         * @param toShow
     */
    , mockFullOffer : function(component) {
       if(component.get("v.selectedACP.Outcome_Status_LOV__c")!=null && component.get("v.selectedACP.Outcome_Status_LOV__r.Value__c")== 'OFFER-COND')
       {
           if(component.get("v.selectedACP.Conditional_Offer_Status_LOV__c")!=null && component.get("v.selectedACP.Conditional_Offer_Status_LOV__r.Value__c") != 'WAIVED')
           {
                component.set("v.mockFullOffer", false);
           }else
           {
               if(component.get("v.selectedACP.Documentation_Status_LOV__c")!=null && component.get("v.selectedACP.Conditional_Offer_Status_LOV__c")!=null &&component.get("v.selectedACP.Conditional_Offer_Status_LOV__r.Value__c") == 'WAIVED')
               {
                   if(component.get("v.selectedACP.Documentation_Status_LOV__r.Value__c") =='DOC-UNCERT' ||
                      component.get("v.selectedACP.Documentation_Status_LOV__r.Value__c") =='DOC-ENROL')
                   {
                         //console.log('v.mockFullOffer =====true');
                          component.set("v.mockFullOffer", true);
                   }
               }
           }
            //console.log('v.mockFullOffer'+component.get("v.mockFullOffer"));
       }



    }

    /**
     * clear the temp attributes to go back to 'Start' state
     * @param component
     */
    , backToOffersStart:function(component, useraction)
    {
        this.showOffersSpinner(component, false);

        component.set("v.showConfirmReject", false);
        component.set("v.showResponsePopup", false);


        //console.log('val=='+useraction);

        var fullOfferMsg =' Fantastic news! The next step in accepting your place with Monash is to enrol. <br/><br/>'+
                      'Follow the steps in the <a href="https://www.monash.edu/get-started#enrolment">Get started</a> website by your offer expiry date: '+  component.get("v.selectedACP.Offer_Response_Date__c")+'.<br/><br/>'+
                      ' Also be on the lookout for information provided by your faculty in future correspondence.'+
                      '<p>We look forward to having you join the Monash community!</p>';
	    var conditionalOfferMsg = 'Fantastic news! Once you fulfil your conditions, submit documents via the "Add Documents" button against your submitted application on my.app.';
        var rejectMsg = 'Thank you for considering study at Monash. We’re sorry to see you go. We would appreciate any feedback you have on your experience with us and how we can improve.';
        if(useraction == 'accept')
        {
            if(component.get("v.selectedACP.Outcome_Status_LOV__c")!=null && component.get("v.selectedACP.Outcome_Status_LOV__r.Value__c")== 'OFFER-COND')
            {
                  if(component.get("v.selectedACP.Conditional_Offer_Status_LOV__c")!=null && component.get("v.selectedACP.Documentation_Status_LOV__c")!=null && component.get("v.selectedACP.Conditional_Offer_Status_LOV__r.Value__c") == 'WAIVED')
                  {
                      if(component.get("v.selectedACP.Documentation_Status_LOV__r.Value__c") =='DOC-UNCERT' ||
                         component.get("v.selectedACP.Documentation_Status_LOV__r.Value__c") =='DOC-ENROL')
                      {
                            component.set("v.confirmMsgContent",fullOfferMsg);
                      }else {
                       component.set("v.confirmMsgContent",conditionalOfferMsg);
                       }
                  }else {
                     component.set("v.confirmMsgContent",conditionalOfferMsg);
                     }
            }else
                component.set("v.confirmMsgContent",fullOfferMsg);

            component.set("v.confirmMsgTitle",'Fantastic news');
        }else if(useraction == 'reject')
        {
            component.set("v.confirmMsgContent",rejectMsg);
            component.set("v.confirmMsgTitle",'Sorry to see you go');
        }
      component.set("v.showConfirmPopup", true);

    }

    /**
     * parse the map returned from server side does the following:
     * 1. only show the Respond button if it matches the filter conditions
     * 2. mark as expired if the date is past and still pending a response
     *
     * NB. although the records returned are ACPs, JS only recognizes them as objects, therefore,
     * we can append the showOfferButton and expired fields at runtime
     * @param component
     * @param submittedApplications
     */
	, formatACPs : function(component, submittedApplications) {
        //console.log('appHomeOffersHelper::formatACPs'+submittedApplications.length);
		if(submittedApplications && submittedApplications.length > 0)
        {
            component.set("v.haveOffers", false);

            var VALID_ADM_CATEGORIES = ['UG-FEE', 
            'UG-CSP', 'UG-HECS', 'MO-PG-DOM', 'PG-CSP', 'PG-FEE'];

            var VALID_OUTCOME_STATUS = [ 'OFFER', 'OFFER-COND'];
            var VALID_RESPONSE_STATUS = ['PENDING'];

            var dateToday = new Date();
            // loop through to apply filter logic
            for(var i = 0; i < submittedApplications.length; ++i)
            {
                var objApp = submittedApplications[i];
                var arrACPs = objApp.acps;
                //console.log('application:' + objApp.applicationId + ', ' + objApp.applicationName);
                for(var j = 0; j < arrACPs.length; ++j)
                {
                    var acp = arrACPs[j];
                    //console.log(acp);
                    // main logic as per SF-2484
                    var showOfferButton = true;

                    var offerType = acp.Outcome_Status_LOV__c!=null?acp.Outcome_Status_LOV__r.Applicant_Value__c:'';
                    if(!acp.Admission_Category__c || VALID_ADM_CATEGORIES.indexOf(acp.Admission_Category__c) < 0)
                    {
                        showOfferButton = false;
                    }
                    if(!acp.Outcome_Status_LOV__r || VALID_OUTCOME_STATUS.indexOf(acp.Outcome_Status_LOV__r.Value__c) < 0)
                    {
                        showOfferButton = false;
                    }
                    if(!acp.Offer_Response_Status_LOV__r || VALID_RESPONSE_STATUS.indexOf(acp.Offer_Response_Status_LOV__r.Value__c) < 0)
                    {
                        showOfferButton = false;
                    }
                    if(acp.Offer_Response_Date__c
                        && acp.Offer_Response_Status_LOV__r
                        && VALID_RESPONSE_STATUS.indexOf(acp.Offer_Response_Status_LOV__r.Value__c) >= 0)
                    {
                        var dateExpiry = new Date(acp.Offer_Response_Date__c);
                        //console.log('****:' + dateExpiry + ', today = ' + dateToday);
                         //console.log('response date:' + dateExpiry.getDate()+ ', today = ' + dateToday.getDate());
                        if( (dateExpiry.getDate() < dateToday.getDate() && dateExpiry.getMonth() ==dateToday.getMonth() && dateExpiry.getYear() ==dateToday.getYear())
                             || ( (dateExpiry.getDate()!=dateToday.getDate() || dateExpiry.getMonth()!=dateToday.getMonth() || dateExpiry.getYear()!=dateToday.getYear()) && dateExpiry<dateToday)
                            )                 {
                            showOfferButton = false;
                            acp.expired = true;
                        }
                        
                    }


                   if(acp.Outcome_Status_LOV__c!=null && acp.Outcome_Status_LOV__r.Value__c== 'OFFER-COND')
                       if(acp.Documentation_Status_LOV__c!=null && acp.Conditional_Offer_Status_LOV__c!=null && acp.Conditional_Offer_Status_LOV__r.Value__c == 'WAIVED')
                       {
                           if(  acp.Documentation_Status_LOV__r.Value__c =='DOC-UNCERT' ||
                             acp.Documentation_Status_LOV__r.Value__c =='DOC-ENROL')
                           {
                                 //console.log('Setting table offer type ****');
                                  offerType = 'Full Offer';
                           }
                       }

                    acp.offerType = offerType;

                    //console.log('show offer button?' + showOfferButton);
                    acp.showOfferButton = showOfferButton;

                    // if there are any offers, show the banner
                    if(showOfferButton == true)
                    {
                        component.set("v.haveOffers", true);
                    }
                }
                //Set application header format
                objApp.headerName = 'APPLICATION - ' + objApp.applicationName + ' (SUBMITTED ON ' + objApp.applicationDate + ')';
            }
            //console.log(' 3  appHomeOffersHelper::formatACPs');
            component.set("v.submittedApplications", submittedApplications);
            component.set("v.showComponent", true);
        }
        else
        {
            //console.log('appHomeOffersHelper:: no submitted applications');
        }
	}

    /**
     * returns the acp (object) by an Id, this is required because buttons can only store a string value
     *
     * @param component
     * @param acpId
     */
	, getACPById:function(component, acpId)
    {
        var submittedApps = component.get("v.submittedApplications")
        for(var i = 0; i < submittedApps.length; ++i)
        {
            var objApplication = submittedApps[i];
            var arrACPS = objApplication.acps;
            for(var j = 0; j < arrACPS.length; ++j)
            {
                var acp = arrACPS[j];
                if(acp.Id == acpId)
                {
                    component.set("v.selectedACP", acp);
                    return;
                }
            }
        }

        //console.error("appHomeOffersHelper:: couldn't find acp with Id:" + acpId );
    }
})