/**
 * Created by trentdelaney on 14/8/18.
 */
({
    doInit : function(component, event, helper) {        
        helper.parseApplicationId(component);


        var arrStates = [];
        arrStates.push({"label":"Declaration",
            "value":"Declaration",
            "url":'/signup-declaration',
            "valid":true});
        arrStates.push({"label":"Personal Details",
            "value":"Personal Details",
            "url":"/personal-details",
            "valid":true});
        arrStates.push({"label":"Study Preferences",
            "value":"Study Preferences",
            "url":"/course-selection",
            "valid":true});
        arrStates.push({"label":"Educational History",
            "value":"Credentials",
            "url":"/qualifications-work-experience",
            "valid":true});
        arrStates.push({"label":"Sponsorship / Proxy",
            "value":"Scholarship",
            "url":"/external-scholarship",
            "valid":true});
        arrStates.push({"label":"Documents",
            "value":"Documents",
            "url":"/document-upload",
            "valid":true});
        arrStates.push({"label":"Review",
            "value":"Review",
            "url":"/review",
            "valid":true});
        arrStates.push({"label":"Processing Fee",
            "value":"Application Fee",
            "url":"/payment",
            "valid":true});
        arrStates.push({"label":"Submit",
            "value":"Submit",
            "url":"/submission-declaration",
            "valid":true});
        component.set("v.submissionProgressOptions", arrStates);


        helper.initLoad(component);
        //helper.getCurrentStatus(component);
    }

    , onClickDivStep:function (component, event, helper) {
        var src = event.currentTarget;
        var stepId = src.getAttribute("data-id");
        var stepUrl = src.getAttribute("data-url");

        if(stepUrl) {
            helper.navToPage(component, stepId, stepUrl);
        }
        else {
            console.error('no url for ' + stepId);
        }

    }

    , onClickStep: function (component, event, helper) {
        var src = event.getSource();
        var stepId = src.getLocalId();

        var stepValue;
        var url;
        helper.navToPage(component, stepValue, url);
        switch(stepId)
        {
            case 'step-01':
                stepValue = 'Declaration';
                url = '/signup-declaration';
                break;
            case 'step-02':
                stepValue = 'Personal Details';
                url = '/personal-details';
                break;
            case 'step-03':
                stepValue = 'Study Preferences';
                url = '/course-selection';
                break;
            case 'step-04':
                stepValue = 'Credentials';
                url = '/qualifications-work-experience';
                break;
            case 'step-05':
                stepValue = 'Scholarship';
                url = '/external-scholarship';
                break;
            case 'step-06':
                stepValue = 'Documents';
                url = '/document-upload';
                break;
            case 'step-07':
                stepValue = 'Review';
                url = '/review';
                break;
            case 'step-08':
                stepValue = 'Application Fee';
                url = '/payment';
                break;
            case 'step-09':
                stepValue = 'Submit';
                url = '/submission-declaration';
                break;
            default:
                console.error('ApplicationPathController:: unrecognized step:' + stepId);
                break;
        }
    }

	, doNothing: function (component, event, helper) {
        event.preventDefault();
        //console.log('doNothing');
	}

    , onClickCloseAlert: function (component, event, helper) {
        component.set('v.navError', false);
    }
})