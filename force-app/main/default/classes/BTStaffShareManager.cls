/**
 * @author Ibrahim Rumi
 * @date 27-08-2020
 * @group Event Management
 * @description Helper class for BTStaffTriggerHandler (Blackthorn)
 * @revision 
 * Ver   Date         Author         Modification
 * 1.0   12-03-2022   RANAND         Updated validatestaff method to prevent Event and Event Group duplication
 **/
public class BTStaffShareManager {
     
    /*
     * Mthod gets called during staff insert and runs a chained batch class to share 
     * records with the new users
     * Param:
     * stafflist - accepts a list of staff records
     */
    public void processStaffInsert(List<conference360__Staff__c>staffList){
    	map<Id,set<id>>userIdByEventId = new map<Id,set<id>>();
        if(!staffList.isEmpty()){
            
            for(conference360__Staff__c staff: staffList){
            
                Set<Id> userids = userIdByEventId.get(staff.conference360__Event__c);
                if(userids == null){
                    userids = new Set<Id>();
                }
                userids.add(staff.conference360__User__c);
                userIdByEventId.put(staff.conference360__Event__c,userids);
            }
            
            Database.executeBatch(new BTShareCreateBatch(userIdByEventId));
        }
    }

    /*
     * method to validate if a user is already a part of the event or event group
     * param:
     * stafflist: list of staff records to be processed
     */
    public void validateStaff(list<conference360__Staff__c> staffList){
        Set<Id> eventIds = new Set<Id>();
        Set<Id> eventGroupIds = new Set<Id>();
        Set<String> existingStaffs = new Set<String>();
        for(conference360__Staff__c objStaff : staffList){
            if(objStaff.Event_Group__c != null){
                eventGroupIds.add(objStaff.Event_Group__c);
            }
            else{
                eventIds.add(objStaff.conference360__Event__c);
            }
        }
        if(!eventGroupIds.isEmpty() || !eventIds.isEmpty()){
            existingStaffs = new BTStaffServices().getExistingStaffRecordSet(eventIds, eventGroupIds);
        }
        if(!existingStaffs.isEmpty()){
            for(conference360__Staff__c rec : staffList){
                if(rec.Event_Group__c != null){
                    if(existingStaffs.contains(String.valueOf(rec.Event_Group__c)+ '_'+String.valueOf(rec.conference360__User__c))){
                        rec.addError('The user is already an existing staff in the event group');
                    }
                }
                else{
                    if(existingStaffs.contains(String.valueOf(rec.conference360__Event__c)+ '_'+String.valueOf(rec.conference360__User__c))){ //&& String.IsBlank(rec.Event_Group_Staff_Id__c)){
                        rec.addError('The user is already an existing staff in the event');
                    }
                }
            }
        }

    }
    /*
     * method to delete the sharing records assigned to a user per event basis
     * param: list of staff records
     */
    public void processStaffDelete(List<conference360__Staff__c>staffList){
        map<Id,set<id>>userIdByEventId = new map<Id,set<id>>();
        if(!staffList.isEmpty()){
            for(conference360__Staff__c staff: staffList){
                
                Set<Id> userids = userIdByEventId.get(staff.conference360__Event__c);
                if(userids == null){
                    userids = new Set<Id>();
                }
                userids.add(staff.conference360__User__c);
                userIdByEventId.put(staff.conference360__Event__c,userids);
            }
            
            if(!userIdByEventId.isEmpty()){
                
                Database.executeBatch(new BTSharePurgeBatch(userIdByEventId));
            
    		}
        }
    }
    
    /*
     * method to asynchronously assign permission set groups to new users assigned to events
     * Param:
     * useridset - accepts set of user ids to be processed
     */
    public Static void asyncPermissionSetGroupAssignment(Set<id>userIdSet){
         if(!userIdSet.isEmpty()){
             BTStaffServices.autoExpiringPermissionSetGroupAssignment(userIdSet);
        }
    }
}