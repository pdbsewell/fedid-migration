public with sharing class ApplicationTableController {

    public static Boolean RemoveApplication(String appId) {
        List<Application__c> apps = [
                SELECT Id
                FROM Application__c
                WHERE Id = :appId
        ];

        if (apps.size() > 0) {
            //Remove the application from Salesforce.
            delete apps[0];
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    public static Boolean RemoveAcp(String acpId) {
        List<Application_Course_Preference__c> prefs = [
                SELECT Id, Application__c
                FROM Application_Course_Preference__c
                WHERE Id = :acpId
        ];

        if (prefs.size() > 0) {
            //Check to see if there are any ACPs which are left attached to the parent
            List<Application_Course_Preference__c> parents = [
                    SELECT Id, Application__c
                    FROM Application_Course_Preference__c
                    WHERE Application__c = :prefs[0].Application__c];

            delete prefs[0];

            if(parents.size() == 1){
                //Remove the parent application
                RemoveApplication(prefs[0].Application__c);
            }

            return true;
        }
        return false;
    }

    public class AppStatusWrapper
    {
        public String appId;
        public String acpId;
        public String status;

        public AppStatusWrapper(String applicationId, String coursePrefId, String appStatus)
        {
            appId = applicationId;
            acpId = coursePrefId;
            status = appStatus;
        }
    }

    @AuraEnabled
    public static String GetAppIdByAcp(String acpId) {
        String value = MyApplicationUtilities.getAppIdByAcpId(acpId);
        return value;
    }

    @AuraEnabled
    public static String GetAppByAcp(String acpId)
    {
        String appId = MyApplicationUtilities.getAppIdByAcpId(acpId);
        String stat = MyApplicationUtilities.getApplicationStatusByAppId(appId);

        ExLog.add('ApplicationTableController', 'GetAppId', appId + ' ' + stat, '');
        return JSON.serialize(new AppStatusWrapper(appId, acpId, stat));

    }
    
    /**
      * Revision Shalini Mendu - 20/07/2022 - Uses Checkmarx DynamicSoqlBuilder
     */

    @AuraEnabled
    public static DataTableResponse getRecords(String strObjectName, String strFieldSetName, String clause) {

        //Get the fields from FieldSet
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);

        //To hold the table hearders
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();

        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();

        //The final wrapper response to return to component
        DataTableResponse response = new DataTableResponse();

        for (Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields()) {
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            //This way we can set the type of a column
            //We do not get the exact type from schema object which matches to lightning:datatable component structure
            if (dataType == 'datetime') {
                dataType = 'date';
            }
            //Create a wrapper instance and store label, fieldname and type.
            DataTableColumns datacolumns = new DataTableColumns(String.valueOf(eachFieldSetMember.getLabel()),
                    String.valueOf(eachFieldSetMember.getFieldPath()),
                    String.valueOf(eachFieldSetMember.getType()).toLowerCase());
            lstDataColumns.add(datacolumns);
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        Set<String> fieldsSet = new Set<String>(lstFieldsToQuery);
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if (!lstDataColumns.isEmpty()) {
            response.lstDataTableColumns = lstDataColumns;

            String dynamicTotSearchQuery = DynamicSoqlBuilder.getInstance()
            .showSOQLStatement(true)
            .setEnforced(false)
            .querySObject(String.escapeSingleQuotes(strObjectName))
            .queryFields( fieldsSet)
            .getQuery(String.escapeSingleQuotes(clause));
    
            System.debug(dynamicTotSearchQuery);
            response.lstDataTableData = Database.query(dynamicTotSearchQuery);
        }

        return response;
    }

    //Wrapper class to hold Columns with headers
    public class DataTableColumns {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public String type { get; set; }

        //Create and set three variables label, fieldname and type as required by the lightning:datatable
        public DataTableColumns(String label, String fieldName, String type) {
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }

    //Wrapper calss to hold response - This response is used in the lightning:datatable component
    public class DataTableResponse {
        @AuraEnabled
        public List<DataTableColumns> lstDataTableColumns { get; set; }
        @AuraEnabled
        public List<sObject> lstDataTableData { get; set; }

        public DataTableResponse() {
            lstDataTableColumns = new List<DataTableColumns>();
            lstDataTableData = new List<sObject>();
        }
    }
}