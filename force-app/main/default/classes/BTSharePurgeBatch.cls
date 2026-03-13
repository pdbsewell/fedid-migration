/**
 * @description  : chained batch class for deletion of Event and related record shared with Staff (Blackthorn)
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 27-08-2021
 * @revision 
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   removed query limit of 10000 records from start method 
**/
global class BTSharePurgeBatch implements Database.Batchable<sObject>{

    @TestVisible
    private Integer counter {get;set;}
    
    @TestVisible
    private List<sObjectType> sObjectList;
    
    @TestVisible
    private Set<id>userIdSet;
    
    @TestVisible
    private map<Id,set<id>> userIdByEventId;

    @TestVisible
    private Map<id,Set<Id>>usersWithParentMap;
    
    @TestVisible
    private string sObjName;
    
    @TestVisible
    private string shareObjName;
    
    @TestVisible
    private Map<Id,conference360__Event__c>eventChildRecMap;

     /*
     * public constructor that could be called to initiate deletion of sharing recs associated with staff
     * param:
     * userIdByEventId: userids associated to the event ids that needs to be deleted
     */
    public BTSharePurgeBatch(map<Id,set<id>>userIdByEventId){
        this.counter = 0;
        this.userIdByEventId = userIdByEventId;
        this.eventChildRecMap = new Map<Id,conference360__Event__c>();
        
        processSobjRecs();
    }

    /*
     * private constructor that gets chained in the finish context to delete the records of the next sObject
     * param:
     * counter: it determines the object that has to be processed to be deleted
     * userIdByEventId: userids with the event ids to be deleted
     * eventChildRecMap: collection of all associated child records
     * sObjectList: collection of list of sObjects
     */
    private BTSharePurgeBatch(Integer counter,Map<Id,conference360__Event__c> eventChildRecMap, map<Id,set<id>>userIdByEventId,List<sObjectType>sObjectList){
        this.counter = counter;
        this.userIdByEventId = userIdByEventId;
        this.eventChildRecMap = eventChildRecMap;
        this.sObjectList = sObjectList;
        
        processSobjRecs();
    }

    /*
     * Initial processing of the sObjects and the records associated with the sObjects
     */
    private BTSharePurgeBatch processSobjRecs(){
        //fetch the child records associated with the event when the batch is initially called
        if(this.eventChildRecMap.isEmpty()&& !this.userIdByEventId.isEmpty()){
            this.eventChildRecMap = new BTStaffservices().getEventChildRecordsMap(this.userIdByEventId.keyset());
        }
        //set the sObjectList when the class is initially called
        if(this.sObjectList==null){
            this.sObjectList = new List<sObjectType>();
        	this.sObjectList.addall(BTStaffServices.shareObjMap.keyset());
        }
        //fetch the sObject type to process in the iteration and fetch its name
        sObjectType sObjType = sObjectList.get(counter);
        sObjectType shareObjType = BTStaffServices.shareObjMap.get(sObjType);
        
        this.sObjName = sObjType.getDescribe().getName().toLowerCase();
        this.shareObjName = shareObjType.getDescribe().getName().toLowerCase();
        counter++;
        
        //process the collections to dynamically fetch the recordids associated with the iterated Object
        if(!String.isBlank(this.sObjName) && !String.isBlank(this.shareObjName)&&
			this.userIdByEventId.size() > 0 && this.eventChildRecMap.size() > 0){
            	this.useridset = new Set<id>();
                this.usersWithParentMap = new Map<id,Set<Id>>();
                
                for(id eveid: this.userIdByEventId.keyset()){
                    set<id> userset = this.userIdByEventId.get(eveid);
                    this.useridset.addAll(userset);
                    if(this.eventChildRecMap.containskey(eveid)){
                        conference360__Event__c eve = this.eventChildRecMap.get(eveid);
                        
                        //dynamically fetch the records based on the sObjecttype
                        list<sObject>recsList = new BTEventShareDAO(eve)
                        .setRelatedRecords(eve.conference360__Attendees__r)
                        .getRecordsList(sObjName);
                       
                        if(recsList!=null && !recsList.isEmpty()){
                            for(sObject rec:recsList){
                                id recid = (Id)rec.get('Id');
                                if(recid!=null && !userset.isEmpty()){
                                    this.usersWithParentMap.put(recid,userset); 
                                }
                            }
                        } 
                    }
            	}
        	}
        return this;
    }

    /*
     * start method to dynamically render and run the query
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = '';
        set<id> parentidset = new set<id>();
        parentidset = usersWithParentMap.keyset();
        
        if(!string.isblank(shareObjName)){
            query = 'SELECT Id,UserOrGroupId,parentid FROM '+shareObjName+' WHERE';
            
            if(!useridset.isEmpty()){
                query +=' UserOrGroupId IN: useridset AND';
            }
            
            if(!parentidset.isEmpty()){
                query += ' parentid IN: parentidset AND';
            }
            
            query += ' RowCause = \'BT_Mobile_Check_in_App__c\'';
        }
        
        LogUtilityException.debug('BTSharePurgeBatch query:' + query);
        return Database.getQueryLocator(query);
    }

    //fetch the relative sharing records to delete and delete the sharing records
    public void execute(Database.BatchableContext BC, List<SObject> scopes){
        list <sObject> recsToDelete = new list <sObject>();
        if(!scopes.isEmpty() && !this.usersWithParentMap.isEmpty()){
            
            //fetch the relative sharing records to delete
            for(sObject rec: scopes){
                id parentid = (Id)rec.get('parentid');
                id userorgroupid = (Id)rec.get('userOrGroupId');
                if(this.usersWithParentMap.containsKey(parentid)){
                    
                    set <id> idset = this.usersWithParentMap.get(parentid);
                    for(id userid: idset){
                        if(userorgroupid == userid){
                            recsToDelete.add(rec);
                        }
                    }
                }
            }
        }
        
        //delete the fetched sharing records
        if(!recsToDelete.isEmpty()){
            Database.DeleteResult[] drList = Database.delete(recsToDelete, false);

            // Iterate through each returned result
			integer i = 0;
            for (Database.DeleteResult dr : drList) {
            	if (!dr.isSuccess()) {
                	// Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        LogUtilityException.addLogEvent(this.sObjName, scopes[i], err, 'BTSharePurgeBatch.execute');
                    }
                }
                i++;
            }
            LogUtilityException.publishAll();
        }
        

    }

    /*
     * finish method to handle chaining of the next sObject in the sObjectList collection
     */
    public void finish(Database.BatchableContext BC){
        LogUtilityException.getLimits();
        if (counter < this.sObjectList.size()) {
            Database.executeBatch(new BTSharePurgeBatch(counter,this.eventChildRecMap,this.userIdByEventId,this.sObjectList));
        }
    }
}