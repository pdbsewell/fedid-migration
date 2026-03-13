({
	/*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  initial actions on page load - retrieve the contact details and
    * 					check if read only
    * @revision     
    *******************************************************************************/
    doInit : function(component, event, helper) {
        /*******************************************************************************
        * @author       Ant Custodio
        * @date         12.Apr.2017         
        * @description  retrieve the application Id from the parameter
        * @revision     
        *******************************************************************************/
        let sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        let sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        let sParameterName;

        let retrievedAppId = '';
        for (let i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.
            for (let j = 0; j < sParameterName.length; j++) {
                if (sParameterName[j] === 'appId') { //get the app Id from the parameter
                    retrievedAppId = sParameterName[j+1];
                }
            }
        }
        if (retrievedAppId != '') {
            component.set("v.appId", retrievedAppId);
        }

        //retrieve the work experience list
        helper.retrieveWorkExpList(component);
        helper.retrieveContactId(component);
    },

    initStartDatePicker : function (component, event, helper) {
        if(component.get("v.initializeStartDatePicker")){
            TinyDatePicker(document.querySelector('.ux-startdatepicker'), {
              // Used to convert a date into a string to be used as the value of input 
              format: function (date) {
                return moment(date).format('DD/MMM/YYYY');
              },
              // Used to parse a date string and return a date (e.g. parsing the input value)
              parse: function (str) {
                var date = moment(str,'DD/MMM/YYYY');
                return new Date(moment(str,'DD/MMM/YYYY'));
              },
              // Names of months, in order 
              months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
              // Names of days of week, in order 
              days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
              // The text for the button used to set the date to today's date 
              today: 'Today',
              // The text for the button used to clear the input value 
              clear: 'Clear',
              // The text for the button used to close the form 
              close: 'Close',
              // Specifies the minimum date that can be selected DD/MM/YYYY
              min: moment().subtract(100,'y').format('DD/MMM/YYYY'),
              // Specifies the maximum date that can be selected 
              max: moment().format('DD/MMM/YYYY'),
              // Place datepicker selector on this date if field is still empty 
              preselectedDate: moment().format('DD/MMM/YYYY'),
              // There are two modes: dp-modal (the default) and dp-below. 
              // dp-modal makes the date picker show up as a modal. 
              // dp-below makes it show up beneath its input element. 
              mode: 'dp-below',
              // Whether to use Monday as start of the week 
              weekStartsMonday: false,
              // A function which is called any time the date picker opens 
              onOpen: function (context) {
                // context is the datepicker context, detailed below 
              }, 
              // A function which is called any time the year is selected 
              // in the year menu 
              onSelectYear: function (context) {
                // context is the datepicker context, detailed below 
              },
              // A function which is called any time the month is selected 
              // in the month menu 
              onSelectMonth: function (context) {
                // context is the datepicker context, detailed below 
              },
            }).open();

            component.set("v.initializeStartDatePicker", false)
        }
        
    },

    initEndDatePicker : function (component, event, helper) {
        if(component.get("v.initializeEndDatePicker")){
            TinyDatePicker(document.querySelector('.ux-enddatepicker'), {
              // Used to convert a date into a string to be used as the value of input 
              format: function (date) {
                return moment(date).format('DD/MMM/YYYY');
              },
              // Used to parse a date string and return a date (e.g. parsing the input value)
              parse: function (str) {
                var date = moment(str,'DD/MMM/YYYY');
                return new Date(moment(str,'DD/MMM/YYYY'));
              },
              // Names of months, in order 
              months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
              // Names of days of week, in order 
              days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
              // The text for the button used to set the date to today's date 
              today: 'Today',
              // The text for the button used to clear the input value 
              clear: 'Clear',
              // The text for the button used to close the form 
              close: 'Close',
              // Specifies the minimum date that can be selected DD/MM/YYYY
              min: moment().subtract(100,'y').format('DD/MMM/YYYY'),
              // Specifies the maximum date that can be selected 
              max: moment().format('DD/MMM/YYYY'),
              // Place datepicker selector on this date if field is still empty 
              preselectedDate: moment().format('DD/MMM/YYYY'),
              // There are two modes: dp-modal (the default) and dp-below. 
              // dp-modal makes the date picker show up as a modal. 
              // dp-below makes it show up beneath its input element. 
              mode: 'dp-below',
              // Whether to use Monday as start of the week 
              weekStartsMonday: false,
              // A function which is called any time the date picker opens 
              onOpen: function (context) {
                // context is the datepicker context, detailed below 
              }, 
              // A function which is called any time the year is selected 
              // in the year menu 
              onSelectYear: function (context) {
                // context is the datepicker context, detailed below 
              },
              // A function which is called any time the month is selected 
              // in the month menu 
              onSelectMonth: function (context) {
                // context is the datepicker context, detailed below 
              },
            }).open();

            component.set("v.initializeEndDatePicker", false)
        }
        
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
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
    * @date         7.Apr.2017         
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
    * @date         7.Apr.2017         
    * @description  shows/hides panel
    * @revision     
    *******************************************************************************/
    showHideComponent : function (component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        
        if (isExpanded) {
            isExpanded = false;
        } else {
            isExpanded = true;
        }
		component.set("v.isExpanded", isExpanded);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  shows work experience form for inserting a new one
    * @revision     
    *******************************************************************************/
    showWorkExperienceForm : function (component, event, helper) {
        //reinitialise the record and show the edit mode
        component.set("v.workExpMode", "New");
        helper.clearAllErrors(component);
        helper.createNewRecord(component);
        window.location.hash = '#newWorkExpHeader';
        helper.createWorkExpAndRetrieveID(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  hides work experience form for inserting a new one
    * @revision     
    *******************************************************************************/
   hideOrDeleteWorkExp : function (component, event, helper) {
        if(component.get("v.workExpMode") === "New")
        {
            component.set("v.selRecToDelId", component.get("v.appWorkExperienceProvidedId"));
            helper.deleteWorkExperience(component, event, helper);
        }
        component.set("v.showForm", false);
        helper.clearAllErrors(component);
        window.location.hash = '#myWorkExpDiv';
    },

    // /*******************************************************************************
    // * @author       Ant Custodio
    // * @date         7.Apr.2017         
    // * @description  initial actions on page load - retrieve the contact details and
    // *                   check if read only
    // * @revision     
    // *******************************************************************************/
    // addNewWorkExperience : function(component, event, helper) {
    //     //validate the form before saving
    //     var contWorkExpRec = component.get("v.contWorkExp");
    //     contWorkExpRec.sobjectType = 'Work_Experience__c';
    //     helper.validateForm(component, contWorkExpRec);

    //     let hasError = "";//component.get("v.hasErrors");
    //     if (!hasError) {
    //         component.set("v.errorMessage", "");
    //         /*******************************************************************************
    //         * @author       Ant Custodio
    //         * @date         12.Apr.2017         
    //         * @description  retrieve the contact details
    //         * @revision     
    //         *******************************************************************************/
    //         var action_addNewWorkExperience = component.get("c.insertNewWorkExpRecord");

    //         //set the parameters
    //         if (component.get("v.isAppComponent") == true) {
    //             action_addNewWorkExperience = component.get("c.insertNewWorkExpRecordWithApp");
    //             action_addNewWorkExperience.setParams({ "workExpToInsert" : contWorkExpRec, 
    //                                                     "applicationId"   : component.get("v.appId"), 
    //                                                     "isEdit"          : component.get("v.isEditWorkExperience") 
    //                                                   });
    //         } else {
    //             action_addNewWorkExperience.setParams({ "workExpToInsert"   : contWorkExpRec });
    //         }
            
    //         action_addNewWorkExperience.setCallback(this, function(a) {
    //             var state = a.getState();
    //             if (state == "ERROR") {
    //                 var errors = a.getError();
    //                 if (errors) {
    //                     if (errors[0] && errors[0].message) {
    //                         console.log("Error message: " + 
    //                                  errors[0].message);
    //                         var splitString = errors[0].message.split(":");
    //                         component.set("v.errorMessage", splitString[3] + ': ' + splitString[4]);
    //                         window.location.hash = '#appWE_errorDiv';
    //                     }
    //                 } else {
    //                     console.log("Unknown error");
    //                 }
    //             } else {
    //                 $A.util.removeClass(component.find("endDateId"), 'dateError');
    //                 component.set("v.enddateErrorMessage", "");
    //                 component.set("v.invalidEndDate", false);

    //                 /*******************************************************************************
    //                 * @author       Ant Custodio
    //                 * @date         12.Apr.2017         
    //                 * @description  retrieve the contact details
    //                 * @revision     
    //                 *******************************************************************************/
    //                 var action_retrieveWorkExpList = component.get("c.retrieveWorkExpList");
    //                 if (component.get("v.isAppComponent") == true) {
    //                     action_retrieveWorkExpList = component.get("c.retrieveAppWorkExpProvidedList");
    //                     action_retrieveWorkExpList.setParams({ "applicationId"   : component.get("v.appId") });
    //                 }
    //                 action_retrieveWorkExpList.setCallback(this, function(a) {
    //                     component.set("v.workExpList", a.getReturnValue());
                        
    //                     /*******************************************************************************
    //                     * @author       Ant Custodio
    //                     * @date         26.Apr.2017         
    //                     * @description  attach the document added on the form
    //                     * @revision     
    //                     *******************************************************************************/
    //                     /*var childCmp = component.find("addDocWorkExp");
    //                     //action 3, insert contact document
    //                     childCmp.uploadDocumentMethod();*/
    //                     //close the form
    //                     component.set("v.showForm", false);
    //                     window.location.hash = '#myWorkExpDiv';
    //                 });
    //                 //action 2, retrieve qualification list
    //                 $A.enqueueAction(action_retrieveWorkExpList);
    //             }
    //         });
    //         //action 1, adds a new record
    //         $A.enqueueAction(action_addNewWorkExperience);
    //     } else {
    //         component.set("v.errorMessage", "There are errors on your page. Please review your form.");
    //         window.location.hash = '#appWE_errorDiv';
    //     }
    // },

    onEditWorkExperience : function(component, event, helper) {
        component.set("v.workExpMode", "Edit");
        component.set("v.isEditWorkExperience", true);

        var source = event.getSource(); // this would give that particular component
        var workExId = source.get("v.name"); // returns the id

        //assign Id and show the edit document screen
        component.set("v.selRecToEditId", workExId);
        
        helper.retrieveWorkExpToEdit(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  deletes the work experience record
    * @revision     
    *******************************************************************************/
    deleteWorkExperience : function (component, event, helper){     
        helper.deleteWorkExperience(component, event, helper);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  cancel the deletion
    * @revision     
    *******************************************************************************/
    cancelDelete : function (component, event, helper){     
        //close the confirmation popup
        component.set("v.showConfirmPopup", false);
    }, 


    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  cancel the deletion
    * @revision     
    *******************************************************************************/
    showConfirmDeletePopup : function (component, event, helper){     
        /*var domEvent = event.getParams().domEvent;
        var bodySpan = domEvent.target.nextSibling;
        
        var workExpId = bodySpan.dataset.id;*/
        var source = event.getSource(); // this would give that particular component
        var workExpId = source.get("v.name"); // returns the id

        //assign Id and show the confirmation popup
        component.set("v.selRecToDelId", workExpId);
        component.set("v.showConfirmPopup", true);
    }, 

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         17.May.2017         
    * @description  check date achieved/planned
    * @revision     
    *******************************************************************************/
    startDate_onChange: function(component, event, helper) {
        var enteredDate = component.get("v.selectedStartDate");

        var regDateFormat = /^\d{4}[\-\/\s]?((((0[13578])|(1[02]))[\-\/\s]?(([0-2][0-9])|(3[01])))|(((0[469])|(11))[\-\/\s]?(([0-2][0-9])|(30)))|(02[\-\/\s]?[0-2][0-9]))$/;
        
        $A.util.removeClass(component.find("startDateId"), 'dateError');
        component.set("v.startdateErrorMessage", "");
        component.set("v.invalidStartDate", false);

        if (enteredDate == 'Invalid Date') {
            component.set("v.startdateErrorMessage", "Please enter a valid date (dd/mmm/yyyy).");
            $A.util.addClass(component.find("startDateId"), 'dateError');
            component.set("v.invalidStartDate", true);
        } else if (!enteredDate.match(regDateFormat)) {
            component.set("v.startdateErrorMessage", "Please enter a valid date (dd/mmm/yyyy).");
            $A.util.addClass(component.find("startDateId"), 'dateError');
            component.set("v.invalidStartDate", true);
        } else if (enteredDate != null ) {
            enteredDate = new Date(enteredDate.split("-")[0], enteredDate.split("-")[1]-1, enteredDate.split("-")[2]);
            var dateNow = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
            var earliestDate = new Date(new Date().getFullYear()-99, new Date().getMonth(), new Date().getDate());

            if(enteredDate > dateNow){
                component.set("v.startdateErrorMessage", "Please check the year in your Start Date - you have entered a future date");
                $A.util.addClass(component.find("startDateId"), 'dateError');
                component.set("v.invalidStartDate", true);
            } else if(enteredDate <= earliestDate) {
                component.set("v.startdateErrorMessage", "Please check the year in your Start date.");
                $A.util.addClass(component.find("startDateId"), 'dateError');
                component.set("v.invalidStartDate", true);
            }
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         17.May.2017         
    * @description  check date achieved/planned
    * @revision     
    *******************************************************************************/
    endDate_onChange: function(component, event, helper) {
        var enteredDate = component.get("v.selectedEndDate");

        var regDateFormat = /^\d{4}[\-\/\s]?((((0[13578])|(1[02]))[\-\/\s]?(([0-2][0-9])|(3[01])))|(((0[469])|(11))[\-\/\s]?(([0-2][0-9])|(30)))|(02[\-\/\s]?[0-2][0-9]))$/;
        
        $A.util.removeClass(component.find("endDateId"), 'dateError');
        component.set("v.enddateErrorMessage", "");
        component.set("v.invalidEndDate", false);

        if(enteredDate != null && enteredDate != ''){
          if (enteredDate == 'Invalid Date') {
              component.set("v.enddateErrorMessage", "Please enter a valid date (dd/mmm/yyyy).");
              $A.util.addClass(component.find("endDateId"), 'dateError');
              component.set("v.invalidEndDate", true);
          } else if (!enteredDate.match(regDateFormat)) {
              component.set("v.enddateErrorMessage", "Please enter a valid date (dd/mmm/yyyy).");
              $A.util.addClass(component.find("endDateId"), 'dateError');
              component.set("v.invalidEndDate", true);
          } else if (enteredDate != null) {
              enteredDate = new Date(enteredDate.split("-")[0], enteredDate.split("-")[1]-1, enteredDate.split("-")[2]);
              var dateNow = new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate());
              var earliestDate = new Date(new Date().getFullYear()-99, new Date().getMonth(), new Date().getDate());

              if(enteredDate > dateNow){
                  component.set("v.enddateErrorMessage", "Please check the year in your End Date - you have entered a future date");
                  $A.util.addClass(component.find("endDateId"), 'dateError');
                  component.set("v.invalidEndDate", true);
              } else if(enteredDate <= earliestDate) {
                  component.set("v.enddateErrorMessage", "Please check the year in your End date.");
                  $A.util.addClass(component.find("endDateId"), 'dateError');
                  component.set("v.invalidEndDate", true);
              }
          }
        }
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         4.Jun.2017         
    * @description  on change general behaviour
    * @revision     
    *******************************************************************************/
    onChangeGeneralBehaviour: function(component, event, helper) {
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         11.Jul.2017         
    * @description  shows the view popup
    * @revision     
    *******************************************************************************/
    showviewQualPopup : function (component, event, helper){
        var source = event.getSource(); // this would give that particular component
        var workExpId = source.get("v.name"); // returns the id
        //assign Id and show the confirmation popup
        helper.retrieveSelectedQualification(component, workExpId);
        component.set("v.showViewPopup", true);
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         11.Jul.2017        
    * @description  cancel the deletion
    * @revision     
    *******************************************************************************/
    closeViewModal : function (component, event, helper){     
        //close the confirmation popup
        component.set("v.showViewPopup", false);
    },

    handleSubmit : function(component, event, helper) {
        event.preventDefault(); // Prevent default submit
        let fields = event.getParam("fields");
        component.set("v.errorMessage", "");

        let errorMessages = [];
        if(
            !fields["Employer_Name__c"] ||
            !fields["Position__c"] ||
            !fields["Start_Date__c"] ||
            !fields["Contact_Person_First_Name__c"] ||
            !fields["Contact_Person_Last_Name__c"] ||
            !fields["Contact_Person_Email__c"] ||
            !fields["Contact_Person_Phone__c"] ||
            !fields["Country__c"]
        )
        {
            errorMessages.push("Please fill in all of the fields.");
            if(!fields["Country__c"] )
            {
                errorMessages.push("Please pick the country from the country list.");
            }
        }

        if(fields["End_Date__c"] && fields["Start_Date__c"])
        {
            if(new Date(fields["End_Date__c"]) <= new Date(fields["Start_Date__c"]))
            {
                errorMessages.push("Please enter valid date(s). Please check the Start Date and End Date.");
            }
        }

        if(new Date() < new Date(fields["End_Date__c"]) || new Date() < new Date(fields["Start_Date__c"]))
        {
            errorMessages.push("A date in the future is not acceptable. Please change the date(s).");
        }

        if(errorMessages.length === 0)
        {
            // Populate Description field
            fields["Contact__c"] =  component.get("v.contactId"); 
            component.find('createWorkExp').submit(fields); // Submit form
            //close the form
            component.set("v.showForm", false);
            window.location.hash = '#myWorkExpDiv';
            //THIS NEEDS TO GO
            var urlEvent = $A.get("e.force:refreshView");
            urlEvent.fire();
        } else
        {
            let errorMessagesString = '';
            for(var eMessage = 0; eMessage < errorMessages.length; ++eMessage)
            {
                errorMessagesString += errorMessages[eMessage] + '<br/>';
            }
            component.set("v.errorMessage", errorMessagesString);
            window.location.hash = '#appWE_errorDiv';

        }

    },

    handleSuccess : function(component, event, helper) {
        console.log("Successful");
        var payload = event.getParams().response;
        helper.retrieveWorkExpList(component)
        console.log(JSON.stringify(payload));
    },

    onerror : function(component, event, helper) {
        var payload = event.getParams().response;
        console.log(JSON.stringify(payload));
    },
    
    keyCheck:function(component, event, helper)
    {
        //console.log('keycheck:' + event.which);
        if (event.which == 13)
        {
            //helper.onSend(component, event);
            event.preventDefault();
            return false;
        }    
    }
})