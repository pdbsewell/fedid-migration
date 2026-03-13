({
    initializePledgeRec : function(component, event, helper) {
        var pledgeRec = component.get("v.pledgeRec");

        if (pledgeRec == null) {
            let today = new Date();
            var pledgeRec = {
                'Id': null,
                'Name': '',
                'Amount': 0.00,
                'Type': 'Standard',
                'ucinn_ascendv2__Credit_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate(),
                'ucinn_ascendv2__Notes__c': '',
                'ucinn_ascendv2__Entry_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate()
            };

            component.set("v.pledgeRec", pledgeRec);
        }

        var portalDonationSetupParams = component.get("v.portalDonationSetupParams");
        if (portalDonationSetupParams == null) {
            portalDonationSetupParams = {};
        }

        if (portalDonationSetupParams.selectedPaymentDayOfMonth == undefined) {
            portalDonationSetupParams.selectedPaymentDayOfMonth = "0";
        }
        if (portalDonationSetupParams.selectedPaymentFrequency == undefined) {
            portalDonationSetupParams.selectedPaymentFrequency = "Monthly";
        }
        var availableMonthOptions = [];

        availableMonthOptions = availableMonthOptions.concat([{"Name":"0","Label":"Current Date"}, {"Name":"1","Label":"1st Day Of Month"}, {"Name":"15","Label":"15th Day Of Month"}]);

        var availableFrequencyOptions = ["Monthly", "Annual"];

        component.set("v.availableMonthOptions", availableMonthOptions);
        component.set("v.availableFrequencyOptions", availableFrequencyOptions);

        var availableMonthOptionsWrapper = [];
        for (var oneMonthOption of availableMonthOptions) {

            var oneOption = {class: "optionClass", label: oneMonthOption.Label, value: oneMonthOption.Name};
            if (portalDonationSetupParams != undefined && portalDonationSetupParams != null 
                && portalDonationSetupParams.selectedPaymentDayOfMonth != undefined && portalDonationSetupParams.selectedPaymentDayOfMonth != null
                && oneMonthOption.Name == portalDonationSetupParams.selectedPaymentDayOfMonth) {
                oneOption.selected = true;
            }

            availableMonthOptionsWrapper.push(oneOption);
        }

        component.find("availableMonthOptions").set("v.options", availableMonthOptionsWrapper);

        var availableFrequencyOptionsWrapper = [];
        for (var oneFrequencyOption of availableFrequencyOptions) {

            var oneOption = {class: "optionClass", label: oneFrequencyOption, value: oneFrequencyOption};
            if (portalDonationSetupParams != undefined && portalDonationSetupParams != null 
                && portalDonationSetupParams.selectedPaymentFrequency != undefined && portalDonationSetupParams.selectedPaymentFrequency != null
                && oneFrequencyOption == portalDonationSetupParams.selectedPaymentFrequency) {
                oneOption.selected = true;
            }

            availableFrequencyOptionsWrapper.push(oneOption);
        }

        component.find("availableFrequencyOptions").set("v.options", availableFrequencyOptionsWrapper);

        component.set("v.portalDonationSetupParams", portalDonationSetupParams);
    },

    initializeGiftRec : function(component, event, helper) {
        var giftRec = component.get("v.giftRec");

        if (giftRec == null) {
            let today = new Date();
            var giftRec = {
                'Id': null,
                'Name': '',
                'Amount': 0.00,
                'Type': 'Outright',
                'ucinn_ascendv2__Credit_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate(),
                'ucinn_ascendv2__Notes__c': '',
                'ucinn_ascendv2__Entry_Date__c': today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate()
            };
            component.set("v.giftRec", giftRec);
        }
    }
})