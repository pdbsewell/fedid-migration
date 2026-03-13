/**
 * @description       : Trigger for Account object
 * @author            : Kristian Vegerano
 * @group             : Trigger
 * @last modified on  : 2022-07-06
 * @last modified by  : Stefan Scheit
 * Modifications Log 
 * Date         Author          Modification
 * 2022-07-06 - Stefan Scheit - Added HandleDunBradstreetElements to blank out DnB Company lookup field
 * 2021-11-08 - Inderpal Dhanoa -- Added syncHierarchyLevel to show the Hierarchy of the related School/Faculty
 * 2021-09-08 - Inderpal Dhanoa - Added SyncDUNSNumbrToOppty to sync the account's DUNS numbr to Opportunities
 * 2021-02-12 - Kristian Vegerano - Added CorrectPartnerOwner to correct the account's owner when created from communities
 * 2021-02-02 - Steffi Narang - Added createAccountTeamMemberforPRM after update PRM field on Account
 * 2020-09-21 - Stefan Scheit - Updated PopulateFields handler
 * 2019-05-17 - Kristian Vegerano - Added UpdateSubmissionLocationCountry handler
 **/
trigger AccountTrigger on Account (before insert, after insert, before update, after update, after delete, after undelete) {

    if (TriggerCommon.doNotRunTrigger('Account')) {
        return;
    }

    //Initialize Triggers
    new Triggers('Account')
    /** INSERT */
    .bindExtended(Triggers.Evnt.beforeinsert, new AccountHandler.HandleExternalOrganisation())
    .bindExtended(Triggers.Evnt.beforeinsert, new AccountHandler.HandleDunBradstreetElements())
    .bindExtended(Triggers.Evnt.beforeinsert, new AccountHandler.CorrectPartnerOwner())
    .bindExtended(Triggers.Evnt.afterinsert, new AccountHandler.SyncHierarchyLevel())
    .bindExtended(Triggers.Evnt.afterinsert, new AccountHandler.UpdateAccountTeamMemberForPRM()) //create Account Team members (of role PRM) when Account records are created with PRM field set
    .bindExtended(Triggers.Evnt.afterinsert, new AccountHandler.CreatePartnerAgreement())
    .bindExtended(Triggers.Evnt.afterinsert, new AccountHandler.SyncDUNSNumbrToOppty())
    /** UPDATE */
    .bindExtended(Triggers.Evnt.beforeupdate, new AccountHandler.HandleExternalOrganisation())
    .bindExtended(Triggers.Evnt.beforeupdate, new AccountHandler.HandleDunBradstreetElements())
    .bindExtended(Triggers.Evnt.beforeupdate, new AccountHandler.UpdatePhoneWithDialingCode())
    .bindExtended(Triggers.Evnt.afterupdate, new AccountHandler.SyncHierarchyLevel())    
    .bindExtended(Triggers.Evnt.afterupdate, new AccountHandler.UpdateSubmissionLocationCountry())
    .bindExtended(Triggers.Evnt.afterupdate, new AccountHandler.SyncDUNSNumbrToOppty())
    .bindExtended(Triggers.Evnt.afterupdate, new AccountHandler.UpdateAccountTeamMemberForPRM()) //update Account Team members (of role PRM) when Account records are updated for the PRM field
    .bindExtended(Triggers.Evnt.afterupdate, new AccountHandler.PopulateAccountRecordTypeNameOnContact()) //Update Account Record type name on Contact for household record type
    //Calls the run method on each class
    .execute();
}