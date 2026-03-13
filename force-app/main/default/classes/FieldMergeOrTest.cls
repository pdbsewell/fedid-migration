/*******************************************************************************
* @author       Inderpal Dhanoa
* @date         10/04/2021
* @description  Test class for FieldMergeOr Class
* @revision     1.0
*******************************************************************************/
@isTest(isParallel=true)
public class FieldMergeOrTest {
    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/04/2021
    * @description  Method for FieldMergeOrTest, mergeField
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void mergeFieldTest(){
        Account master = new Account(	Name = 'testCreateExternalAccount1', Monash_AM_Campus__c = 'South Africa',
        Anonymous_Donor__c = true, DBC_DUNS_Number__c = '1234',
        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('External_Organisation').getRecordTypeId());
        insert master;

        Account duplicate = new Account(	Name = 'testCreateExternalAccount2', Monash_AM_Campus__c = 'Malaysia',
        Anonymous_Donor__c = true, DBC_DUNS_Number__c = '12345',
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

            FieldMergeOr o_FieldMergeOr = new FieldMergeOr();

            SObject mergedMaster = (SObject)o_FieldMergeOr.mergeField(descFieldResult, masterRecord, duplicateRecord);
            system.debug('@@fieldsMerged'+mergedMaster);
            system.assertEquals(mergedMaster.get('Anonymous_Donor__c'), true);

            duplicate = [SELECT Id, Anonymous_Donor__c,DBC_DUNS_Number__c,Monash_AM_Campus__c FROM Account WHERE Name = 'testCreateExternalAccount2'];
            duplicate.Anonymous_Donor__c = false;
            update duplicate;

            master = [SELECT Id, Anonymous_Donor__c,DBC_DUNS_Number__c,Monash_AM_Campus__c FROM Account WHERE Name = 'testCreateExternalAccount1'];
            master.Anonymous_Donor__c = false;
            update master;

            duplicateRecord = (SObject)duplicate;
            masterRecord = (SObject)master;

            descFieldResult = fields.get('DBC_DUNS_Number__c').getDescribe();

            mergedMaster = (SObject)o_FieldMergeOr.mergeField(descFieldResult, masterRecord, duplicateRecord);
            Assert.areEqual('12345', mergedMaster.get('DBC_DUNS_Number__c'), 'Field merge was not successful');

            descFieldResult = fields.get('Monash_AM_Campus__c').getDescribe();

            mergedMaster = (SObject)o_FieldMergeOr.mergeField(descFieldResult, masterRecord, duplicateRecord);
            Assert.areEqual('South Africa', mergedMaster.get('Monash_AM_Campus__c'), 'Field merge was not successful');
        Test.stopTest();
    }
}