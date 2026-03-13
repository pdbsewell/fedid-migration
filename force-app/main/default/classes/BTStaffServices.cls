/**
 * @description  : Service class for BTStaffTriggerHandler (Blackthorn)
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 07-03-2023
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   Updates to shareObjectInfo object and getshareinfo method to include additional criteria
 * 1.1   13-10-2021   Ibrahim Rumi   Update to getShareInfo method to provide edit access to attendee
 * 1.2   12-03-2022   RANAND         Added manageEventStaffForGroup method to incorporate Event Staff creation if Event Group is populated
 * 1.3   03-10-2022   Ibrahim Rumi   Update getExistingPermSetGroupbyUser to include expired records 
 * 1.3   07-03-2023   Ibrahim Rumi   Update getEventChildRecordsMap to get only the active Users
 **/
public class BTStaffServices {
    
    //shareObjMap determines the objects that has to be shared as part of the event share module
    public Static Map<Schema.SObjectType,Schema.SObjectType> shareObjMap = new Map<Schema.sObjectType,Schema.SObjectType> {
        conference360__Attendee__c.sObjectType => conference360__Attendee__share.sObjectType,
        conference360__Event__c.sObjectType => conference360__Event__share.sObjectType
    };
      
    //Fetching the default blackthorn event stetings(custom settings)
    public static conference360__Blackthorn_Events_Settings__c defaultSettings {
        get {
            if(defaultSettings == null) {
                defaultSettings = getdefaultBlackthornSettings();
            }
            return defaultSettings;
        } set;
    }
    
    /*
     * returns event, attendee and staff records related to an event
     * param:
     * eventIdSet - set of event ids
     */
    public map <Id,conference360__Event__c> getEventChildRecordsMap(set<Id>eventIdSet){
        return new map<Id,conference360__Event__c>([SELECT id,(SELECT id,conference360__Event__c from conference360__Attendees__r),
                (SELECT id,conference360__Event__c,conference360__User__c  from conference360__Staff__r WHERE conference360__User__r.IsActive = true) 
                FROM conference360__Event__c 
                WHERE id IN: eventIdSet]);
    }
    
    /*
     * fetches the existing permission set group fields for a user
     * param:
     * permissionSetGroupId - permission set group to fetch the values from
     * userIdSet - set of userids
     */
    public Static Map<Id,PermissionSetAssignment> getExistingPermSetGroupbyUser(id permissionSetGroupId, set<id>userIdSet){
        Map<Id,PermissionSetAssignment>existingPermSetGroupbyUserMap = new Map<Id,PermissionSetAssignment>();
            if(permissionSetGroupId!=null && !userIdSet.isEmpty()){
                for(PermissionSetAssignment psa:[SELECT AssigneeId,PermissionSetGroupId,ExpirationDate 
                                     			 FROM PermissionSetAssignment 
                                     			 WHERE AssigneeId IN: userIdSet AND PermissionSetGroupId =: permissionSetGroupId ALL ROWS]){
                    existingPermSetGroupbyUserMap.put(psa.AssigneeId,psa);
                }
            }
        
        return existingPermSetGroupbyUserMap;
    }
    
    /*
     * asynchronous method that sets Blackthorn_Check_In permission set group to users
     * param:
     * userIdSet - set of userids
     */
    @future
    public static void autoExpiringPermissionSetGroupAssignment(set<id>userIdSet){
        List<PermissionSetAssignment> psgAssignment = new List<PermissionSetAssignment>();
        if(userIdSet!=null && !userIdSet.isEmpty()){
            
            //fetch PermissionSetGroup id of Blackthorn_Check_In PermissionSetGroup
            Id permissionSetGroupId = [SELECT id FROM PermissionSetGroup Where DeveloperName = 'Blackthorn_Check_In'][0]?.Id;
            if(permissionSetGroupId!=null){    
                
                //fetches the PermissionSetGroup details if Blackthorn_Check_In is already assigned
                Map<Id,PermissionSetAssignment> existingPermSetGroupbyUserMap = getExistingPermSetGroupbyUser(permissionSetGroupId,userIdSet);
                
                //fetches the maximum end date based on the latest event end date/time
                Map<Id,Datetime>maxEventEndDateTimeWithUserid = setMaxEndDateTimeWithUserMap(userIdSet);
                
                for(id userid: userIdSet){
                    DateTime expirationDateTime;
                    DateTime currentexpirationDateTime;
                    
                    //gets expirationdate for user from latest event end date/time
                    if(maxEventEndDateTimeWithUserid.containskey(userid)){
                        expirationDateTime = maxEventEndDateTimeWithUserid.get(userid);
                    }
                    //checks if user already has Blackthorn_Check_In PSG assigned
                    if(existingPermSetGroupbyUserMap.containskey(userid)){
                        PermissionSetAssignment psa = existingPermSetGroupbyUserMap.get(userid);
                        
                        //checks if event's latest expirationdate is greater than user's existing psg's expiry date
                        if(psa.ExpirationDate != null && expirationDateTime > psa.ExpirationDate){
                            psa.ExpirationDate = expirationDateTime;
                            psgAssignment.add(psa);
                        }
                    //creates a new psg assignment if user already has none
                    }else{
                        PermissionSetAssignment psg = new PermissionSetAssignment();
                        psg.AssigneeId = userid;
                        psg.ExpirationDate = expirationDateTime;
                        psg.PermissionSetGroupId = permissionSetGroupId;
                        psgAssignment.add(psg);
                    }
                    
                }
            }
            // upsert the psg assignment 
                Try{
                    Database.upsert(psgAssignment,false);
                    
                }catch(Exception ex){
                    LogUtilityException.logException(ex,'BTStaffServices.autoExpiringPermissionSetGroupAssignment');
                }        
        }
    }
    
