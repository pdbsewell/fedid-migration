({
    doInit : function(component, event, helper) {

        var queryPostedJobs = component.get('c.SERVER_queryPostedJobs');

        queryPostedJobs.setCallback(this, function(response){

            var state = response.getState();
            
            var result = response.getReturnValue();

            console.log( (JSON.parse(JSON.stringify(result))) );

            if (state === "SUCCESS") {
                component.set('v.postedJobList', result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var postedJobListToDisplay = result;

                if (itemsPerPage < result.length) {
                    postedJobListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(postedJobListToDisplay);
                component.set("v.postedJobListToDisplay", postedJobListToDisplay);
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(queryPostedJobs);

        // var postedJobList = [
        //     {
        //         companyName: 'Service Now',
        //         jobTitle: 'Salesforce Developer',
        //         description: 'Not Selected',
        //         postedDate: '02/19/2016'
        //     },
        //     {
        //         companyName: 'Avetta',
        //         jobTitle: 'SQL Developer',
        //         description: 'Closed',
        //         postedDate: '02/19/2014'
        //     },
        //     {
        //         companyName: 'Appfolio',
        //         jobTitle: 'Salesforce Admin',
        //         description: 'Not Selected',
        //         postedDate: '02/19/2013'
        //     },
        //     {
        //         companyName: 'Zynga',
        //         jobTitle: 'UI Designer',
        //         description: 'In Progress',
        //         postedDate: '02/19/2012'
        //     },
        //     {
        //         companyName: 'Yelp',
        //         jobTitle: 'UI Designer',
        //         description: 'In Progress',
        //         postedDate: '02/04/2011'
        //     }
        // ];        
    },
    openJobModal : function(component, event, helper) {
        helper.showPopupHelper(component,'backdrop','slds-backdrop--');
        helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
    },
    closeJobModal : function(component, event, helper) {
        helper.hidePopupHelper(component,'backdrop','slds-backdrop--');
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
    },
    postNewJob : function(component, event, helper) {

        document.getElementById("spinner").className = "slds-show";

        var jobPositionType = component.find("jobPositionType").get("v.value");
        var classDegreeLevel = component.find("classLevelDegreeLevel").get("v.value");
        var jobRec = component.get("v.jobAppRecord");

        jobRec.Position_Type__c = jobPositionType;
        jobRec.Class_Level_Degree_Level__c = classDegreeLevel;

        console.log(JSON.parse(JSON.stringify(jobRec)));

        var createJobPost = component.get('c.SERVER_createJobRecord');

        createJobPost.setParams({
            'jobRecord': jobRec
        });

        createJobPost.setCallback(this, function(response){

            var state = response.getState();

            if (state === "SUCCESS" && response.getReturnValue() == "success") {
                document.getElementById("spinner").className = "slds-hide";
                document.getElementById("message").className = "slds-show";
            }
            else {
                alert('Error in getting data');
            }
        });
        $A.enqueueAction(createJobPost);
    },
    confirmationButton : function(component, event, helper) {
        location.reload();
    },
    viewApplicants : function(component, event, helper) {

        console.log(event.currentTarget.getAttribute("data-jobRecId"));
        var modalBody;
        $A.createComponent("c:PORTAL_JobApplicants", {
            "jobRecId": event.currentTarget.getAttribute("data-jobRecId")
        }, function(content, status, message) {

            if (status === "SUCCESS") {
                modalBody = content;
                component.find('overlayLib').showCustomModal({
                    header: "Applicants",
                    body: modalBody, 
                    showCloseButton: true,
                    cssClass: "mymodal",
                    closeCallback: function() {
                        // alert('You closed the alert!');
                    }
                })
            }                               
        });
    },
    viewJobRec : function(component, event, helper) {
        console.log(event.currentTarget.getAttribute("data-jobRecId"));
        var modalBody;
        $A.createComponent("c:PORTAL_ViewJobRec", {
            "jobRecId": event.currentTarget.getAttribute("data-jobRecId")
        }, function(content, status, message) {

            if (status === "SUCCESS") {
                modalBody = content;
                component.find('overlayLib').showCustomModal({
                    header: "Job Detail",
                    body: modalBody, 
                    showCloseButton: true,
                    cssClass: "mymodal",
                    closeCallback: function() {
                        // alert('You closed the alert!');
                    }
                })
            }                               
        });
    },
    editJobRec : function(component, event, helper) {
        console.log(event.currentTarget.getAttribute("data-jobRecId"));
        var modalBody;
        $A.createComponent("c:PORTAL_EditJobRec", {
            "jobRecId": event.currentTarget.getAttribute("data-jobRecId")
        }, function(content, status, message) {

            if (status === "SUCCESS") {
                modalBody = content;
                component.find('overlayLib').showCustomModal({
                    header: "Edit Job Detail",
                    body: modalBody, 
                    showCloseButton: true,
                    cssClass: "mymodal",
                    closeCallback: function() {
                        // alert('You closed the alert!');
                    }
                })
            }                               
        });
    },
    cancelDeleteJob : function(component, event, helper) {
        document.getElementById("spinner").className = "slds-hide";
        document.getElementById("deleteJobConfirmaton").className = "slds-hide";
    },
    confirmDeleteJob : function(component, event, helper) {
        var deleteJobRec = component.get('c.SERVER_deleteJobRecord');

        deleteJobRec.setParams({
            "jobRecId": component.get("v.temJobRecIdToDelete")
        });

        deleteJobRec.setCallback(this, function(response){

            var state = response.getState();

            if (state === "SUCCESS") {
                location.reload();
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(deleteJobRec);
    },
    deleteJobRec : function(component, event, helper) {

        component.set("v.temJobRecIdToDelete", event.currentTarget.getAttribute("data-jobRecId"));

        document.getElementById("spinner").className = "slds-show";
        document.getElementById("deleteJobConfirmaton").className = "slds-show";
    },
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var postedJobList = cmp.get("v.postedJobList");

        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(postedJobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var postedJobListToDisplay = postedJobList.slice(start, end);

        cmp.set("v.postedJobListToDisplay", postedJobListToDisplay);

        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var postedJobList = cmp.get("v.postedJobList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(postedJobList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > postedJobList.length) {
            end = postedJobList.length;
        }

        var postedJobListToDisplay = postedJobList.slice(start, end);

        cmp.set("v.postedJobListToDisplay", postedJobListToDisplay);

        cmp.set("v.currentPage", currentPage + 1);
    },
})