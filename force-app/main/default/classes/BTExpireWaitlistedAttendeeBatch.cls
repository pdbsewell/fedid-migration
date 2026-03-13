/**
* @description        : Sets Registration status to canceled and
*                       Waitlist registration reason to Waitlist Expired
*                       when waitlist Expiry hours > current time and
*                       Registration Status is still "Pending" and
*                       Registration status reason is "Pending Waitlist Registration"
 * @author            : Ibrahim Rumi 
 * @group             : Event Management
 * @created date      : 12-07-2021
**/

public without sharing class BTExpireWaitlistedAttendeeBatch implements Database.Batchable<sObject> {
    
    public BTExpireWaitlistedAttendeeBatch(){
        
    }

    public database.querylocator start(Database.BatchableContext BC)
    {
        string query;
        DateTime dt = System.now();
        String REG_STATUS_REASON_PENDING_WL_REG = BTAttendeeServices.REG_STATUS_REASON_PENDING_WL_REG;
        String REG_STATUS_PENDING = BTAttendeeServices.REG_STATUS_PENDING;
        
        query = 'SELECT id,conference360__Registration_Status__c,Registration_status_reason__c FROM conference360__Attendee__c ';
        query += 'WHERE Waitlist_Registration_Expiry__c <: dt AND conference360__Registration_Status__c =: REG_STATUS_PENDING AND Registration_status_reason__c =: REG_STATUS_REASON_PENDING_WL_REG';
        
        return Database.getQueryLocator(query);
    }   

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<conference360__Attendee__c> attendeeList=(List<conference360__Attendee__c>)scope;
        
        if(!attendeeList.isEmpty()){
            attendeeList = new BTAttendeeServices().expireWaitlistedAttendee(attendeeList);
            
            Database.SaveResult[] lsr = Database.update(attendeeList,false);
            
            for(Integer i=0; i<attendeeList.size(); i++){
                for(Database.SaveResult sr : lsr){
                    if(!sr.isSuccess()){
                        // Get the first save result error
                        Database.Error err = sr.getErrors()[0];
                        
                        logUtilityException.addLogEvent('conference360__Attendee__c', attendeeList[i], err, 'BTExpireWaitlistedAttendeeBatch');
                    }
            	}
            }
            LogUtilityException.publishAll();
        }
    } 

    public void finish(Database.BatchableContext BC) {
        
    }
}