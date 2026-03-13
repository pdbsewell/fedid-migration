({
    /*******************************************************************************
     * @author       Ant Custodio
     * @date         3.Apr.2017
     * @description  initial actions on page load - retrieve the contact details and
     *                    check if read only
     * @revision
     *******************************************************************************/
    doInit: function (component, event, helper) {

        helper.parseApplicationIdFromUrl(component);
        helper.retrieveUserRecord(component, helper);
        
        helper.initLoad(component);

        /*        moved to helper InitLoad
        //retrieves the user record
        helper.retrieveUserRecord(component, helper);

        //retrieve salutations list
        helper.retrievePicklistValues(component.get("c.retrieveSalutations"), component.find("salutationOptions"));

        //retrieve salutations list
        helper.retrievePicklistValues(component.get("c.retrieveGender"), component.find("GenderOptions"));

        //retrieve campus of study list
        //helper.retrievePicklistValues(component.get("c.retrieveCampusOfStudyOptions"), component.find("campusOfStudyOptions"));
        helper.initCampusLocationOptions(component);
        
        //retrieve citizenship type list
        //helper.retrievePicklistValues(component.get("c.retrieveCitizenshipTypeOptions"), component.find("CitizenshipTypeOptions"));
        helper.initCitizenshipTypeOptions(component);
        
        //retrieve previous institutions list
        helper.retrievePicklistValues(component.get("c.retrievePreviousInstitutions"), component.find("previousinstitution"));

        //retrieve state list
        helper.retrievePicklistValues(component.get("c.retrieveState"), component.find("StateOptions"));

        //retrieve state list
        helper.retrieveYESNOPicklistValues(component.find("atsiOptions")); 

        //retrieve state list
        helper.retrieveYESNOPicklistValues(component.find("addressType"));

        //retrieve countries list
        helper.retrievePicklistValues(component.get("c.retrieveCountries"), component.find("countryOptions"));
        
        */
    },

    initDatePicker: function (component, event, helper) {
        if (component.get("v.initializeDatePicker")) {
            TinyDatePicker(document.querySelector('.ux-datepicker'), {
                // Used to convert a date into a string to be used as the value of input
                format: function (date) {
                    return moment(date).format('DD/MM/YYYY');
                },
                // Used to parse a date string and return a date (e.g. parsing the input value)
                parse: function (str) {
                    var date = moment(str, 'DD/MM/YYYY');
                    return new Date(moment(str, 'DD/MM/YYYY'));
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
                min: moment().subtract(100, 'y').format('DD/MM/YYYY'),
                // Specifies the maximum date that can be selected
                max: moment().format('DD/MM/YYYY'),
                // Place datepicker selector on this date if field is still empty
                preselectedDate: moment().format('DD/MM/YYYY'),
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
                    $('.dp-current').removeClass('dp-current');
                    $('.dp-cal-year').trigger('focus');
                },
                // A function which is called any time the month is selected
                // in the month menu
                onSelectMonth: function (context) {
                    // context is the datepicker context, detailed below
                    $('.dp-current').removeClass('dp-current');
                    $('.dp-cal-month').trigger('focus');
                },
            }).open();

            component.set("v.initializeDatePicker", false)
        }

    },

    /*******************************************************************************
     * @author       Ant Custodio
     * @date         3.Apr.2017
     * @description  saves the user reord
     * @revision
     *******************************************************************************/
    saveRecord: function (component, event, helper) {
        console.log('applicationPortalController::saveRecord()');
        helper.updateUser(component, event, helper);
        //console.log('34343434345');
    },

    saveRecordAndContinue: function (component, event, helper)
    {
        console.log("Test");
        helper.updateUser(component, event, helper, true)
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         11.May.2017         
    * @description  close the popup
    * @revision     
    *******************************************************************************/
    closeViewModal : function (component, event, helper){     
        //close the confirmation popup
        component.set("v.showAgeCheckPopup", false);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         11.May.2017         
    * @description  continue on saving the form
    * @revision     
    *******************************************************************************/
    continueSaving : function (component, event, helper){
        //set acknowledged to true
        component.set("v.isAgeAcknowledged", true);
        helper.updateUser(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.Apr.2017         
    * @description  sets the isEdit variable to true
    * @revision     
    *******************************************************************************/
    editDetails : function (component, event, helper) {
        helper.retrieveUserRecord(component, helper);
        component.set("v.isEdit", true);
    },
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.Apr.2017         
    * @description  cancels the editing and goes back to read only mode
    * @revision     
    *******************************************************************************/
    cancelEdit : function (component, event, helper) {
        //retrieves the user record
        helper.retrieveUserRecord(component, helper);
        helper.clearAllErrors(component);

        component.set("v.isEdit", false);
    },
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.Apr.2017         
    * @description  gets the selected gender
    * @revision     
    *******************************************************************************/
    studiedBefore_onSelectChange : function(component, event, helper) {
        // first get the div element. by using aura:id
        var changeElement = component.find("DivID");
        // by using $A.util.toggleClass add-remove slds-hide class
        $A.util.toggleClass(changeElement, "slds-hide");
        //remove the values when value is set to no
        helper.removeValuesIfFalse(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  show the spinner when page is loading
    * @revision     
    *******************************************************************************/
    waiting: function(component, event, helper) {
        /*
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "block";
        }
        */
        console.debug('appPortal show spinner');
        component.set('v.showSpinner', true);
        
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         7.Apr.2017         
    * @description  hide the spinner when finished loading
    * @revision     
    *******************************************************************************/
    doneWaiting: function(component, event, helper) {
        /*
        var accSpinner = document.getElementById("Accspinner");
        if (accSpinner != null) {
            accSpinner.style.display = "none";
        }
        */
        component.set('v.showSpinner', false);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of country 
    * @revision     
    *******************************************************************************/
    salutation_onChange: function(component, event, helper) {
        var dynamicCmp = component.find("salutationOptions");
        component.set("v.userRec.App_Salutation__c", dynamicCmp.get("v.value"));

        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of country 
    * @revision     
    *******************************************************************************/
    dob_onChange: function(component, event, helper) {
        //date on screen validation
        helper.validateDOB(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of Gender 
    * @revision     
    *******************************************************************************/
    Gender_onChange: function(component, event, helper) {
        helper.populateGender(component);
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.May.2017         
    * @description  set value on change of Citizenship 
    * @revision     
    *******************************************************************************/
    CitizenshipType_onChange: function(component, event, helper) {
        //helper.showAndHideAccessAndEquity(component, helper);
        helper.populateCitizenshipType(component, helper);
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.May.2017         
    * @description  set value on change of Citizenship 
    * @revision     
    *******************************************************************************/
    addressType_onChange: function(component, event, helper) {
        helper.populateAddressType(component);
        helper.clearAllErrors(component);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         3.May.2017         
    * @description  set value on campus of study
    * @revision     
    *******************************************************************************/
    campusOfStudy_onChange: function(component, event, helper) {
        helper.validateCampusOfStudy(component);
        helper.clearError_onChange(component, event);
    },
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of State 
    * @revision     
    *******************************************************************************/
    State_onChange: function(component, event, helper) {
        var dynamicCmp = component.find("StateOptions");
        component.set("v.userRec.State", dynamicCmp.get("v.value"));

        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of ATSI 
    * @revision     
    *******************************************************************************/
    ATSI_onChange: function(component, event, helper) {
        helper.populateATSI(component);
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         21.May.2018
    * @description  set value on change of disability
    * @revision     
    *******************************************************************************/
    disabilityOnChange: function(component, event, helper) {
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         21.May.2018
    * @description  hide the text
    * @revision     
    *******************************************************************************/
   hideTheDisabilityText: function(component, event, helper) {
        document.getElementById("disabilityTextDivId").style.display = "none";
        document.getElementById("disabilityErrorMessageUlId").style.display = "none";
        component.set("v.userRec.App_HasDisabilities__c", 'No');
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         21.May.2018
    * @description  hide the text
    * @revision     
    *******************************************************************************/
   showTheDisabilityText: function(component, event, helper) {
        document.getElementById("disabilityTextDivId").style.display = "block";
        document.getElementById("disabilityErrorMessageUlId").style.display = "none";
        component.set("v.userRec.App_HasDisabilities__c", 'Yes');
    },

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         9.Apr.2017         
    * @description  set value on change of State 
    * @revision     
    *******************************************************************************/
    PrevSchools_onChange: function(component, event, helper) {
        var dynamicCmp = component.find("previousinstitution");
        component.set("v.userRec.App_Previous_Monash_Institution__c", dynamicCmp.get("v.value"));
        helper.clearError_onChange(component, event);
    },

    /*******************************************************************************
    * @author       Majid Reisi Dehkordi
    * @date         28.Mar.2018         
    * @description  Make sure the Previous Id in Staging is numbers.
    * @revision     
    *******************************************************************************/
   PrevMonashId_onChange: function(component, event, helper) {
        helper.validatePreviousStudentId(component);
        //helper.clearError_onChange(component, event);
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
})