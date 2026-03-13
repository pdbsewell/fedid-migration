/**
 * @description  : Helper class to process ApexSharing
 * @author       : Ibrahim Rumi
 * @group        : Event Management
 * @date         : 27-08-2021
 * @revision
 * Ver   Date         Author         Modification
 * 1.0   05-10-2021   Ibrahim Rumi   added constructor and modified setshareRecord and processSharing methods 
**/
public without sharing class BTApexSharing {

    @TestVisible
    private List<SObject> shareRecordsList;

    /**
    * @description public constructor with no param to initiate the collections
    * 
    **/
    public BTApexSharing() {
        this.ShareRecordsList = new List<SObject>();
    }
    
    /*
     * method to aid set up of share records
     * param:
     * rec - sObject Record to share
     * shareObjType - sObjectType of the share object
     * userOrGroupId - user or group to share record with
     * sharingReason - apex sharing reason of the sObject
     * accessLevel - "Read" or "Write" permission to be shared on the record
     */
    public void setShareRecords(List<SObject> recs, sObjectType shareObjType, Id userOrGroupId, String sharingReason, String AccessLevel){
        
        if(recs != null && recs.size() > 0 && shareObjType!=null){
            for(sObject rec: recs){
                setshareRecord(rec,shareObjType,userOrGroupId,sharingReason,AccessLevel);
            }
        }
        
        // return apexShareList;
    }
    
     /*
     * method to aid set up of share record
     * param:
     * rec - sObject Record to share
     * shareObjType - sObjectType of the share object
     * userOrGroupId - user or group to share record with
     * sharingReason - apex sharing reason of the sObject
     * accessLevel - "Read" or "Write" permission to be shared on the record
     */
    public void setshareRecord(sObject rec, sObjectType shareObjType, Id userOrGroupId, String sharingReason, String accessLevel){
        
        if(rec != null && shareObjType!=null){
                
                if(shareObjType != null){
                    
                    SObject share = shareObjType.newSObject();
                    share.put('ParentId', rec.Id);
                    share.put('UserOrGroupId',  userOrGroupId);
                    share.put('RowCause', sharingreason);
                    share.put('AccessLevel', accessLevel);
                    
                    this.shareRecordsList.add(share);
                
            }
        }
    }
    
    /*
     * method to insert the share records in the database
     */
    public void processSharing(){
        if(!this.shareRecordsList.isEmpty()){
            Database.SaveResult[] lsr = Database.insert(ShareRecordsList,false);
        
            // Create counter
            Integer i=0;
            
            // Process the save results
            for(Database.SaveResult sr : lsr){
                if(!sr.isSuccess()){
                    // Get the first save result error
                    Database.Error err = sr.getErrors()[0];
                    LogUtilityException.addLogEvent(ShareRecordsList.getSObjectType(),ShareRecordsList[i], err.getMessage(),'Error');            
                   
                }
                i++;
            }   
            LogUtilityException.publishAll();
        }
    }
}