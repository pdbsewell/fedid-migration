({
    doInit : function(component, event, helper) {

        let defaultFilterObject = {keyWord: null,
                                    locationKeyWord: null,
                                    salaryLowerBound: null,
                                    salaryUpperBound: null
                                };
        component.set("v.filterObject", defaultFilterObject);

        var queryOpenJobs = component.get('c.SERVER_queryOpenJobs');

        queryOpenJobs.setCallback(this, function(response){

            var state = response.getState();
            var result = response.getReturnValue();

            console.log( (JSON.parse(JSON.stringify(response.getReturnValue()))) );

            if (state === "SUCCESS") {
                component.set('v.jobList', result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var jobListToDisplay = result;

                if (itemsPerPage < result.length) {
                    jobListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(jobListToDisplay);
                component.set("v.jobListToDisplay", jobListToDisplay);
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(queryOpenJobs);      
    },
    applyFilter : function(component, event, helper) {

        let positionType = component.find("jobPositionType").get("v.value");
        let classDegreeLevel = component.find("classLevelDegreeLevel").get("v.value");
        let filterObject = component.get("v.filterObject");

        filterObject.positionType = positionType;
        filterObject.classDegreeLevel = classDegreeLevel;

        console.log(positionType);
        console.log(classDegreeLevel);
        console.log(JSON.parse(JSON.stringify(filterObject)));

        var queryPostedJobs = component.get('c.SERVER_queryPostedJobsWithFilter');

        queryPostedJobs.setParams({
            filterCriteria: filterObject
        });

        queryPostedJobs.setCallback(this, function(response){

            var state = response.getState();

            // console.log( (JSON.parse(JSON.stringify(response.getReturnValue()))) );
            
            var result = response.getReturnValue();

            if (state === "SUCCESS") {
                component.set('v.jobList', result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var jobListToDisplay = result;

                if (itemsPerPage < result.length) {
                    jobListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(jobListToDisplay);
                component.set("v.jobListToDisplay", jobListToDisplay);
                
                component.set("v.currentPage", 1);
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(queryPostedJobs);
    },
    openJobModal : function(component, event, helper) {

        let jobRecOnDisplay = component.get("v.jobList")[event.currentTarget.getAttribute("data-index")];
        // console.log( JSON.parse(JSON.stringify(jobRecOnDisplay)) );
        component.set("v.jobRecOnDisplay", jobRecOnDisplay);
        component.set("v.clickedJobId", jobRecOnDisplay.Id);

        helper.showPopupHelper(component,'backdrop','slds-backdrop--');
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
    },
    closeJobModal : function(component, event, helper) {
        helper.hidePopupHelper(component,'backdrop','slds-backdrop--');
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
    },
    handleUploadFinished : function(component, event, helper) {
        console.log('finish');
    },
    
    
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var jobList = cmp.get("v.jobList");

        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(jobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var jobListToDisplay = jobList.slice(start, end);

        cmp.set("v.jobListToDisplay", jobListToDisplay);

        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var jobList = cmp.get("v.jobList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(jobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > jobList.length) {
            end = jobList.length;
        }

        var jobListToDisplay = jobList.slice(start, end);

        cmp.set("v.jobListToDisplay", jobListToDisplay);

        cmp.set("v.currentPage", currentPage + 1);
    },
})