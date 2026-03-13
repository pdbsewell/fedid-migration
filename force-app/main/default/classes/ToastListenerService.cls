/**
 * @created                     October 18, 2018
 * @description                 Service Class for ToastListener lightning component
 * @modified					Added escapeSingleQuotes to prevent SOQL injection @rajeshpunjabi 03-AUG-2022
 */
public class ToastListenerService {
    /**
     * @created                     October 19, 2018
     * @description                 Retrieve custom metadata Toast_Listener_Auto_Redirection__mdt to flag success messages for listening
     * @return                      Map<String, String> - Map with its key as quick action success message and value of the object type where the user should be redirected
     */
    @AuraEnabled 
    public static Map<String, String> retrieveToastListenerAutoRedirection() {
        //Initialize Variables
        Map<String, String> autoRedirectionMap = new Map<String, String>();
        //Read Toast_Listener_Auto_Redirection__mdt records
        for (Toast_Listener_Auto_Redirection_Rule__mdt loopRule : [SELECT MasterLabel, Quick_Action_Success_Message__c, Redirect_to_Created_Object__c FROM Toast_Listener_Auto_Redirection_Rule__mdt]) {
            autoRedirectionMap.put(loopRule.Quick_Action_Success_Message__c, loopRule.Redirect_to_Created_Object__c);
        }
        
        return autoRedirectionMap;
    }
    
    /**
     * @created                     October 18, 2018
     * @description                 Queries the latest created record of the current user based on the object type parameter
     * @parameter                   String objectType - object type of the record to be queried
     * @return                      Id - Record Id of the latest created record - Redirect the user to this record
     * @modified					Added escapeSingleQuotes to prevent SOQL injection. @rajeshpunjabi 03-AUG-2022
     */
    @AuraEnabled 
    public static Id retrieveLatestCreatedRecord(String objectType) {

        //.. Santizing param to prevent SOQL injection
        String sObjectName = String.escapeSingleQuotes (objectType);

        //Construct Query String
        String queryString = 'SELECT Id FROM ' + sObjectName + ' WHERE CreatedById = \'' + UserInfo.getUserId() + '\' ORDER BY CreatedDate DESC LIMIT 1';
        
        //Query Record
        SObject queryCase = Database.query(queryString)[0];
        return (Id)queryCase.get('Id');
    }
}