@isTest
public class EngageDedupeInterimScheduler_Test {
	
    public static String CRON_VAL = ' 0 0 0 15 3 ? 2050';
    
    @isTest
    static void testScheduledJob() {
        
        Test.startTest();
        EngageDedupeInterimScheduler dedupeSched = new EngageDedupeInterimScheduler();
        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('interimNewBatchSize', 1);
        paramMap.put('interimPendingBatchSize', 1);
        paramMap.put('interimInProgressBatchSize', 1);
        paramMap.put('recordTypeDeveloperName', 'Online_Donation_Interface');
        paramMap.put('recordTypeNamespacePrefix', 'ucinn_ascendv2');
        dedupeSched.params = paramMap;
        String jobId = System.schedule('DedupeBatch', CRON_VAL, dedupeSched);
        Test.stopTest();

    }
    
    @isTest
    static void test_MatchingKVBatch() {
        
        ucinn_ascendv2__Matching_Key_Rule__c target_mkr1 = new ucinn_ascendv2__Matching_Key_Rule__c();
        target_mkr1.ucinn_ascendv2__Create_Matching_Keys__c = true;
        target_mkr1.ucinn_ascendv2__Is_for_Source_Object_Use__c = true;
        target_mkr1.ucinn_ascendv2__Is_for_Target_Object_Use__c = true;
        target_mkr1.ucinn_ascendv2__Key_Value_Field_API_Name__c = 'Matching_Key_Value_1__c';
        target_mkr1.ucinn_ascendv2__Key_Value_Set_Created__c = true;
        target_mkr1.Name = 'First Key';
        target_mkr1.ucinn_ascendv2__Object_Name__c = 'Contact';
        insert target_mkr1;
        
        ucinn_ascendv2__Matching_Key_Rule__c target_mkr2 = new ucinn_ascendv2__Matching_Key_Rule__c();
        target_mkr2.ucinn_ascendv2__Create_Matching_Keys__c = true;
        target_mkr2.ucinn_ascendv2__Is_for_Source_Object_Use__c = true;
        target_mkr2.ucinn_ascendv2__Is_for_Target_Object_Use__c = true;
        target_mkr2.ucinn_ascendv2__Key_Value_Field_API_Name__c = 'Matching_Key_Value_2__c';
        target_mkr2.ucinn_ascendv2__Key_Value_Set_Created__c = true;
        target_mkr2.Name = 'Second Key';
        target_mkr2.ucinn_ascendv2__Object_Name__c = 'Contact';
        insert target_mkr2;
        
        ucinn_ascendv2__Matching_Keys__c mk1 = new ucinn_ascendv2__Matching_Keys__c();
        mk1.Name = 'First Key';
        mk1.ucinn_ascendv2__Creation_Method__c = 'First 5 Characters';
        mk1.ucinn_ascendv2__Field_API_Name__c = 'FirstName';
        mk1.ucinn_ascendv2__Field_Index__c = 1.0;
        mk1.ucinn_ascendv2__Matching_Key_Rule__c = target_mkr1.ID;
        insert mk1;
        
        ucinn_ascendv2__Matching_Keys__c mk2 = new ucinn_ascendv2__Matching_Keys__c();
        mk2.Name = 'First Key';
        mk2.ucinn_ascendv2__Creation_Method__c = 'First 3 Characters';
        mk2.ucinn_ascendv2__Field_API_Name__c = 'FirstName';
        mk2.ucinn_ascendv2__Field_Index__c = 1.0;
        mk2.ucinn_ascendv2__Matching_Key_Rule__c = target_mkr2.ID;
        insert mk2;
        
        ucinn_ascendv2__Matching_Rule__c mr = new ucinn_ascendv2__Matching_Rule__c();
        mr.ucinn_ascendv2__Is_Active__c = true;
        mr.ucinn_ascendv2__Common_Threshold__c = 50.0;
        mr.ucinn_ascendv2__Source_Matching_Rule_1__c = target_mkr2.Id;
        mr.Name = 'Interim To Contact';
        mr.ucinn_ascendv2__Target_Matching_Rule_1__c = target_mkr1.Id;
        mr.ucinn_ascendv2__Source_Object_Name__c = 'Interim__c';
        mr.ucinn_ascendv2__Target_Object_Name__c = 'Contact';
        insert mr;
        
        Contact contact = new Contact(LastName = 'LastName', FirstName = 'FirstName');
        insert contact;
        
        Test.startTest();
        EngageDedupeInterimScheduler dedupeSched = new EngageDedupeInterimScheduler();
        dedupeSched.batchType = 'MatchingKVBatch';
        Map<String, Object> paramMap = new Map<String, Object>();
        paramMap.put('matchingRuleId', mr.Id);
        paramMap.put('whereClause', 'Where LastName = \'LastName \'');
        paramMap.put('batchSize', 1);
        dedupeSched.params = paramMap;
        String jobId = System.schedule('DedupeBatch', CRON_VAL, dedupeSched);
        Test.stopTest();
    }
    
}