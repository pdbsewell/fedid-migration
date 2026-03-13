({
    onTabRefreshed : function(cmp, event, helper) {
        // when tab refresh event is detected, forward it to the AuraEventBridge__c channel
        var refreshedTabId = event.getParam("tabId");
        var payload = {
          eventType: "refresh",
          target: refreshedTabId
        };
        cmp.find("eventChannel").publish(payload);
    },
    handleMessage : function(cmp, msg, helper) {
        console.log('lwcEventBridge: Message received');

        const method = msg.getParam('method');
        if(!method) {
            // no method specified, nothing to do
            return;
        }
        const params = JSON.parse(JSON.stringify(msg.getParam('params')));

        if(method == 'quickActionAPI') {
            const qaAPI = cmp.find(method);
            const qaMethod = params['method'];
            const qaParams = params['params'];
            qaAPI[qaMethod](qaParams);
            console.log('lwcEventBridge: Quick Action API Called');
        } else {
            console.log('lwcEventBridge: Unsupported Method: ' + method);
        }

    }
})