/**
 * @description Test class for BDPAcpOfferConditionSync
 */
@isTest(isParallel=true)
public class BDPAcpOfferConditionSync_Test {

    private static final Id ACP_1_RECORD_ID = FakeRecordIdGenerator.generateId(
            Application_Course_Preference__c.getSObjectType()
    );

    private static final Id ACP_2_RECORD_ID = FakeRecordIdGenerator.generateId(
        Application_Course_Preference__c.getSObjectType()
    );

    @isTest
    static void shouldUpdateOneAcpConditionForOneBdpRecord() {
        
        SObjectDaoMock acpDao = new SObjectDaoMock();
        
        BDPAcpOfferConditionSync offerConditionSync = new BDPAcpOfferConditionSync();
        offerConditionSync.init();
        offerConditionSync.acpDao = acpDao;
        offerConditionSync.acpSelector = (ACPSelector) Test.createStub(
            ACPSelector.class, 
            new ACPSelectorMock()
        );

        Bulk_Data_Processing__c bdp = new Bulk_Data_Processing__c();
        bdp.Transfer_To__c = ACP_1_RECORD_ID;
        bdp.Offer_Condition__c = 'zzz';

        List<Bulk_Data_Processing__c> bdps = new List<Bulk_Data_Processing__c>{bdp};

        offerConditionSync.execute(bdps);

        Application_Course_Preference__c updatedRecord = (Application_Course_Preference__c) acpDao.recordsUpdated[0];
        System.assertEquals('zzz', updatedRecord.Offer_Condition__c, 
            'Expected Offer Condition to be updated to zzz'
        );
    }

    @isTest
    static void shouldUpdateTwoAcpConditionsForTwoBdpRecords() {
        SObjectDaoMock acpDao = new SObjectDaoMock();
        
        BDPAcpOfferConditionSync offerConditionSync = new BDPAcpOfferConditionSync();
        offerConditionSync.init();
        offerConditionSync.acpDao = acpDao;
        offerConditionSync.acpSelector = (ACPSelector) Test.createStub(
            ACPSelector.class, 
            new ACPSelectorMock()
        );

        Bulk_Data_Processing__c bdp1 = new Bulk_Data_Processing__c();
        bdp1.Transfer_To__c = ACP_1_RECORD_ID;
        bdp1.Offer_Condition__c = 'yyy';

        Bulk_Data_Processing__c bdp2 = new Bulk_Data_Processing__c();
        bdp2.Transfer_To__c = ACP_2_RECORD_ID;
        bdp2.Offer_Condition__c = 'zzz';

        List<Bulk_Data_Processing__c> bdps = new List<Bulk_Data_Processing__c>{
            bdp1, bdp2};

        offerConditionSync.execute(bdps);

        Boolean IsAcp1ConditionUpdated = false;
        Boolean IsAcp2ConditionUpdated = false;

        for (Application_Course_Preference__c updatedRecord : 
                (Application_Course_Preference__c[]) acpDao.recordsUpdated) {
            if (updatedRecord.Id == ACP_1_RECORD_ID 
                    && 'yyy'.equals(updatedRecord.Offer_Condition__c)) {
                IsAcp1ConditionUpdated = true;
            }
            if (updatedRecord.Id == ACP_2_RECORD_ID 
                    && 'zzz'.equals(updatedRecord.Offer_Condition__c)) {
                IsAcp2ConditionUpdated = true;
            }
        }
        System.assertEquals(true, IsAcp1ConditionUpdated, 
            'Expected ACP 1 Offer condition to be updated correctly.'
        );
        System.assertEquals(true, IsAcp2ConditionUpdated, 
            'Expected ACP 2 Offer condition to be updated correctly.'
        );
    }

    private class ACPSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes selectById is called
            Set<Id> recordIds =  (Set<Id>) listOfArgs[0];  // first parameter
            List<Application_Course_Preference__c> acpQueryResults = new List<Application_Course_Preference__c>();
            
            if (recordIds.contains(ACP_1_RECORD_ID)) {
                acpQueryResults.add(generateAcp(ACP_1_RECORD_ID, 'Condition 1'));
            }
            if (recordIds.contains(ACP_2_RECORD_ID)) {
                acpQueryResults.add(generateAcp(ACP_2_RECORD_ID, 'Condition 2'));
            }
            
            return acpQueryResults;
        }
    }

    private static Application_Course_Preference__c generateAcp(Id acpId, String offerCondition) {
        String acpRecord = 
            '{"attributes":{"type":"Application_Course_Preference__c"}, '
            + '"id":"' + acpId + '", '
            + '"Offer_Condition__c":"' + offerCondition + '"'
            + '}';
        /*
        We don't care about the rest of the fields as they are not required
        for unit testing this class
        */
        return (Application_Course_Preference__c) JSON.deserialize(
            acpRecord, Application_Course_Preference__c.class
        );
    }

}