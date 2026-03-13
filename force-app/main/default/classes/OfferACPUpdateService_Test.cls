/**
 * @description Test class for OfferACPUpdateService
 */
@isTest
public class OfferACPUpdateService_Test {
    
    private static List<MirrorClauseServices.MirrorClauseWrapper> getMirrorClause(List<Application_Course_Preference__c> acps){
        List<MirrorClauseServices.MirrorClauseWrapper> clauseWrapperList = new List<MirrorClauseServices.MirrorClauseWrapper>();
        for(Application_Course_Preference__c acp: acps){
            MirrorClauseServices.MirrorClauseWrapper mirrorClause = new MirrorClauseServices.MirrorClauseWrapper();
            mirrorClause.clauses = new List<Mirror_Clause__c>();
            clauseWrapperList.add(mirrorClause);
        }
        return clauseWrapperList;
    }
    private static OfferWizardWrapper getOfferWizardWrapper(Opportunity opp, List<MirrorClauseServices.MirrorClauseWrapper> mirrorClause, List<Application_Course_Preference__c> acps){
        OfferWizardWrapper wrapper = new OfferWizardWrapper();
        wrapper.opptyRecord = opp;
        wrapper.selectedACPList = acps;
        wrapper.additionalProducts = new List<PricebookEntry>();
        wrapper.selectedClauses = mirrorClause;
        wrapper.courseOfferingByAcpId = new Map<String, Course_Offering__c>();
        wrapper.additionalACPClauses = new Map<String, String>();
        return wrapper;
    }
    @isTest
    static void test_OfferACPUpdateService(){
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        Course_Offering__c co = (Course_Offering__c) JSON.deserialize('{"attributes":{"type":"Course_Offering__c"}, "Id": "a305P000000KurlQAC"}', Course_Offering__c.class);
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Course_Offering__c" : "a305P000000KurlQAD", "Name":"ACP-0001", "Course_Code__c": "E6001", "Course_Product_ID__c": "E6001_MAEMATS02"}';

        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OfferWizardWrapper offerWizard = getOfferWizardWrapper(null, getMirrorClause(acpList), acpList) ;
        offerWizard.updatedACPs = new Map<ID,Application_Course_Preference__c>{acp.Id => acp};
        offerWizard.courseOfferingByAcpId = new Map<String,Course_Offering__c>{
            acp.id => co
        };
        OfferACPUpdateService acpService = new OfferACPUpdateService( offerWizard );
        acpService.execute();
        System.assert(acpService.acps.values()[0].Deferred_Course_Offering__c == co.Id, 'Deferred Course Offering should be populated');
        acpService.acpDao = new SObjectDaoMock();
        acpService.commitAll();
    }

    @isTest
    static void shouldSetDeferralStatusWhenOriginalOppStageIsInReview() {
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        Course_Offering__c co = (Course_Offering__c) JSON.deserialize('{"attributes":{"type":"Course_Offering__c"}, "Id": "a305P000000KurlQAC"}', Course_Offering__c.class);
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Course_Offering__c" : "a305P000000KurlQAD", "Name":"ACP-0001", "Course_Code__c": "E6001", "Course_Product_ID__c": "E6001_MAEMATS02"}';

        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OfferWizardWrapper offerWizard = getOfferWizardWrapper(null, getMirrorClause(acpList), acpList) ;
        offerWizard.updatedACPs = new Map<ID,Application_Course_Preference__c>{acp.Id => acp};
        offerWizard.courseOfferingByAcpId = new Map<String,Course_Offering__c>{
            acp.id => co
        };
        // Create a fake OpptyRecord
        String opportunityJsonstring = '{"attributes":{"type":"Opportunity"}, "Id": "' 
            + FakeRecordIdGenerator.generateId(Opportunity.getSObjectType()) + '",' 
            + '"Original_Offer__c": "' + FakeRecordIdGenerator.generateId(Opportunity.getSObjectType()) 
            + '"}';
        offerWizard.opptyRecord = (Opportunity) JSON.deserialize(opportunityJsonstring, Opportunity.class);
        
        Test.startTest();
        OfferACPUpdateService acpService = new OfferACPUpdateService( offerWizard );
        acpService.opportunitiesSelector =  (OpportunitiesSelector) Test.createStub(
            OpportunitiesSelector.class, new ReviewOfferOpportunitiesSelectorStub());
        acpService.execute();
        System.assertEquals(
            'APPROVED-ADM_OFFER_DFRMNT_STATUS', 
            acpService.acps.values()[0].Deferment_Status_LOV__r.Unique_Key__c, 
            'Deferment Status should be approved for opportunity Review Offer stage');
        System.assertNotEquals( null,   
                acpService.acps.values()[0].Actual_Offer_Response_Date__c, 
                'Actual Offer Response Date must be set');
        Test.stopTest();
    }

    @isTest
    static void shouldSetDeferralStatusWhenOriginalOppStageIsPublish() {
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        Course_Offering__c co = (Course_Offering__c) JSON.deserialize('{"attributes":{"type":"Course_Offering__c"}, "Id": "a305P000000KurlQAC"}', Course_Offering__c.class);
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Course_Offering__c" : "a305P000000KurlQAD", "Name":"ACP-0001", "Course_Code__c": "E6001", "Course_Product_ID__c": "E6001_MAEMATS02"}';

        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OfferWizardWrapper offerWizard = getOfferWizardWrapper(null, getMirrorClause(acpList), acpList) ;
        offerWizard.updatedACPs = new Map<ID,Application_Course_Preference__c>{acp.Id => acp};
        offerWizard.courseOfferingByAcpId = new Map<String,Course_Offering__c>{
            acp.id => co
        };
        // Create a fake OpptyRecord
        String opportunityJsonstring = '{"attributes":{"type":"Opportunity"}, "Id": "' 
            + FakeRecordIdGenerator.generateId(Opportunity.getSObjectType()) + '",' 
            + '"Original_Offer__c": "' + FakeRecordIdGenerator.generateId(Opportunity.getSObjectType()) 
            + '"}';
        offerWizard.opptyRecord = (Opportunity) JSON.deserialize(opportunityJsonstring, Opportunity.class);
        
        Test.startTest();
        OfferACPUpdateService acpService = new OfferACPUpdateService( offerWizard );
        acpService.opportunitiesSelector =  (OpportunitiesSelector) Test.createStub(
            OpportunitiesSelector.class, new PublishOpportunitiesSelectorStub());
        acpService.execute();
        System.assertEquals(
            'APPROVED-ADM_OFFER_DFRMNT_STATUS', 
            acpService.acps.values()[0].Deferment_Status_LOV__r.Unique_Key__c, 
            'Deferment Status should set to approved for original opportunity Publish stage');
        Test.stopTest();
    }

    /**
     * @description Stub for returning an opportunity with stage = Review Offer
     */
    private class ReviewOfferOpportunitiesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method called is selectById
            Opportunity opportunity = new Opportunity(StageName = 'Review Offer');
            return new List<Opportunity>{opportunity};
        }
    }

    /**
     * @description Stub for returning an opportunity with stage = Publish
     */
    private class PublishOpportunitiesSelectorStub implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
            // assumes method called is selectById
            Opportunity opportunity = new Opportunity(StageName = 'Publish');
            return new List<Opportunity>{opportunity};
        }
    }

}