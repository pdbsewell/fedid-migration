/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/04/2021
* @description  Test class for FieldMergeAnd Class
* @revision     1.0
*******************************************************************************/
@isTest(isParallel=true)
public class FieldMergeDefaultTest { 
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Method for FieldMergeAndTest, mergeField
    * @revision     1.0
    *******************************************************************************/ 
    @isTest
    public static void FieldMergeDefaultTest(){
        Account master = new Account(	Name = 'testCreateExternalAccount1', Monash_AM_Campus__c = 'South Africa',
        Anonymous_Donor__c = true, DBC_DUNS_Number__c = null,
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert master;

        Account duplicate = new Account(	Name = 'testCreateExternalAccount2', Monash_AM_Campus__c = 'Malaysia',
        Anonymous_Donor__c = true, DBC_DUNS_Number__c = '1234',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert duplicate;

        Test.startTest();
            SObject masterRecord = (SObject)master;
            SObject duplicateRecord = (SObject)duplicate;

            Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe();
            Schema.SObjectType s = m.get('Account');
            Schema.DescribeSObjectResult r = s.getDescribe();
            Map<String,Schema.SObjectField> fields = r.fields.getMap();

            Schema.DescribeFieldResult descFieldResult = fields.get('Anonymous_Donor__c').getDescribe();

            FieldMergeDefault o_FieldMergeDefault = new FieldMergeDefault();  
            
            SObject mergedMaster = (SObject)o_FieldMergeDefault.mergeField(descFieldResult, masterRecord, duplicateRecord);
            Assert.areEqual(true, mergedMaster.get('Anonymous_Donor__c'), 'Field merge was not successful');

            descFieldResult = fields.get('DBC_DUNS_Number__c').getDescribe();

            mergedMaster = (SObject)o_FieldMergeDefault.mergeField(descFieldResult, masterRecord, duplicateRecord);
            Assert.areEqual('1234', mergedMaster.get('DBC_DUNS_Number__c'), 'Field merge was not successful');

            descFieldResult = fields.get('Monash_AM_Campus__c').getDescribe();

            mergedMaster = (SObject)o_FieldMergeDefault.mergeField(descFieldResult, masterRecord, duplicateRecord);
            Assert.areEqual('South Africa;Malaysia', mergedMaster.get('Monash_AM_Campus__c'), 'Field merge was not successful');
        Test.stopTest();
    }    
}