    /*
     * gets the latest expiration date based on event end date/time for a user
     * param:
     * userIdset - set of user ids
     */
    public Static Map<Id,Datetime> setMaxEndDateTimeWithUserMap(set<id>userIdSet){
        Map<Id,Datetime>maxEventEndDateTimeWithUserid = new Map<Id,Datetime>();
        
        //fetches additional time from the default blackthorn event settings
        Integer timeAddition = (Integer)defaultSettings.Time_Addition_Permission_Set_Expiry__c;
        if(userIdSet!=null && !userIdSet.isEmpty()){
            
            //fetch all event associated to a staff
            for(conference360__Staff__c staff:[SELECT conference360__Event__c,conference360__Event__r.conference360__Event_End_Time__c,
                                                      conference360__Event__r.conference360__Event_End_Date__c,conference360__User__c 
                                               FROM conference360__Staff__c
                                               WHERE conference360__User__c IN: userIdSet])
            {
                if(staff.conference360__Event__r.conference360__Event_End_Date__c!=null &&
                   staff.conference360__Event__r.conference360__Event_End_Time__c!=null){
                       
                       // set a new datetime instance combining event end date/time and an additional time
                       DateTime eventEndDateTime = DateTime.newInstance(staff.conference360__Event__r.conference360__Event_End_Date__c,staff.conference360__Event__r.conference360__Event_End_Time__c)
                                                   .addHours(timeAddition);
                       DateTime maxEventEndDateTime = eventEndDateTime;
                       if(maxEventEndDateTimeWithUserid.containskey(staff.conference360__User__c)){
                           DateTime dt = maxEventEndDateTimeWithUserid.get(staff.conference360__User__c);
                           maxEventEndDateTime = eventEndDateTime > dt ? eventEndDateTime : dt;
                       }
                       // sets latest event datetime as expiry date
                       if(maxEventEndDateTime!=null){
                           maxEventEndDateTimeWithUserid.put(staff.conference360__User__c,maxEventEndDateTime);
                       }
                }
                
            }
        }
        return maxEventEndDateTimeWithUserid;
    }
    
    /*
    * @description retrieve blackthorn default settings
    */
    private static conference360__Blackthorn_Events_Settings__c getdefaultBlackthornSettings(){
        conference360__Blackthorn_Events_Settings__c defaultSettings = conference360__Blackthorn_Events_Settings__c.getOrgDefaults();
        
        if(defaultSettings.Time_Addition_Permission_Set_Expiry__c  == null){
            defaultSettings.Time_Addition_Permission_Set_Expiry__c = 4;
        }
        
        return defaultSettings;
    }
    
    /*
     * checks if the user is already an existing staff in the event
     * param: 
     * userid - accepts user id to compare
     * stafflist - accepts a stafflist to compare the userid with
     */
    public Boolean isExistingStaff(id userid,List<conference360__Staff__c>staffList){
        Boolean existingStaff = false;
        if(!staffList.isEmpty() && userid != null){
            for(conference360__Staff__c staff: stafflist){
                if(userid == staff.conference360__User__c){
                    return true;
                }
            }
        }
        return existingStaff;
    }
    
