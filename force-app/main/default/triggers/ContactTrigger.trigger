/**
 * @author          PwC
 * @description     Trigger class specific to Contact sObject
 * @revision
 *              23/01/2020 - Nick Guia          - Added UpdatePrimaryEmail on afterUpdate
 *              05/04/2019 - K Liew             - Added new invocation of composeDecomposeBirthDeceasedDates() for project engage
 *              12/02/2019 - Nick Guia          - added ComputeLeadGrade on afterInsert and afterUpdate
 *              15/07/2018 - Stefan Scheit      - Removed logic to generate dummy person id on contact on field Person_Id_unique__c (SF-1517)
 *              10/07/2018 - Kristian Vegerano  - IT account disabled logic added
 *              ???        - Kristian Vegerano  - Added syncCitizenship() logic
 *              PwC                             - Updated maintainEmailAddressHistory method to include Personal_Email__c (DCXCRM-1669)
 *              25.FEB.2020 - J.Mapanao         - Commented out the logic for invoking ContactServices.cleanUpOrphanAccounts() on after delete
 *              22.JUL.2020 - J.Mapanao         - Removed UpdatePrimaryEmail in after update and added InvokeRollUpContactPointsAsync instead
 *              05.APR.2021 - Vinothraja        - Added logic to sync Partner user whenever an Associated Contact is updated
 *				22/06/2021  - Martin C		    - Added queuable update of Contact lastmodified field (for survivors of a merge)
 *              22/01/2022 - Inderpal D		   - Added method to sync PRM Members (ENGAGEIE-1259)
 *              10/02/2022 - Inderpal D		   - Added method to sync PRM Members (ENGAGEIE-1317)
 *              24/05/2022 - Vinothraja        - Changed sync Partner user logic to new Trigger Framework
 *              13/03/2023 - Peter Sewell       - Added RecreateAffiliationContactShares on after update
 *              28/04/2023 - Seeva Singh       -  Added updateAccountRecordType on Before insert/update
 *              12/01/2024 - Jitender Padda     - Updated functionalities to use BindExtended framework
 */
trigger ContactTrigger on Contact (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Contact')) {
        return;
    }
 
    new Triggers()
    /** INSERT */
    // Removed as we don't believe the user will exist prior to the contact
    //.bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.syncCitizenship())                // Updates the Citizenship field translated from Citizenship code fed from Callista

    //.bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.EnableCopyCaseInfoToContact())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.AddContactAccounts())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.MaintainEmailAddressHistory())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.CopyMultiselectToTextField())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.updateFields())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.managePhoneFields())
    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.RestrictDuplicateAgencyRolesPerAgency())

    .bindExtended(Triggers.Evnt.beforeInsert, new ContactServices.ComposeDecomposeBirthDeceasedDates())
    .bindExtended(Triggers.Evnt.afterInsert, new ContactServices.MapMonashIdToUser())               // Map authcate across to User record (for community users)
    .bindExtended(Triggers.Evnt.afterInsert, new ContactServices.Person360RollDown())
    .bindExtended(Triggers.Evnt.afterInsert, new ContactServices.InvokeRollUpContactPointsAsync())  // this should always happen after the roll-down
    .bindExtended(Triggers.Evnt.afterInsert, new ContactServices.UpdatePrimaryEmail())
	.bindExtended(Triggers.Evnt.afterInsert, new ContactServices.UpdateContactTeamMemberForPRM())
    .bindExtended(Triggers.Evnt.afterInsert, new ContactServices.ResetContactPointSource())

    /** UPDATE */
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.MaintainEmailAddressHistory())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.syncCitizenship())           
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.CopyMultiselectToTextField())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.updateFields())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.managePhoneFields())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.ComposeDecomposeBirthDeceasedDates())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.CheckEmailSource())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.CheckAddressSource())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.CheckPhoneSource())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.maintainAccountName())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.ItAccountDisabled())               // Set the related user as deactivated
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.MapMonashIdToUser())               // Map authcate across to User record (for community users)
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.Person360RollDown())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.InvokeRollUpContactPointsAsync())  // this should always happen after the roll-down
    .bind(Triggers.Evnt.afterUpdate, new ContactServices.RecognitionNameUpdate())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.SyncPartnerUser())                 // Sync Contact's details to Partner User
    .bindExtended(Triggers.Evnt.afterupdate, new ContactServices.UpdateSubmissionLocationCountry())
	.bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.UpdateContactTeamMemberForPRM())
	.bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.updateAccountRecordType())
    .bindExtended(Triggers.Evnt.beforeUpdate, new ContactServices.RestrictDuplicateAgencyRolesPerAgency())

    
    //.. ERDA .. Update relationship for deceased contacts.
    .bindExtended(Triggers.Evnt.afterupdate, new ContactServiceERDA.ManageRelationDeceasedContact())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.ResetContactPointSource())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.RecreateAffiliationContactShares())
    .bindExtended(Triggers.Evnt.afterUpdate, new ContactServices.ReAssignUserRole())

    /** DELETE */
    //.bind(Triggers.Evnt.afterDelete, new ContactServices.cleanUpOrphanAccounts())
    .bindExtended(Triggers.Evnt.afterDelete, new ContactServices.MapMonashIdToUser())               // Map authcate across to User record (for community users)
    .bindExtended(Triggers.Evnt.afterDelete, new ContactServices.ClearFieldsAfterMerge())           // Map authcate across to User record (for community users)

    /** UNDELETE */
    .bindExtended(Triggers.Evnt.afterUndelete, new ContactServices.MapMonashIdToUser())             // Map authcate across to User record (for community users)

    .execute();
}