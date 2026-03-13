/**
 * Created by angelorivera on 10/3/21.
 */

({
    populateEndDate : function(component, event, helper) {
        var sDate = component.get("v.startDate");
        var eDate = new Date(sDate);
        eDate.setDate(eDate.getDate() - 1);
        component.set("v.endDate",eDate.toISOString());
    },

    getFacultyNames : function(component, event, helper) {
        var facNamesMap = component.get("v.facultyNamesMap");
        console.log("------ Faculty with Names: " + JSON.stringify(facNamesMap));
        var selectedFaculty = component.get("v.managingFaculty");
        console.log("------ Selected Faculty: " + selectedFaculty);
        var tempFacultyNames;
        for(var sub in facNamesMap){
            if(selectedFaculty === sub){
                tempFacultyNames = facNamesMap[sub];
            }
        }
        var arr = [];
        for (let i = 0; i < tempFacultyNames.length; i++) {
            console.log(tempFacultyNames[i]);
            arr.push(tempFacultyNames[i]);
        }
        component.set("v.facultyNamesFinalList", arr);
    },

    validateForm :function(component, event, helper) {
        console.log('Start Date: '+ component.get("v.startDate"));
        console.log('End Date: '+ component.get("v.endDate"));
        console.log('Residency Date: '+ component.get("v.residencyDate"));
        console.log('Subclass of the VISA: '+ component.get("v.visaSubclass"));
        console.log('Student Status: '+ component.get("v.studStatus"));
        console.log('Managing Faculty: '+ component.get("v.managingFaculty"));
        console.log('Faculty Name: '+ component.get("v.facultyName"));

        var sDate = component.get("v.startDate");
        var rDate = component.get("v.residencyDate");
        var subclass = component.get("v.visaSubclass");
        var status = component.get("v.studStatus");
        var managingFaculty =  component.get("v.managingFaculty");
        var faculty =  component.get("v.facultyName");

        component.set("v.disableButton", false);

        if(sDate === '' || sDate === null || sDate === undefined) {
            component.set("v.disableButton", true);
        }
        if(subclass === '' || subclass === '--None--' || subclass === null  || subclass === undefined) {
            component.set("v.disableButton", true);
        }
        if(rDate === '' || rDate === null  || rDate === undefined) {
            component.set("v.disableButton", true);
        }
        if(status === '' || status === null  || status === undefined) {
            component.set("v.disableButton", true);
        }
        if(managingFaculty === '' || managingFaculty === '--None--' || managingFaculty === null  || managingFaculty === undefined) {
            component.set("v.disableButton", true);
        }
        if(faculty === '' || faculty === '--None--' || faculty === null  || faculty === undefined) {
            component.set("v.disableButton", true);
        }
    }

});