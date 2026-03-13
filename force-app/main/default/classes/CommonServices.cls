/**
 * @description       : A non specific 'global' class containing methods that can be leveraged by multiple domains
 * @author            : PwC
 * @group             : Helper
 * @last modified on  : 2020-10-16
 * @last modified by  : Stefan Scheit
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.2         PV - Added ISActive check on Get RecordTypeId
 * 1.1   2020-10=16   Stefan Scheit   Update of recordTypeId() method to use record type developer name instead of name.
 * 1.0   20??-??-??   PwC             Initial Version
**/
public class CommonServices {

    public static string ORGWIDE_ADDRESS_MONASH = 'Monash University';

    /*
     * returns an id of a record type, provided an sobject name and record type name
     * @param sObjName - The name of the sobject that uses the record type
     * @param recordTypeDeveloperName - The developerName of the record type
     */
    @TestVisible
    private static Map<Id,Schema.RecordTypeInfo> mapRTIds;
    @TestVisible
    private static String lastSObjName;
    public static Id recordTypeId( String sObjName, String recordTypeDeveloperName ) {
        try {
            Schema.RecordTypeInfo schemaRtinfo;
            if(mapRTIds == null || lastSObjName != sObjName) {
                mapRTIds = Schema.getGlobalDescribe().get(sObjName).getDescribe().getRecordTypeInfosById();
            }
            for(Schema.RecordTypeInfo srtinfo :mapRTIds.values()) {
                System.debug('!!@@##:getDeveloperName():'+srtinfo.getDeveloperName());
                if(srtinfo.getDeveloperName() == recordTypeDeveloperName && srtinfo.isActive()) {
                    schemaRtinfo = srtinfo;
                    break;
                }
            }
            //
            lastSObjName = sObjName;
            //
            return schemaRtinfo.getRecordTypeId();
        } catch (exception e) {
            return null; // not found
        }
    }
    /*
     * returns an id of an org wide email address
     * @param displayName the name of the email address that we want an id for
     */
    public static Id orgWideAddressId(String displayName) {

        for(OrgWideEmailAddress owa : [select id, DisplayName from OrgWideEmailAddress]) {
            if(owa.displayName.contains(displayName)) return owa.id;
        }
        return null;

    }

    /*
     * return boolean describing if in sandbox
     */
    public static Boolean isSandbox {
        get{
            if(isSandbox == null) {
                isSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return isSandbox;
        }
        set;
    }

    /*
     * returns List of Queues
     * @param Sobject Name
     * Added by: Ryan Wilson
     */
    public static Map<Id,String> mapQueue(String objName) {
        Map<Id,String> mapQue = new Map<Id,String>();
        List<QueueSobject> caseQueues = [SELECT Id, QueueId, Queue.Name, SobjectType FROM QueueSobject WHERE SobjectType =:objName];
        for(QueueSobject que: caseQueues) {
            mapQue.put(que.QueueId, que.Queue.Name);
        }
        return mapQue;
    }

}