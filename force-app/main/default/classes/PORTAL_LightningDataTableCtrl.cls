/*
 * Copyright (c) 2019, UC Innovation, Inc.  All Rights Reserved.
 *                     http://www.ucinnovation.com
 *
 * This source code is licensed, not sold, and is subject to a written
 * license agreement.  Among other things, no portion of this source
 * code may be copied, transmitted, disclosed, displayed, distributed,
 * translated, used as the basis for a derivative work, or used, in
 * whole or in part, for any program or purpose other than its intended
 * use in compliance with the license agreement as part of UC Innovation's
 * software.  This source code and certain of the algorithms contained
 * within it are confidential trade secrets of UC Innovation, Inc.
 * and may not be used as the basis for any other
 * software, hardware, product or service.
 */
 
 public class PORTAL_LightningDataTableCtrl {

    @AuraEnabled
    public static DataTableResponse getPledgeRecords(Map<String, Object> params) {

        String strObjectName = (String) params.get('strObjectName');
        String strFieldSetName = (String) params.get('strFieldSetName');
        String constituentId = (String) params.get('constituentId');
        String organizationId = (String) params.get('organizationId');
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        system.debug('strFieldSetName: ' + strFieldSetName);

        //To hold the table headers 
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        //Field to be queried - fetched from fieldset
        List<String> lstFieldsToQuery = new List<String>();

        //The final wrapper response to return to component
        DataTableResponse response = new DataTableResponse();
        
        for (Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields()) {
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            
            DataTableColumns datacolumns;
            //This way we can set the type of a column
            //We do not get the exact type from schema object which matches to lightning:datatable component structure
            if(dataType == 'datetime' || dataType == 'date'){
                //Create a wrapper instance and store label, fieldname and type.
                datacolumns = new DataTableColumns(String.valueOf(eachFieldSetMember.getLabel()) , 
                                                   String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                   'date-local');
            }
            else {
                //Create a wrapper instance and store label, fieldname and type.
                datacolumns = new DataTableColumns(String.valueOf(eachFieldSetMember.getLabel()) , 
                                                   String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                   String.valueOf(eachFieldSetMember.getType()).toLowerCase());
            }

            lstDataColumns.add(datacolumns);
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }

        // Map<String, Schema.SObjectField> opportunityFieldsMap = Schema.SObjectType.Opportunity.fields.getMap();

        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(! lstDataColumns.isEmpty()) {
            response.lstDataTableColumns = lstDataColumns;

            // String fieldsToQuery = '';

            // Integer count = 0;
            // for (String fieldStr : lstFieldsToQuery) {
            //     Schema.DescribeFieldResult fieldDescribeResult = opportunityFieldsMap.get(fieldStr).getDescribe();
            //     String fieldTypeStrFmt = String.valueOf(fieldDescribeResult.getType()).toLowerCase();
            //     if (fieldTypeStrFmt == 'date' || fieldTypeStrFmt == 'datetime') {
            //         fieldsToQuery += 'convertTimezone('+fieldStr+')';
            //     }
            //     else {
            //         fieldsToQuery += fieldStr;
            //     }
            //     if (count != lstFieldsToQuery.size() - 1) {
            //         fieldsToQuery += ',';
            //         count++;
            //     }
            // }

            String query = 'SELECT Id, ' + String.join(lstFieldsToQuery, ',') + ' FROM Opportunity';
            if (constituentId != null && constituentId != '') {
                query = query + ' WHERE ucinn_ascendv2__Contact__c =: constituentId';
            }
            else if (organizationId != null && organizationId != '') {
                query = query + ' WHERE AccountId =: organizationId';
            }
            else {
                response.lstDataTableData = new List<sObject>();
                return response;
            }
            query = query + ' AND RecordType.NamespacePrefix = \'ucinn_ascendv2\' AND RecordType.DeveloperName = \'Pledge\' AND ucinn_ascendv2__Session__r.ucinn_ascendv2__Session_Completed__c != NULL AND ucinn_ascendv2__Session__r.ucinn_ascendv2__Session_Completed_By__c != NULL AND ucinn_ascendv2__Session__r.ucinn_ascendv2__Is_Ready_for_G_L__c = TRUE AND ucinn_ascendv2__Session__r.ucinn_ascendv2__Session_Totals_Approved__c != NULL';
            System.debug('query: ' + query);
            response.lstDataTableData = Database.query(query);
            System.debug('data: ' + response.lstDataTableData);
        }
        
        return response;
    }

    //Wrapper class to hold Columns with headers
    public class DataTableColumns {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;}
        
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
        public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled
        public List<sObject> lstDataTableData {get;set;}
        
        public DataTableResponse() {
            lstDataTableColumns = new List<DataTableColumns>();
            lstDataTableData = new List<sObject>();
        }
    }
}