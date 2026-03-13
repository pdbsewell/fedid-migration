/**
 * @author Ibrahim Rumi
 * @date 27-08-2020
 * @group Event Management
 * @description DAO class to Event Sharing (Blackthorn)
 **/
public virtual class BTEventShareDAO {
    public conference360__Event__c eventRec {get; set;}
    public Map<String,list<sObject>>sObjectMap;
    
    /*
     * constructor accepts event record as param
     */
    public BTEventShareDAO(conference360__Event__c evRec) {
        this.eventRec = evRec;
        this.sObjectMap = new Map<String,List<sObject>>();
        
    }
    
    /*
     * method used to set the sObject records related to the event
     */
    public BTEventShareDAO setRelatedRecords(list<sObject> recs){
        
        if(recs!=null){
            String sType = recs.getSObjectType().getDescribe().getName().toLowerCase();
            this.sObjectMap.put(sType,recs);
            system.debug('sObjectMap'+this.sObjectMap);
        }else{
            throw new BTEventShareDAOException('sObject type is null');
        }
        return this;
    }

    /*
     * method to dynamically fetch sObject Records stored in sObjectMap 
     * by passing object APIname as param
     */
    public List<sObject>getRecordsList(String sObjectName){
        sObjectName = sObjectName.toLowerCase();
        List<sObject> recslist = new List<sObject>();
        switch on sObjectName{
            
            when('conference360__event__c'){
                recslist = new list<sObject>{this.eventrec};
            }
            when('conference360__attendee__c'){
                if(this.sObjectMap.containsKey(sObjectName)){
                    recslist = this.sObjectMap.get(sObjectName);
                }
            }
        }
        return recslist;
    }
    
    public class BTEventShareDAOException extends Exception { }
}