    /*
     * returns a shareObjectInfo object which helps the BTShareCreate Batch class
     * param:
     * accepts an sObject type 
     */
    public shareObjectInfo getShareInfo(sObject sObj){
        shareObjectInfo shr = new shareObjectInfo();
        switch on sObj{
            
            when conference360__event__c eve {
                shr.evntFilterField = 'Id';
                shr.sharingReason = 'BT_Mobile_Check_in_App__c';
                shr.shareAccess = 'Read';
                shr.additionalFilter = '';
            }
            
            when conference360__attendee__c att {
                shr.evntFilterField = 'conference360__event__c';
                shr.sharingReason = 'BT_Mobile_Check_in_App__c';
                shr.shareAccess = 'Edit';
                shr.additionalFilter = ' AND(conference360__Contact__c != null OR(conference360__Contact__c = null and is_Primary_Registrant__c = true))';
            }
        }
        return shr;
    }
    
    /*
     * Object to help with BTShareCreate Batch class
     */
    public class shareObjectInfo{
        public String evntFilterField{get;set;}
        public String sharingReason{get;set;}
        public String shareAccess{get;set;}
        public String additionalFilter{get;set;}
    }
    /*
     * Manage event staffs automatically when an Event Group is added/updated/deleted
     */
    public void manageEventStaffForGroup(Set<Id> eventGroupIds){

        Map<Id, List<conference360__Staff__c>> groupStaffMap = new Map<Id, List<conference360__Staff__c>>();
        Map<String, conference360__Staff__c> eventStaffMap = new Map<String, conference360__Staff__c>();
        List<conference360__Staff__c> newStaffList =  new List<conference360__Staff__c>();

        //Get all the Staffs related to Event Group or Events related to list of Ids
        for (conference360__Staff__c eventStaffObj: [SELECT Id,conference360__User__c, conference360__Event__c, Event_Group__c, Event_Group_Staff_Id__c  
                                                    FROM conference360__Staff__c 
                                                    WHERE Event_Group__c IN :eventGroupIds
                                                     OR (conference360__Event__r.conference360__Event_Group__c IN: eventGroupIds)]){
            if(eventStaffObj.conference360__Event__c == null){
                if(groupStaffMap.containsKey(eventStaffObj.Event_Group__c)){
                    List<conference360__Staff__c> tempSet = groupStaffMap.get(eventStaffObj.Event_Group__c);
                    tempSet.add(eventStaffObj);
                    groupStaffMap.put(eventStaffObj.Event_Group__c, tempSet);
                }
                else{
                    groupStaffMap.put(eventStaffObj.Event_Group__c, new List<conference360__Staff__c>{eventStaffObj});
                }
            }
            else if(eventStaffObj.conference360__Event__c != null){
                eventStaffMap.put(String.valueOf(eventStaffObj.conference360__Event__c)+'-'+String.valueOf(eventStaffObj.conference360__User__c), eventStaffObj);
            }
        }

        for(conference360__Event__c event : [SELECT Id,conference360__Event_Group__c FROM conference360__Event__c WHERE conference360__Event_Group__c IN :eventGroupIds]){
            if(groupStaffMap.containsKey(event.conference360__Event_Group__c)){
                for(conference360__Staff__c staff : groupStaffMap.get(event.conference360__Event_Group__c)){
                    if(eventStaffMap.containsKey(String.valueOf(event.Id)+'-'+String.valueOf(staff.conference360__User__c))){
                        //Remove the staff record from map if already present
                        eventStaffMap.remove(String.valueOf(event.Id)+'-'+String.valueOf(staff.conference360__User__c));
                    }
                    else{
                        //Create a new instance for Staff record for Event
                        newStaffList.add(new conference360__Staff__c(conference360__User__c = staff.conference360__User__c,
                                                                    conference360__Event__c = event.Id,
                                                                    Event_Group_Staff_Id__c = event.conference360__Event_Group__c));
                    }
                }
            }
        }
        if(!newStaffList.isEmpty()){
            Database.insert(newStaffList, false);
        }
        if(!eventStaffMap.isEmpty()){
            delete eventStaffMap.values();
        }
    }
    /*
     * Method to create and return a unique set of staff for Event/Event Group 
     */
    public Set<String> getExistingStaffRecordSet(Set<Id>eventIdSet, Set<Id> eventGroupIdSet){
        List<conference360__Staff__c> staffList = new List<conference360__Staff__c>();
        Set<String> returnSet = new Set<String>();
        for(conference360__Staff__c objStaff : [SELECT Id, conference360__Event__c, conference360__User__c, Event_Group__c, Event_Group_Staff_Id__c FROM conference360__Staff__c WHERE conference360__Event__c = :eventIdSet OR Event_Group__c = :eventGroupIdSet]){
            if(objStaff.Event_Group__c == null){
                returnSet.add(String.valueof(objStaff.conference360__Event__c)+'_'+String.valueof(objStaff.conference360__User__c));
            }
            else{
                returnSet.add(String.valueof(objStaff.Event_Group__c)+'_'+String.valueof(objStaff.conference360__User__c));
            }
        }   
        return returnSet;
    }
}