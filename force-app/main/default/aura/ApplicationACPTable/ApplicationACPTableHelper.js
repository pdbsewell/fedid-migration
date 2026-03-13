/**
 * Created by trentdelaney on 4/9/18.
 */
({
    getApplicationsWithAcps : function (component, editable) {
        var action = component.get("c.GetApplicationsWithACP");

        action.setParams({
            "editable": editable
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            console.log(state);
            if(state === 'SUCCESS'){
                var values = JSON.parse(response.getReturnValue());
                var apps = [];
                console.log(values);
                for(var key in values){
                    apps.push({value : values[key], key:key})
                    if(editable === true){
                        component.set("v.draftApplication", key);
                    }
                }

                component.set("v.applications", apps);
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

    editMyApplication : function(component){
        var action = component.get("c.EditApplication");
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log(state);
            if(state === 'SUCCESS'){
                //Reroute the user to the application here
                var app = response.getReturnValue();
                var values = JSON.parse(app);
                var path = this.determinePath(values.status);

                var address = path + '?appId=' + values.appId;
                this.navigateToUrl(address);
            }
        });

        $A.enqueueAction(action);
    },

    viewMyApplication : function (component, path, appId, elementId) {
        var url = path + '?appId=' + appId + '#' + elementId;
        this.navigateToUrl(url);
    },

    toggleHelper : function(component,event) {
        var toggleText = component.find("tooltip");
        $A.util.toggleClass(toggleText, "toggle");
    }
})