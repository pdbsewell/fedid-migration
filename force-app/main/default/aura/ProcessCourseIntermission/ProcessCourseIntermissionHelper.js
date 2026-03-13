/**
 * Created by angelorivera on 5/5/21.
 */

({

    formatDate:function (dateToFormat){
        var tmpStartDate = dateToFormat.substr(0, 10);
        var tmpStartdd = tmpStartDate.substr(8, 2);
        var tmpStartmm = tmpStartDate.substr(5, 2);
        var tmpStartyyyy = tmpStartDate.substr(0, 4);
        var formattedStartDate = tmpStartdd + '/' + tmpStartmm + '/' + tmpStartyyyy;
        return  formattedStartDate;
    },
    
    processDates : function (date){
   		var parts = date.split("/");
   		return new Date(parts[2], parts[1] - 1, parts[0]);
	},

    validateForm :function(component, event, helper){

        var sDate = component.get("v.startDate");
        var eDate;
        
        if(component.get("v.selectedCalendar")){
            eDate = component.get("v.selectedCalendar")
        }else{
            eDate = component.get("v.endDate");
        }
        var courseCode = component.get("v.courseCode");
        var secondaryReason = component.get("v.secondaryReason");
        var secondaryReasonFreeText = component.get("v.secondaryReasonFreeText");
        var enrolmentExceptions_acadYear =  component.get("v.enrolmentExceptions_acadYear");
        var enrolmentExceptions_minValue =  component.get("v.enrolmentExceptions_minValue");
        var enrolmentExceptions_maxValue =  component.get("v.enrolmentExceptions_maxValue");

        component.set("v.disableButton", false);

        if(sDate === '' || sDate === null || sDate === undefined) {
            component.set("v.disableButton", true);
        }
        if(courseCode === '' || courseCode === '--None--' || courseCode === null  || courseCode === undefined) {
            component.set("v.disableButton", true);
        }
        if(secondaryReason === '' || secondaryReason === '--None--' || secondaryReason === null  || secondaryReason === undefined) {
            component.set("v.disableButton", true);
        }
        if(eDate === '' || eDate === null  || eDate === undefined) {
            component.set("v.disableButton", true);
        }
        if(secondaryReason === 'Other' ){
            component.set("v.showSecondaryReasonFreeText", true);
        }else{
            component.set("v.showSecondaryReasonFreeText", false);
        }

        var bAcadYrEmpty = false;
        var bMinValueEmpty = false;
        var bMaxValueEmpty = false;
        if(enrolmentExceptions_acadYear === '' || enrolmentExceptions_acadYear === null  || enrolmentExceptions_acadYear === undefined) {
            bAcadYrEmpty = true;
        }
        if(enrolmentExceptions_minValue === '' || enrolmentExceptions_minValue === null  || enrolmentExceptions_minValue === undefined) {
            bMinValueEmpty = true
        }
        if(enrolmentExceptions_maxValue === '' || enrolmentExceptions_maxValue === null  || enrolmentExceptions_maxValue === undefined) {
            bMaxValueEmpty = true
        }

        if(!bAcadYrEmpty && (bMinValueEmpty || bMaxValueEmpty)){
            component.set("v.disableButton", true);
        }
        if(!bMinValueEmpty && (bAcadYrEmpty || bMaxValueEmpty)){
            component.set("v.disableButton", true);
        }
        if(!bMaxValueEmpty && (bAcadYrEmpty || bMinValueEmpty)){
            component.set("v.disableButton", true);
        }
        if(!bMaxValueEmpty && !bAcadYrEmpty && !bMinValueEmpty){
            component.set("v.disableButton", false);
        }
    }

});