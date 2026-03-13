/**
 * Created by trentdelaney on 4/9/18.
 */
({
    hasDrafts : function(component){
        var action = component.get("c.HasDrafts");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var result = response.getReturnValue();
                if(result === true){
                    component.set("v.editApplication", true);
                    component.set("v.cancelApplication", true);
                }else{
                    component.set("v.newApplication", true)
                }
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

    navigateToUrl : function(address)
    {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": address,
            "isredirect" :false
        });
        urlEvent.fire();
    },

    createApplication : function(component, page)
    {
        var action = component.get("c.CreateApplication");

        component.set("v.buttonSelected", true);

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var appId = response.getReturnValue();
                var address = page + '?appId=' + appId;
                this.navigateToUrl(address);

            }else{
                component.set("v.buttonSelected", false);
            }
        });

        $A.enqueueAction(action);
    },

    editMyApplication : function(component){
        var action = component.get("c.EditApplication");
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log(state);
            if(state === 'SUCCESS'){
                //Reroute the user to the application here
                var app = response.getReturnValue();
                console.log(app);
                var values = JSON.parse(app);
                var path = this.determinePath(values.status);

                console.log('path=='+path);
                var address = path + '?appId=' + values.appId;
                console.log(address);
                this.navigateToUrl(address);
            }
        });

        $A.enqueueAction(action);
    },

    deleteApplication : function(component){
        var action = component.get("c.RemoveApplication");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                //Render some information to the user here in the form of a Modal
                //This is lazy for now and needs to be changed.
                this.navigateToUrl('/');
            }
        });

        $A.enqueueAction(action);

    }
})