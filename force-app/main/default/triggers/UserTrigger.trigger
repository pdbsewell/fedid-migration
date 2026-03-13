/**
 * @author			Carl Vescovi, PwC
 * @description		Services class to provide User sObject centric logical support
 * @revision		15/02/2019 - Stefan Scheit - Added trigger handler logic to assign detault permission sets to community users
 * 					02/04/2017 - Ant Custodio - Added trigger handler logic to map user details to contact (for community users)
 * 					initial    - Carl Vescovi - initial version
 *					08/05/2019 - Russell Cadapan = Added trigger handler for license management
 *               	30/10/2019 - KEvasco (GrowthOps) - Added auto permission set assignment for Einstein Discovery Writeback
 *                  28/07/2020 - Stefan Scheit - consolidated permission set assignment (new/update trigger)
 *                  05/04/2021 - Vinothraja - Added trigger handler logic to sync details between partner user & contact
 *                  29/09/2021 - SMendu - Added trigger handler logic to stop deactivation of a Primary Account Holder user
 *                  01/11/2021 - Peter Sewell - Added trigger handler logic to sync auditable user record inserts/updates to UserShadow object
 *                  07/12/2021 - PVictoriano - Added trigger for Clear User Properties and Permissions / License
 *                  03/07/2023 - Peter Sewell - Added trigger to clear MFA_Mobile_Verified_External__c if MobilePhone updated 

 */
trigger UserTrigger on User (before insert, after insert, after update, before update) {
    
    if (TriggerCommon.doNotRunTrigger('User')) { return; }
    
    new Triggers()
    /*** INSERT **/
    // assign default customer community permission sets
    .bindExtended(Triggers.Evnt.afterinsert, new UserServices.AssignPermissionSets())
    // license management on insert
    .bind(Triggers.Evnt.afterinsert, new UserLicenseServices.CheckUserRecordUpdates())
    // create a contact for the context user if the current/running user is a partner delegated admin trying to create a new partner user
    .bindExtended(Triggers.Evnt.beforeinsert, new UserServices.CreateAssociatedPartnerContact())
    // sync user details from contact
    .bindExtended(Triggers.Evnt.beforeinsert, new UserServices.SyncDetailsFromContact())
    // partner community access assignment for partner created users
    .bindExtended(Triggers.Evnt.afterinsert, new UserServices.AssignPartnerPermissionDelegatedUser())
    // Syncs username from user record to related contact
    .bindExtended(Triggers.Evnt.afterinsert, new UserServices.SyncUsernameToContact())
    // sync inserts to UserShadow object for auditing
    .bind(Triggers.Evnt.afterinsert, new UserServices.SyncUserToUserShadow()) 
    // Prevent deactivation of Primary Account Holder user 
    .bindExtended(Triggers.Evnt.beforeupdate, new UserServices.PreventPrimaryAccountHolderDeactivation())
    // Clear User Details
    .bindExtended(Triggers.Evnt.beforeupdate, new UserServices.ClearFedIdUserName())
    // Clears Verified Mobule flag on MobilePhone update
    .bindExtended(Triggers.Evnt.beforeupdate, new UserServices.ClearVerifiedMobileFlagOnMobileChange())
    // assign permission sets upon update
    .bindExtended(Triggers.Evnt.afterupdate, new UserServices.AssignPermissionSets())
    // license management on insert
    .bind(Triggers.Evnt.afterupdate, new UserLicenseServices.CheckUserRecordUpdates())
    // sync contact with the user's details
    .bind(Triggers.Evnt.afterupdate, new UserServices.SyncAssociatedPartnerContact())
    // sync updates to UserShadow object for auditing
    .bind(Triggers.Evnt.afterupdate, new UserServices.SyncUserToUserShadow()) 
    // Removes assigned Permission Sets for User
    .bindExtended(Triggers.Evnt.afterupdate, new UserServices.RemovePermissionsUser())
    // Syncs username from user record to related contact
    .bindExtended(Triggers.Evnt.afterupdate, new UserServices.SyncUsernameToContact())

    //
    .execute(); 
}