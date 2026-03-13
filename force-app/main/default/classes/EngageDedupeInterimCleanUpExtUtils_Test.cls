@isTest(isParallel=true)
public class EngageDedupeInterimCleanUpExtUtils_Test {
    @isTest
	public static void testInterimCleanUpUtils() {
        
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;

        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Test', ucinn_ascendv2__Last_Name__c = 'Interim', RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'New');
        insert testInterim;
        
        ucinn_ascendv2.ascend_DEDUPE_GlobalWrapper.startProcessInterims(new Map<String, Object>{'recordTypeDeveloperName' => 'Raisers_Edge_Interface',
            																					'interimNewBatchSize' => 5,
            																					'interimPendingBatchSize' => 5,
            																					'interimInProgressBatchSize' => 5});
    }
    
    @isTest
    public static void testCreationOfCleanUpFieldMap() {
        
        //Test with RE Record type.
        Id reRecordTypeID = [SELECT Id FROM RecordType WHERE RecordType.DeveloperName = 'Raisers_Edge_Interface' AND RecordType.NamespacePrefix = ''].Id;
        
    	Dedupe_Interim_Clean_Up__mdt metadata = new Dedupe_Interim_Clean_Up__mdt(Record_Type_Namespace_Prefix__c = '',
                                                                                 Record_Type_Developer_Name__c = 'Raisers_Edge_Interface',
                                                                                 Field_Name__c = 'ucinn_ascendv2__First_Name__c',
                                                                                 Current_Value__c = 'Bob',
                                                                                 New_Value__c = 'Bobby');
        
    	Dedupe_Interim_Clean_Up__mdt metadata2 = new Dedupe_Interim_Clean_Up__mdt(Record_Type_Namespace_Prefix__c = '',
                                                                                 Record_Type_Developer_Name__c = 'default',
                                                                                 Field_Name__c = 'ucinn_ascendv2__Last_Name__c',
                                                                                 Current_Value__c = 'Jones',
                                                                                 New_Value__c = 'Jonas');
        
        ucinn_ascendv2__Interim__c testInterim = new ucinn_ascendv2__Interim__c(ucinn_ascendv2__First_Name__c = 'Bob', ucinn_ascendv2__Middle_Name__c = 'Test', ucinn_ascendv2__Last_Name__c = 'Jones', RecordTypeId = reRecordTypeID, ucinn_ascendv2__Status__c = 'New');
        insert testInterim;
        
        EngageDedupeInterimCleanUpExtUtils.METADATA_RECORD_TYPE_PREFIX = '';
        EngageDedupeInterimCleanUpExtUtils.METADATA_RECORD_TYPE_DEVELOPER_NAME = 'Raisers_Edge_Interface';
        EngageDedupeInterimCleanUpExtUtils.UNIQUE_INTERFACE_PROCESSING_INTERIM_RECORDTYPE = 'c.Raisers_Edge_Interface';
        EngageDedupeInterimCleanUpExtUtils.DEFAULT_TO_ALL_INTERFACES = 'default';
        
		EngageDedupeInterimCleanUpExtUtils.createFieldCleanUpMap_Default();
        EngageDedupeInterimCleanUpExtUtils.createFieldCleanUpMap(new List<Dedupe_Interim_Clean_Up__mdt>{metadata, metadata2});
        EngageDedupeInterimCleanUpExtUtils.cleanupInterimFields_Default(testInterim);
        
        //testInterim = [SELECT ucinn_ascendv2__Manual_Review_Reason__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__First_Name__c, ucinn_ascendv2__Last_Name__c FROM ucinn_ascendv2__Interim__c WHERE ucinn_ascendv2__Middle_Name__c =: 'Test'][0];
        System.debug(testInterim);
        System.assert(testInterim.ucinn_ascendv2__First_Name__c == 'Bobby', 'This interim should have been renamed to Bobby Jonas.');
        System.assert(testInterim.ucinn_ascendv2__Last_Name__c == 'Jonas', 'This interim should have been renamed to Bobby Jonas.');
    }
}