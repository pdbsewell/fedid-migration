/**
* @author various, this comments block is created retrospectively
* @date 15.05.2020
*
* @group Application
*
* @description Trigger Handler on Accounts that handles ensuring the correct system flags are set on <br/>
* our special accounts (Household, One-to-One), and also detects changes on Household Account that requires <br/>
* name updating. <br/>
*
* @revision
*           26.05.2017 - Ryan Wilson: Initial Create
*           15.05.2020 - KL - SFTLG-903 - 'no match' scenario submission of App
*           30.03.2023 - SM- SFTG-3176 - Add/modify affiliation for applicant contact sharing with Partners
*           01.05.2023 - Martin Cadman  - Renamed from ApplicationAndDocumentSubmission to ApplicationTrigger
*                            - Updated/introduced populateSubmissionProgress, populateAgent and populateOwner            
*           25.02.2024 - Martin Cadman  - Updated signature to allow delete operations to occur for DLRS
*           14.10.2024 - Vishal Gupta  - GR application web service callout to Callista MGROI-481
*/
trigger ApplicationTrigger on Application__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    // moved to the start ensure all actions are disabled
    if (TriggerCommon.doNotRunTrigger('Application__c')) {
        return;
    } 
    
    // TODO : MIGRATE TO BINDEXTENDED - START
    if (Trigger.isInsert && Trigger.isBefore) {
        //ANT.CUSTODIO, 16.June.2017 - prevents the user from creating drafts if they already have an existing draft application
        ApplicationHandler.onlyAllowOneDraft(Trigger.new);
    }
    
    //ANT.CUSTODIO, 07.Sept.2017 - automatically populate the Agent using the provided agent org unit code
    if (Trigger.isUpdate && Trigger.isBefore) {
        ApplicationHandler.submittedApplicationsCalculateChecklistOutput(Trigger.newMap, Trigger.oldMap);
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        //Shalini Mendu - Validate data from external applications - AP/IDP
        ApplicationHandler.validateData(Trigger.new, Trigger.oldMap);
        //Shalini Mendu - Redeem fee waiver for my.app Source system
        ApplicationHandler.redeemFeeWaiverCode(Trigger.new, Trigger.oldMap);
        //Shalini Mendu - Submit Documents for my.app and other source systems
        ApplicationHandler.submitDocuments(Trigger.new, Trigger.oldMap);
        //Shalini Mendu - SFTN-455-Admission Test Result: Language of Instruction/ Country of schooling pass to Callista      
        ApplicationHandler.sendLOI(Trigger.new, Trigger.oldMap);
        //MGROI-481 GR application web service callout to Callista to send the GR application data
        ApplicationHandler.submitGRApplication(Trigger.new, Trigger.oldMap);
    }
    // TODO : MIGRATE TO BINDEXTENDED - END
    
    //Initialize Triggers
    new Triggers()

        /** BEFORE INSERT */
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationHandler.populateSubmissionProgress())
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationHandler.populateAgent())
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationHandler.processCampusLocation())
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationHandler.populateOwner())
        .bindExtended(Triggers.Evnt.beforeinsert, new ApplicationHandler.AddModifyAffiliationRecords())
        /** AFTER INSERT */
        .bindExtended(Triggers.Evnt.afterinsert, new ApplicationHandler.UpdateSubmissionLocationCountry())
        .bindExtended(Triggers.Evnt.afterinsert, new ApplicationHandler.PerformDupCheck())
		.bindExtended(Triggers.Evnt.afterInsert, new DlrsDelegateTriggerHandler(Application__c.SObjectType))
        /** BEFORE UPDATE */
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationHandler.populateSubmissionProgress())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationHandler.populateAgent())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationHandler.processCampusLocation())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationHandler.populateOwner())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationTriggerHandler.TrackAgentAndApplicantRevision())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationTriggerHandler.PopulateMyAppUserStatus())
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationTriggerHandler.DelegateApplicationBeforeSubmit())
        //Update Application Status on Contact Qualification
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationTriggerHandler.UpdateApplicationStatusOnContactQual())
        //Update Application Status on Work Experience
        .bindExtended(Triggers.Evnt.beforeupdate, new ApplicationTriggerHandler.UpdateApplicationStatusOnWorkExp())
        /** AFTER UPDATE */
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationHandler.UpdateSubmissionLocationCountry())
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationHandler.PerformDupCheck())
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationHandler.AddModifyAffiliationRecords())
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationTriggerHandler.EnableMyAppAccess())
		.bindExtended(Triggers.Evnt.afterUpdate, new DlrsDelegateTriggerHandler(Application__c.SObjectType))
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationHandler.UpsertAffiliationsonAgentTransfer())
        .bindExtended(Triggers.Evnt.afterupdate, new ApplicationTriggerHandler.RunACPQueueRouting())
        /** BEFORE DELETE */
        .bindExtended(Triggers.Evnt.beforedelete, new ApplicationHandler.ValidateDelete())
        /** AFTER DELETE */
        .bindExtended(Triggers.Evnt.afterDelete, new DlrsDelegateTriggerHandler(Application__c.SObjectType))
		/** AFTER UNDELETE */
        .bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Application__c.SObjectType))
        //Calls the run method on each class
        .execute();
}