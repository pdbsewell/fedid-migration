/**
 * @author          Ajitabh
 * @description     Trigger on Contact Relationship Object
 * @history  
 *  4/11/2021 - Ken McGuire       -  added updateReciprocalRelationship method to syncronize relationship data with their reciprocal relationships.       
 *  05 April 2022 - Rajesh Punjabi - Changed the triggered framework.                
 */
trigger ContactRelationshipTrigger on Contact_Relationship__c (after insert, after update, before delete, after delete) {
    
    if (TriggerCommon.doNotRunTrigger('Contact_Relationship__c')) {
        return;
    }
    new Triggers()         
        //.. After Insert
        .bindExtended(Triggers.Evnt.afterinsert, new ContactRelationshipServices.CreateReciprocalRelation())
        
        //.. After Update
        .bindExtended(Triggers.Evnt.afterupdate, new ContactRelationshipServices.UpdateReciprocalRelation())
		.bindExtended(Triggers.Evnt.afterupdate, new ContactRelationshipServices.UpdateContactRelation())

        //.. Before Delete
        .bindExtended(Triggers.Evnt.beforedelete, new ContactRelationshipServices.DeleteReciprocalRelation())
        
        //.. after Delete
        .bindExtended(Triggers.Evnt.afterdelete, new ContactRelationshipServices.UpdateSpousePartnerRelation())
        
        .execute();
}