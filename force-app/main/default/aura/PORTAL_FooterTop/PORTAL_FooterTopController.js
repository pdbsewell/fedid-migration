({
	doInit : function(component, event, helper) {   
        var action = component.get('c.SERVER_getBaseUrl')
        action.setCallback(this, function (response) {
            var state = response.getState()
            
            console.log('state: ' + state);
            
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue()
            
            	console.log('baseUrl: ' + result);
                
                var linkedInIconUrl = result + "/icons/linkedin-white.png";
                var facebookIconUrl = result + "/icons/facebook-white.png";
                var twitterIconUrl = result + "/icons/twitter-white.png";
                var googlePlusIconUrl = result + "/icons/google-white.png";
                
            	component.set('v.baseUrl', result)
                component.set('v.linkedInIconUrl', linkedInIconUrl)
                component.set('v.facebookIconUrl', facebookIconUrl)
                component.set('v.twitterIconUrl', twitterIconUrl)
                component.set('v.googlePlusIconUrl', googlePlusIconUrl)
            }
        })
        $A.enqueueAction(action)
	}
})