({
    doInit : function(component, event, helper) {

        var queryAppliedJobs = component.get('c.SERVER_queryAppliedJobs');

        queryAppliedJobs.setCallback(this, function(response){

            var state = response.getState();
            var result = response.getReturnValue();

            console.log( (JSON.parse(JSON.stringify(result))) );

            if (state === "SUCCESS") {
                component.set('v.applicationList', result);
                
                var itemsPerPage = component.get("v.itemsPerPage");
                var applicationListToDisplay = result;

                if (itemsPerPage < result.length) {
                    applicationListToDisplay = result.slice(0, itemsPerPage);
                }

                component.set("v.totalNumberOfPages", Math.ceil(result.length / itemsPerPage));

                console.log(applicationListToDisplay);
                component.set("v.applicationListToDisplay", applicationListToDisplay);
            }
            else {
                alert('Error in getting data');
            }
        });

        $A.enqueueAction(queryAppliedJobs);  
    },
    handleShowModal : function(component, event, helper) {
        console.log('bilibibil');
        console.log(event.currentTarget.getAttribute("data-sfdcID"));
        var modalBody;
        $A.createComponent("c:PORTAL_JobDetailView", {
            recordId: event.currentTarget.getAttribute("data-sfdcID")
        }, function(content, status) {
               if (status === "SUCCESS") {
                   modalBody = content;
                   component.find('overlayLib').showCustomModal({
                       header: "Job Detail",
                       body: modalBody, 
                       showCloseButton: true,
                       cssClass: "mymodal",
                       closeCallback: function() {
                           //alert('You closed the alert!');
                       }
                   })
               }                               
           }
        );
    },
    
    previousPage : function (cmp, event, helper) {
        console.log("in previous page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var applicationList = cmp.get("v.applicationList");

        if (currentPage - 1 == 1) {
            cmp.set("v.previousButtonDisabled", true);
        }

        if (currentPage + 1 >= Math.ceil(applicationList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", false);
        }

        var start = (currentPage - 2) * itemsPerPage;
        var end = (currentPage - 1) * itemsPerPage;
        console.log("start is " + start);
        console.log("end is " + end);
        if (start < 0) {
            start = 0;
        }

        var applicationListToDisplay = applicationList.slice(start, end);

        cmp.set("v.applicationListToDisplay", applicationListToDisplay);

        cmp.set("v.currentPage", currentPage - 1);
    },
    nextPage : function(cmp, event, helper) {
        console.log("in next page");

        var currentPage = cmp.get("v.currentPage");
        var itemsPerPage = cmp.get("v.itemsPerPage");
        var applicationList = cmp.get("v.applicationList");
        // if this is the first page
        if (currentPage == 1) {
            cmp.set("v.previousButtonDisabled", false);
        }

        // Handle buttons disabled
        if (currentPage + 1 >= Math.ceil(applicationList.length / itemsPerPage)) {
            cmp.set("v.nextButtonDisabled", true);
        }

        var start = currentPage * itemsPerPage;
        var end = (currentPage + 1) * itemsPerPage;

        console.log("start is " + start);
        console.log("end is " + end);

        if (end > applicationList.length) {
            end = applicationList.length;
        }

        var applicationListToDisplay = applicationList.slice(start, end);

        cmp.set("v.applicationListToDisplay", applicationListToDisplay);

        cmp.set("v.currentPage", currentPage + 1);
    },
})