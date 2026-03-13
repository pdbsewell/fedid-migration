({
    addTribute : function(component, event, helper) {
        var tributeRecList = component.get("v.tributeRecList");

        if (tributeRecList == null) {
            tributeRecList = [];
        }

        tributeRecList.push({
            'Id': null,
            'ucinn_ascendv2__Tribute_Type__c': '',
            'ucinn_ascendv2__Contact__c': '',
            'ucinn_ascendv2__Contact_Text__c': '',
            'ucinn_ascendv2__Tributee__c': '',
            'ucinn_ascendv2__Notify_Contact__c': '',
            'ucinn_ascendv2__Notify_Contact_Text__c': '',
            'ucinn_ascendv2__Notify_Address__c': '',
            'ucinn_ascendv2__Occasion__c': ''
        });
        component.set("v.tributeRecList", tributeRecList);
    },
    tributeListItemEventHandler : function(component, event, helper) {
        let operation = event.getParam("operation");
        let source = event.getParam("source");
        let target = event.getParam("target");
        let index = event.getParam("index");
        let incomingData = event.getParam("data");

        if (target == "tributeList") {
            if (source == "tributeListItem") {
                if (operation == "remove") {
                    var tributeRecList = component.get("v.tributeRecList");
                    if (index > -1) {
                        tributeRecList.splice(index, 1);
                        component.set("v.tributeRecList", tributeRecList);
                    }
                }
                else if (operation == "append") {
                    // no action now
                }
                else if (operation == "modify") {
                    // no action now
                }
            }
        }

        // For now, no more propagation is expected, stop it now.
        event.stopPropagation();
    }
})