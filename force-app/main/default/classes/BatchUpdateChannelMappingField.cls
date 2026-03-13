/*******************************************************************************
* @author       Angelo Rivera
* @date         14/06/2018
* @description  Batch class that updates Channel Mapping field on Enquiry.
*               This only updates the existing cases where Channel Mapping is not populated.
* @revision    	02/05/2019 - Initial Version
*******************************************************************************/

global class BatchUpdateChannelMappingField implements Database.Batchable<sObject>,Schedulable{
    Environment_Settings__c environmentSettings = Environment_Settings__c.getInstance();
    Id mcRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Standard Enquiry').getRecordTypeId();
    public String strQuery = 'SELECT Id, Channel_Mapping__c, Origin FROM Case WHERE RecordTypeId = \'' + mcRecordTypeId + '\'';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(!Test.isRunningTest()) strQuery += ' AND Channel_Mapping__c = NULL AND CreatedDate >= ' + environmentSettings.Enquiry_Created_Date__c;
        System.debug('QUERY: '+ strQuery);
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<case> lstCase = (List<case>)scope;
        List<Case> lstCases = new List<Case>();

        if(!lstCase.isEmpty()){
            Map<String, MC_Enquiry_Origin_Category__mdt> mapEnquiryOriginCategoriesByLabel = new Map<String, MC_Enquiry_Origin_Category__mdt>();
            for(MC_Enquiry_Origin_Category__mdt mdt : [Select MasterLabel, Category__c  from MC_Enquiry_Origin_Category__mdt]){
                mapEnquiryOriginCategoriesByLabel.put(mdt.MasterLabel, mdt);
            }
            for(Case cse : lstCase){
                if(mapEnquiryOriginCategoriesByLabel.containsKey(cse.Origin)){
                    cse.Channel_Mapping__c = mapEnquiryOriginCategoriesByLabel.get(cse.Origin).Category__c;

                }else{
                    cse.Channel_Mapping__c = 'Other';
                }
                lstCases.add(cse);
            }

            //updates the list of Enquiry_Age_History__c records
            if(!lstCases.isEmpty()){
                Update lstCases;
                System.debug('Update completed.');
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new BatchUpdateChannelMappingField(), 200);
    }
}