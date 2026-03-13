/**
 * @description  : chained batch class for Event and related record sharing to Staff (Blackthorn)
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 27-08-2021
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   including additional filters and accessing BTApexSharing Constructor
**/
global class BTShareCreateBatch implements Database.Batchable<sObject>{

    @TestVisible
    private Integer counter {get;set;}
    
    @TestVisible
    private List<sObjectType> sObjectList;
    
    @TestVisible
    private sObjectType sObjtype;
    
    @TestVisible
    private Map<Id,Set<id>> userIdByEventId;
    
    @TestVisible
    private BTStaffServices.shareObjectInfo shareObjInfo;
    
    /*
     * public constructor that could be called to initiate event record sharing with staff
     * param:
     * userIdByEventId: userids with the event ids to be shared
     */
    public BTShareCreateBatch(Map<Id,Set<id>>userIdByEventId){
        this.counter = 0;
        this.userIdByEventId = userIdByEventId;
        Init();
    }
    
    /*
     * private constructor that gets chained in the finish context to share the records of the next sObject
     * param:
     * counter: it determines the object that has to be processed to be shared
     * userIdByEventId: userids with the event ids to be shared
     */
    private BTShareCreateBatch(Integer counter, Map<Id,Set<id>>userIdByEventId,List<sObjectType>sObjectList){
        this.counter = counter;
        this.userIdByEventId = userIdByEventId;
        this.sObjectList = sObjectList;
        Init();
    }
    
    /*
     * initializing the required variables
     */
    public void Init(){
        //set the sObjectList when the class is initially called
        if(this.sObjectList==null){
            this.sObjectList = new List<sObjectType>();
            this.sObjectList.addall(BTStaffServices.shareObjMap.keyset());
        }
        
        this.sObjtype = sObjectList.get(counter);
        this.shareObjInfo = new BTStaffServices.shareObjectInfo();
        sObject sObj = this.sObjtype.newSObject();
        this.shareObjInfo = new BTStaffServices().getShareInfo(sObj);
        counter++;
    }
    
    /*
     * start method to perform the query
     */
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String sObjectName = sObjtype.getDescribe().getName().toLowerCase();
        String filterfield = shareObjInfo.evntFilterField;
        String query = '';
        String fields = '';
        String additionalFilterCriteria = shareObjInfo.additionalFilter;
        
        Set<Id> eventidset = new Set<Id>();
        eventidset = userIdByEventId.keyset();
        
        if(sObjectName == 'conference360__Event__c'){
            fields = 'id';
        }else{
            fields = 'id,'+filterfield;
        }
        
        if(!String.isBlank(sObjectName) && !String.isBlank(filterfield) && !eventidset.isEmpty()){
            query = 'SELECT '+fields+' FROM '+sObjectName+' WHERE '+filterfield+' IN: eventidset'+additionalFilterCriteria;
        }
        LogUtilityException.debug('BTShareCreateBatch query:' + query);
        return Database.getQueryLocator(query);
    }
    
    /*
     * execute method to process the record sharing
     */
    public void execute(Database.BatchableContext BC, List<SObject> scopes){
        SObjectType shareType = BTStaffServices.shareObjMap.get(this.sObjtype);
        BTApexSharing apexSharing = new BTApexSharing();

        if(shareType!=null && !scopes.isEmpty() && shareObjInfo!=null){
            for(sObject rec: scopes){
                id evntid = (Id)rec.get(shareObjInfo.evntFilterField);
                if(userIdByEventId.containskey(evntid)){
                    set<Id>userset = userIdByEventId.get(evntid);
                    if(userset!=null && !userset.isEmpty()){
                        for(id userid: userset){
                            apexSharing.setshareRecord(rec,shareType,userid,shareObjInfo.sharingReason,shareObjInfo.shareAccess);
                        }
                    }
                }
            }
        }
        apexSharing.processSharing();
    }
    
    /*
     * finish method to handle chaining of the next sObject in the BTStaffServices.shareObjMap collection
     */
    public void finish(Database.BatchableContext BC){
        LogUtilityException.getLimits();
        if (counter < this.sObjectList.size()) {
            Database.executeBatch(new BTShareCreateBatch(counter,this.userIdByEventId,this.sObjectList));
        }
	}
}