/**
 * @revision
 * 		JUNE.27.2018  Nick Guia   - removed all reference to Subscription_List__c and Subscripton_Member__c (for deletion)
 * 	    AUGUST.9.2018 Angelo Rivera - Added trigger framework
 * 	    DECEMBER.11.2019 Angelo Rivera - Decommissioned unused methods from Montrack Classic App
 * 	    AUGUST.11.2021 Aref Samad - Update Attendee count for Group Registration(EPBBS-2129)
 * 	    SEP.13.2024 Inderpal Dhanoa - Sync TimeZone(MCT-490)
 */
trigger CampaignMemberTrigger on CampaignMember (before insert, after insert, after update, before update, before delete, after delete ) {

    if (TriggerCommon.doNotRunTrigger('CampaignMember')) { return; }

    new Triggers()
            .bind(Triggers.Evnt.beforeInsert, new CampaignMemberServices.populateEmailToField())
            .bindExtended(Triggers.Evnt.beforeInsert, new CampaignMemberServices.SetPureCloudTimeZone())
            .bind(Triggers.Evnt.beforeInsert, new CampaignMemberServices.populateInviteeFields())
            .bindExtended(Triggers.Evnt.beforeInsert, new CampaignMemberServices.UpdateNumberOfAttendees())
            .execute();


    if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            //CampaignMemberServices.handleBeforeInsert(Trigger.newMap);
        } else if(Trigger.isUpdate) {
            //CampaignMemberServices.handleBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            CampaignMemberServices.handleBeforeDelete(Trigger.newMap, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            //CampaignMemberServices.handleAfterInsert(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isUpdate) {
            CampaignMemberServices.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            CampaignMemberServices.handleAfterDelete(Trigger.newMap, Trigger.oldMap);
        }
    }


}