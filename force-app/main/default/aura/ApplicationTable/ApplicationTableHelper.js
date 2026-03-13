({
    getDataHelper: function (component, event) {

        var actions = [];
        actions.push({label: 'View Application', name: 'view_application'});

        if (component.get("v.isEditable") === true) {
            actions.push({label: 'Edit Application', name: 'edit_application'});
            actions.push({label: 'Delete', name: 'delete'});
        }

        var action = component.get("c.getRecords");
        //Set the Object parameters and Field Set name
        action.setParams({
            strObjectName: component.get("v.targetObject"),
            strFieldSetName: component.get("v.fieldSet"),
            clause: component.get('v.clause')
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var cols = response.getReturnValue().lstDataTableColumns;
                cols.push({type: 'action', typeAttributes: {rowActions: actions}})
                component.set("v.columns", cols);
                component.set("v.data", response.getReturnValue().lstDataTableData);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log('Something went wrong, Please check with your admin');
            }
        });
        $A.enqueueAction(action);
    },

    navigateToUrl : function(address)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect" :false
        });
        urlEvent.fire();
    },

    removeApplication: function (component, row) {
        var rows = component.get("v.data");
        var rowIndex = rows.indexOf(row);

        //Remove it from the DB
        var action = component.get("c.RemoveAcp");
        action.setParams({
            "acpId": row.Id
        });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                rows.splice(rowIndex, 1);
                component.set("v.data", rows);
            }
        });

        $A.enqueueAction(action);
    },

    determinePath : function(status)
    {
        switch (status) {
            case 'Course Preferences':
                return '/course-selection';
            case 'Declaration':
                return '/signup-declaration';
            case 'Personal Details':
                return '/personal-details';
            case 'Credentials':
                return '/qualifications-work-experience';
            case 'Scholarship':
                return '/external-scholarship';
            case 'Documents':
                return '/document-upload';
            case 'Application Fee':
                return '/payment';
            case 'Submit':
                return '/submission-declaration';
            case 'Review':
                return '/review';
            default:
                return '/signup-declaration';
        }
    },

    viewEditApplication: function (component, row, target){

        //Get the Application record first
        var action = component.get("c.GetAppByAcp");

        action.setParams({
            acpId : row.Id
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS") {
                //URL REDIRECT FOR EDITS
                var app = response.getReturnValue();
                var values = JSON.parse(app);
                var path = '';
                if(target === ''){
                    path = this.determinePath(values.status);
                }else{
                    path = target;
                }

                var address = path + '?appId=' + values.appId;
                this.navigateToUrl(address);
            }
        });

        $A.enqueueAction(action);

    }
})