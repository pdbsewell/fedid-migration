/**
 * Created by angelorivera on 24/2/21.
 */

({

    init: function(cmp) {
        var action = cmp.get('c.doInit');

        action.setCallback(this, function(response) {
            let dataWrapper = response.getReturnValue();
            var state = response.getState();
            console.log("------ VISA: " + JSON.stringify(dataWrapper.mapVisaSubclass));
            console.log("------ MANAGING FACULTY: " + JSON.stringify(dataWrapper.managingFaculty));
            console.log("------ MANAGING FACULTY With Names: " + JSON.stringify(dataWrapper.managingFacultyNames));
            console.log("------ RESPONSE STATE: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(dataWrapper.mapVisaSubclass === undefined || dataWrapper.managingFaculty  === undefined){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": 'Error!',
                        "message": 'error',
                        "type" : 'Error retrieving data.'
                    });
                    toastEvent.fire();
                }else{
                    var visaMap = [];
                    for(var sub in dataWrapper.mapVisaSubclass){
                        visaMap.push({key: sub, value: dataWrapper.mapVisaSubclass[sub]});
                    }
                    cmp.set("v.subclassVisaMap", visaMap);
                    cmp.set("v.managingFacultyList", dataWrapper.managingFaculty);
                    cmp.set("v.facultyNamesMap", dataWrapper.managingFacultyNames);
                }
            }
        });
        $A.enqueueAction(action);
    },

    sendCallout: function(cmp, event, helper) {
        cmp.set("v.showForm",false);
        cmp.set("v.showSpinner",true);
        console.log("------ Sending Callout...");

        var stDate = cmp.get("v.startDate");
        var enDate = cmp.get("v.endDate");
        var resDate = cmp.get("v.residencyDate");

        var tmpStartDate = stDate.substr(0, 10);
        var tmpStartdd = tmpStartDate.substr(8, 2);
        var tmpStartmm = tmpStartDate.substr(5, 2);
        var tmpStartyyyy = tmpStartDate.substr(0, 4);
        var formattedStartDate = tmpStartdd + '/' + tmpStartmm + '/' + tmpStartyyyy;

        var tmpEndDate = enDate.substr(0, 10);
        var tmpEnddd = tmpEndDate.substr(8, 2);
        var tmpEndmm = tmpEndDate.substr(5, 2);
        var tmpEndyyyy = tmpEndDate.substr(0, 4);
        var formattedEndDate = tmpEnddd + '/' + tmpEndmm + '/' + tmpEndyyyy;

        var tmpResDate = resDate.substr(0, 10);
        var tmpResdd = tmpResDate.substr(8, 2);
        var tmpResmm = tmpResDate.substr(5, 2);
        var tmpResyyyy = tmpResDate.substr(0, 4);
        var formattedResDate = tmpResdd + '/' + tmpResmm + '/' + tmpResyyyy;

        console.log("------ Case Id: " +  cmp.get("v.recordId"));
        console.log("------ Start Date: " +  formattedStartDate);
        console.log("------ End Date: " + formattedEndDate);
        console.log("------ Residency Date: " +  formattedResDate);
        console.log("------ Subclass Of The Visa: " +  cmp.get("v.visaSubclass"));
        console.log("------ Student Status: " +  cmp.get("v.studStatus"));
        console.log("------ Faculty Name: " +  cmp.get("v.facultyName"));

        var action = cmp.get('c.changeOfResidency');
        action.setParams({
            caseId : cmp.get("v.recordId"),
            sDate : formattedStartDate,
            eDate : formattedEndDate,
            rDate : formattedResDate,
            visa : cmp.get("v.visaSubclass"),
            status : cmp.get("v.studStatus"),
            faculty : cmp.get("v.facultyName")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('success')){
                    title = 'Error!';
                    type = 'error';
                }else{
                    title = 'Success!';
                    type = 'success';
                }
                message = ret;

                cmp.set("v.showSpinner",false);
                $A.get('e.force:closeQuickAction').fire();
                $A.get('e.force:refreshView').fire();

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": message,
                    "type" : type
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    handleChangeStartDate : function(component, event, helper) {
        helper.populateEndDate(component, event, helper);
        helper.validateForm(component, event, helper);
    },

    handleChangeVisa : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },

    handleChangeFaculty : function (component, event, helper){
        helper.getFacultyNames(component, event, helper);
        component.set("v.facultyName", '');
        helper.validateForm(component, event, helper);
    },

    handleChangeFacultyName : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },

    handleChangeResidency : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },

    handleChangeStatus : function (component, event, helper){
        helper.validateForm(component, event, helper);
    },
})