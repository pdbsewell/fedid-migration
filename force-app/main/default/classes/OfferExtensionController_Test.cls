@isTest(isParallel=true)
public class OfferExtensionController_Test {
    @isTest static void test_updateACPOffersLapsedDate_withoutOfferId(){
        OfferExtensionController.updateACPOffersLapsedDate(null);
        System.assert(true,'Expecting the system to by pass process and not throw an error');
    }
    @isTest static void test_syncAcp_success(){
        OfferExtensionController controller = new OfferExtensionController(new ID[]{FakeRecordIdGenerator.generateId(Opportunity.sObjectType)});
		controller.selector = (OpportunitiesSelector) Test.createStub(
            OpportunitiesSelector.class, 
            new OpportunitiesSelectorMock()
        );
        controller.acpDao = new SObjectDaoMock();
        controller.execute();
        System.assertEquals(
            controller.offers.values()[0].Offer_Extension_Date__c, 
            controller.acps.values()[0].Offer_Response_Date__c,
            'Expecting the date to be in sync');
    }
    
    private class OpportunitiesSelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
                
            return (Opportunity[]) JSON.deserialize('[{"attributes":{"type":"Opportunity","url":"/services/data/v49.0/sobjects/Opportunity/0064Y000002AL93QAG"},"Name":"Morty Smith-A6024-2020-07-26", "Offer_Extension_Date__c":"2025-07-12","StageName":"Signed","PrimaryContact__c":"0034Y00000310h3QAA","Agent_Account__c":"0014Y000003nfuaQAA","Id":"0064Y000002AL93QAG","RecordTypeId":"0124a0000004JuIAAU","OpportunityLineItems":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"OpportunityLineItem","url":"/services/data/v49.0/sobjects/OpportunityLineItem/00k4Y0000033PhsQAE"},"OpportunityId":"0064Y000002AL93QAG","Id":"00k4Y0000033PhsQAE","Application_Course_Preference__c":"a204Y0000009jKGQAY","Override_Start_Date__c":"2020-07-26","Override_End_Date__c":"2022-06-29","Override_Duration__c":"2.0 Year(s)","PricebookEntryId":"01u4a000000YTxdAAG","Product2Id":"01t4a000000EamAAAS","PricebookEntry":{"attributes":{"type":"PricebookEntry","url":"/services/data/v49.0/sobjects/PricebookEntry/01u4a000000YTxdAAG"},"Id":"01u4a000000YTxdAAG","Pricebook2Id":"01s4a0000000HnhAAE","Product2Id":"01t4a000000EamAAAS","Product2":{"attributes":{"type":"Product2","url":"/services/data/v49.0/sobjects/Product2/01t4a000000EamAAAS"},"Id":"01t4a000000EamAAAS","Product_Bundle__c":"01t4a000000EacRAAS","RecordTypeId":"0124a0000004JuJAAU"}},"Application_Course_Preference__r":{"attributes":{"type":"Application_Course_Preference__c","url":"/services/data/v49.0/sobjects/Application_Course_Preference__c/a204Y0000009jKGQAY"},"Id":"a204Y0000009jKGQAY","Course_Code__c":"A6024","Location_Code__c":"CLAYTON","Attendance_Type__c":"FT","Attendance_Mode__c":"IN","Admission_Category__c":"UG-IS","Unit_Set_Code__c":"KCUFSOUT01","Course_Offering__c":"a2B4Y0000001GZoUAM","Admission_Calendar_Type__c":"ADM-2","Academic_CI_Sequence_Number__c":9117,"Admission_CI_Sequence_Number__c":9154,"Course_Version_Number__c":1,"Unit_Set_Version__c":1,"ACP_ID__c":"ACP-1901528","Course_Title__c":"Master of Interpreting and Translation Studies (Double Masters International)","Commencement_Period__c":"2020 Semester 2 (June - July start, varies by course)","Name":"A6024/KCUFSOUT01/CLAYTON","Course_Start_Date_Updated__c":"2020-07-20","Course_End_Date_Updated__c":"2021-07-24","Application__c":"a244Y0000001GRyQAM","Outcome_Status_LOV__c":"a3m4Y00000002PTQAY","Offer_Response_Date__c":"2020-10-27","Course_Product_Id__c":"A6024_KCUFSOUT01","ACP_Url__c":"/lightning/r/Application_Course_Preference__c/a204Y0000009jKG/view","Course_Offering__r":{"attributes":{"type":"Course_Offering__c","url":"/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id":"a2B4Y0000001GZoUAM","Citizenship_Type__c":"INT-TEP","Start_Date__c":"2020-07-26","End_Date__c":"2022-06-29","Commencement_Period__c":"Semester 2  (July start)","Academic_Year__c":2020},"Application__r":{"attributes":{"type":"Application__c","url":"/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id":"a244Y0000001GRyQAM","Agent__c":"0014Y000003nfuaQAA"},"Outcome_Status_LOV__r":{"attributes":{"type":"List_of_Values__c","url":"/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id":"a3m4Y00000002PTQAY","System_Code__c":"OFFER"}},"Product2":{"attributes":{"type":"Product2","url":"/services/data/v49.0/sobjects/Product2/01t4a000000EamAAAS"},"Id":"01t4a000000EamAAAS","Family":"Course","RecordTypeId":"0124a0000004JuJAAU"}}]},"PrimaryContact__r":{"attributes":{"type":"Contact","url":"/services/data/v49.0/sobjects/Contact/0034Y00000310h3QAA"},"Id":"0034Y00000310h3QAA","Name":"Morty Smith","RecordTypeId":"01228000000Px7XAAS"},"Agent_Account__r":{"attributes":{"type":"Account","url":"/services/data/v49.0/sobjects/Account/0014Y000003nfuaQAA"},"Id":"0014Y000003nfuaQAA","RecordTypeId":"01228000000TZDgAAO"}}]', List<Opportunity>.class);
        }

    }
}