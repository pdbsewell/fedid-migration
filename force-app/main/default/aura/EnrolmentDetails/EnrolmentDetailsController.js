/*createComponentController.js*/
({
    doInit : function(component, event, helper) {

        // Retrieve picklist values
        helper.retrievePicklistValues(component.get("c.retrieveHAFValues"), component.find("howDidUHear"));
        helper.retrieveStates(component.find("state"));
        helper.retrieveStates(component.find("orgState"));
        
        // Initialise variables
        component.set("v.errorMessage", "");
        component.set("v.cont.enquiryId", "");
        component.set("v.cont.givenName", "");
        component.set("v.cont.familyName", "");
        component.set("v.cont.address", "");
        component.set("v.cont.suburb", "");
        component.set("v.cont.state", "");
        component.set("v.cont.postCode", "");
        component.set("v.cont.homePhoneNumber", "");
        component.set("v.cont.workPhoneNumber", "");
        component.set("v.cont.mobileNumber", "");
        component.set("v.cont.email", "");
        component.set("v.cont.organisation","");
        component.set("v.cont.orgStreetAddress","");
        component.set("v.cont.orgSuburb","");
        component.set("v.cont.orgState","");
        component.set("v.cont.orgPostcode","");
        component.set("v.cont.jobTitle", "");
        component.set("v.cont.concessionCardHolder", false);
        component.set("v.cont.graduate", false);
        component.set("v.cont.termsAccepted", false);
        component.set("v.cont.previousCourse", "");

        // Disable documents section on load
        var sec2 = component.find('section2');
        var sec2header = component.find('section2header');
        $A.util.addClass(sec2, 'disable');
        $A.util.addClass(sec2header, 'disable');

        var fl = component.find('file');
        $A.util.addClass(fl, 'disable');

        var courseNameCmp = component.find("previousCourse");
        $A.util.addClass(courseNameCmp, 'disable');

        // Display fee to be payed
        component.set("v.feeToPay",component.get("v.selectedCourseOffering.Fee__c"));

    },

    showHideComponent1 : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded1");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
        component.set("v.isExpanded1", isExpanded);
    },

    showHideComponent2 : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded2");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
        component.set("v.isExpanded2", isExpanded);
    },

    book : function (component, event, helper) {

        // Validate Form
        helper.validateForm(component);
        var error = component.get("v.errorMessage");


        if(error == '') {
            component.set("v.isLoading", true);
            // Register or Waitlist a candidate for course
            var action_register;
            var state = component.get("v.currentState");
            if(state == 'Course Registration') {
                action_register = component.get("c.register");    
            } else if(state == 'Waiting List') {
                action_register = component.get("c.waitlist");
            }
            
            console.log('Information : '+ component.get("v.cont"));

            action_register.setParams({ "givenName"   : component.get("v.cont.givenName"), 
                                        "familyName"   : component.get("v.cont.familyName"), 
                                        "address"   : component.get("v.cont.address"),
                                        "suburb"   : component.get("v.cont.suburb"),
                                        "state"   : component.get("v.cont.state"),
                                        "postCode"   : component.get("v.cont.postCode"),
                                        "homePhoneNumber"   : component.get("v.cont.homePhoneNumber"),
                                        "workPhoneNumber"   : component.get("v.cont.workPhoneNumber"),
                                        "mobileNumber"   : component.get("v.cont.mobileNumber"),
                                        "email"   : component.get("v.cont.email"),
                                        "jobTitle"   : component.get("v.cont.jobTitle"),
                                        "selectedCourseOfferingId" : component.get("v.selectedCourseOffering.Id"),
                                        "howDidyouHearAboutUs"   : component.get("v.cont.howDidyouHearAboutUs"),
                                        "organisation"   : component.get("v.cont.organisation"),
                                        "orgStreetAddress"   : component.get("v.cont.orgStreetAddress"),
                                        "orgSuburb"   : component.get("v.cont.orgSuburb"),
                                        "orgState"   : component.get("v.cont.orgState"),
                                        "orgPostcode"   : component.get("v.cont.orgPostcode"),
                                        "isConcession" : component.get("v.cont.concessionCardHolder"),
                                        "graduate" : component.get("v.cont.graduate"),
                                        "courseName" : component.get("v.cont.previousCourse")
                                      });
            
            action_register.setCallback(this, function(a) {
                component.set("v.isLoading", false);
                component.set("v.cont.enquiryId", a.getReturnValue()[0]);
                component.set("v.cont.applicationId", a.getReturnValue()[1]);
                component.set("v.cont.contactId", a.getReturnValue()[2]);
                component.set("v.exception", a.getReturnValue()[3]);
            });
            $A.enqueueAction(action_register);

            console.log('Enquiry Id : ' + component.get("v.cont.enquiryId"));
            console.log('Application Id : ' + component.get("v.cont.applicationId"));
            console.log('Contact Id : ' + component.get("v.cont.contactId"));
            console.log('Exception : ' + component.get("v.exception"));
            
            

            if(component.get("v.exception") == '') {
                // Show Documents section
                var sec2 = component.find('section2');
                var sec2header = component.find('section2header');
                $A.util.removeClass(sec2, 'disable');
                $A.util.removeClass(sec2header, 'disable');

                var fl = component.find('file');
                $A.util.removeClass(fl, 'disable');

                // Disable details section
                var sec1 = component.find('section1');
                var sec1header = component.find('section1header');
                $A.util.addClass(sec1, 'disable');
                $A.util.addClass(sec1header, 'disable');

                // Smooth scroll to documents section
                document.querySelector('.scroll-to-documents').scrollIntoView({ 
                  behavior: 'smooth' 
                });     
            }

            console.log('Information : '+ component.get("v.cont"));   
        } 

    },

    redirectToPaymentPage : function(component, event) {
        // Disable button
        var btn = event.getSource();
        btn.set("v.disabled",true);

        // Retrieve files upploaded size
        var filesUploaded = component.get("v.attachList.length");

        var isConcession = component.get("v.cont.concessionCardHolder");
        
        if(isConcession && filesUploaded == 0) {
            component.set("v.errorMessage", "You have indicated that you are a concession card holder. Please upload your concession card as a proof");
            component.set("v.showConfirmPopup", "true");            
        } else {  
            component.set("v.isLoading", true);
            // Create payment
            var action_payment = component.get("c.createPayment");

            if(component.get("v.cont.organisation") != null && component.get("v.cont.organisation") != '') {
                action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                        "contactId"   : component.get("v.cont.contactId"), 
                                        "co"   : component.get("v.selectedCourseOffering"),
                                        "isConcession"   : component.get("v.cont.concessionCardHolder"),
                                        "streetAddress"   : component.get("v.cont.orgStreetAddress"),
                                        "suburb"   : component.get("v.cont.orgSuburb"),
                                        "state"   : component.get("v.cont.orgState"),
                                        "postcode"   : component.get("v.cont.orgPostcode")
                                      }); 
            }
                
            else {
                action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                        "contactId"   : component.get("v.cont.contactId"), 
                                        "co"   : component.get("v.selectedCourseOffering"),
                                        "isConcession"   : component.get("v.cont.concessionCardHolder"), 
                                        "streetAddress"   : component.get("v.cont.address"),
                                        "suburb"   : component.get("v.cont.suburb"),
                                        "state"   : component.get("v.cont.state"),
                                        "postcode"   : component.get("v.cont.postCode")
                                      });    
            }

            action_payment.setCallback(this, function(a) {
                console.log('***PAYMENT ID : '+ a.getReturnValue());
                component.set("v.cont.paymentId", a.getReturnValue());
                
                // Create a purchase order and generate a payment link
                var action_pay = component.get("c.generatePaymentLink");
                
                // Set billing address as company address if the user populates company details
                if(component.get("v.cont.organisation") != null && component.get("v.cont.organisation") != '') {
                    action_pay.setParams({ "givenName"   : component.get("v.cont.givenName"), 
                                            "familyName"   : component.get("v.cont.familyName"), 
                                            "address"   : component.get("v.cont.orgStreetAddress"),
                                            "suburb"   : component.get("v.cont.orgSuburb"),
                                            "state"   : component.get("v.cont.orgState"),
                                            "postCode"   : component.get("v.cont.orgPostcode"),
                                            "homePhoneNumber"   : component.get("v.cont.homePhoneNumber"),
                                            "workPhoneNumber"   : component.get("v.cont.workPhoneNumber"),
                                            "mobileNumber"   : component.get("v.cont.mobileNumber"),
                                            "email"   : component.get("v.cont.email"),                                 
                                            "selectedCourseOfferingId" : component.get("v.selectedCourseOffering.Id"),
                                            "paymentId" : component.get("v.cont.paymentId"),
                                            "isConcession" : component.get("v.cont.concessionCardHolder"),
                                            "enquiryId" : component.get("v.cont.enquiryId")
                                          }); 
                }
                // Set billing address as mailing address if the user does not populate company details
                else {
                    action_pay.setParams({ "givenName"   : component.get("v.cont.givenName"), 
                                            "familyName"   : component.get("v.cont.familyName"), 
                                            "address"   : component.get("v.cont.address"),
                                            "suburb"   : component.get("v.cont.suburb"),
                                            "state"   : component.get("v.cont.state"),
                                            "postCode"   : component.get("v.cont.postCode"),
                                            "homePhoneNumber"   : component.get("v.cont.homePhoneNumber"),
                                            "workPhoneNumber"   : component.get("v.cont.workPhoneNumber"),
                                            "mobileNumber"   : component.get("v.cont.mobileNumber"),
                                            "email"   : component.get("v.cont.email"),                                 
                                            "selectedCourseOfferingId" : component.get("v.selectedCourseOffering.Id"),
                                            "paymentId" : component.get("v.cont.paymentId"),
                                            "isConcession" : component.get("v.cont.concessionCardHolder"),
                                            "enquiryId" : component.get("v.cont.enquiryId")
                                          });    
                }
                
                // redirect to payment page
                action_pay.setCallback(this, function(a) {
                    window.open(a.getReturnValue(),'_parent');
                });
    
                $A.enqueueAction(action_pay);
                   
            });
            $A.enqueueAction(action_payment);
   
        }

    },

    redirectToMagento : function(component, event) {

        // Retrieve files upploaded size
        var filesUploaded = component.get("v.attachList.length");

        var isConcession = component.get("v.cont.concessionCardHolder");
        
        if(isConcession && filesUploaded == 0) {
            component.set("v.errorMessage", "You have indicated that you are a concession card holder. Please upload your concession card as a proof");
            component.set("v.showConfirmPopup", "true");            
        } else {  

            // Create payment
            var action_payment = component.get("c.createPayment");
            //alert('Generating Payment 2');
            if(component.get("v.cont.organisation") != null && component.get("v.cont.organisation") != '') {
                action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                        "contactId"   : component.get("v.cont.contactId"), 
                                        "co"   : component.get("v.selectedCourseOffering"),
                                        "isConcession"   : component.get("v.cont.concessionCardHolder"),
                                        "streetAddress"   : component.get("v.cont.orgStreetAddress"),
                                        "suburb"   : component.get("v.cont.orgSuburb"),
                                        "state"   : component.get("v.cont.orgState"),
                                        "postcode"   : component.get("v.cont.orgPostcode")
                                      }); 
            }
                
            else {
                action_payment.setParams({ "applicationId"   : component.get("v.cont.applicationId"), 
                                        "contactId"   : component.get("v.cont.contactId"), 
                                        "co"   : component.get("v.selectedCourseOffering"),
                                        "isConcession"   : component.get("v.cont.concessionCardHolder"), 
                                        "streetAddress"   : component.get("v.cont.address"),
                                        "suburb"   : component.get("v.cont.suburb"),
                                        "state"   : component.get("v.cont.state"),
                                        "postcode"   : component.get("v.cont.postCode")
                                      });    
            }

            action_payment.setCallback(this, function(a) {
                
                // Reassign enquiry to faculty
                var action_reassign = component.get("c.reassignEnquiry");
                if(component.get("v.cont.enquiryId") != null && component.get("v.cont.enquiryId") != '') {
                    action_reassign.setParams({ "enqId"   : component.get("v.cont.enquiryId")}); 
                }                
                action_reassign.setCallback(this, function(a) {});
                $A.enqueueAction(action_reassign);                

                // Set payment screen url
                component.set("v.cont.paymentId", a.getReturnValue());              
                var url = a.getReturnValue();
                window.open(url, '_parent');

            });
            $A.enqueueAction(action_payment);        
        }
    },

    redirectToConfirmationPage : function(component, event) {

        var faculty = '';
        faculty = component.get("v.selectedCourseOffering.Course__r.Managing_Faculty__c");

        // Reassign enquiry to faculty
        var action_reassign = component.get("c.reassignEnquiry");
        if(component.get("v.cont.enquiryId") != null && component.get("v.cont.enquiryId") != '') {
            action_reassign.setParams({ "enqId"   : component.get("v.cont.enquiryId")}); 
        }
        
        action_reassign.setCallback(this, function(a) {
            window.open('/CourseRegistration/WaitlistConfirmation?faculty='+faculty,'_parent');      
        });

        $A.enqueueAction(action_reassign);
   
    },

    redirectToOfferingPage : function (component, event) {
        // Disable button
        var btn = event.getSource();
        btn.set("v.disabled",true);

        // Refresh Page
        window.location.reload(true);
    },

    saveDocument : function(component, event, helper) {
        helper.save(component);
    },

    closeAlert : function (component, event, helper){  
        helper.closeAlert(component);
    },

    applyConcession : function(component, event, helper) {
        var isConcession = component.get("v.cont.concessionCardHolder");
        var fee = component.get("v.selectedCourseOffering.Fee__c");
        var concessionFee = component.get("v.selectedCourseOffering.Concession_Fee__c");
        if(isConcession)
            component.set("v.feeToPay",concessionFee);
        else
            component.set("v.feeToPay",fee);
    },

    toggleCourseName : function(component, event, helper) {
        var isGraduate = component.get("v.cont.graduate");
        var courseNameCmp = component.find("previousCourse");
        if(isGraduate) {
            $A.util.removeClass(courseNameCmp, 'disable');
        }
        else {
            component.set("v.cont.previousCourse", "");
            $A.util.addClass(courseNameCmp, 'disable');
        }
    }

})