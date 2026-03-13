/**
 * @File Name          : OpportunityLineItemService_Test.cls
 * @Description        : 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/26/2020, 6:58:22 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/26/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest(isParallel=true)
public with sharing class OpportunityLineItemService_Test {
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
        wrapper.additionalBahasaACPClauses = new Map<String, String>();
        return wrapper;
    }

    @isTest
    static void shouldMatchPricebookEntryByForUsualBachDegreesWithOnlyCourseCode() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';

        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Code__c": "F20031", "Course_Product_ID__c": "F20031", "Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';

        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
            Application_Course_Preference__c.class);
        acpList.add(acp);
        
        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator(
                getOfferWizardWrapper(opp, getMirrorClause(acpList), acpList)
            );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new priceBookEntrySelectorMock()
            );
        oppLineItemCreator.pricebook = new Pricebook2(Name = 'International', 
            Description = 'International', IsActive = true 
        );
        oppLineItemCreator.convertAcpsToOppLineItems();

        System.assertEquals(oppLineItemCreator.oppLineList[0].UnitPrice, 31, 
            'Expected the prices returned to match based on usual degrees ' 
            + 'where they do not have unit sets.'
        );
    }

    @isTest
    static void testGrantOpportunityLineItemCreation() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';
        opp.Pricebook2 = new Pricebook2(External_ID__c = 'AU_INT');
        
        OfferWizardWrapper wrapper = getOfferWizardWrapper(opp, null, null);
        wrapper.additionalProducts = (List<PricebookEntry>) JSON.deserialize('[{"attributes": {"type": "PricebookEntry","url": "/services/data/v49.0/sobjects/PricebookEntry/01u4a000000YU98AAG"},"Id": "01u4a000000YU98AAG","Name": "MEB Subsidy - Faculty of Engineering - Master of Professinal Engineering","Pricebook2Id": "01s4a0000000HnhAAE","Product2Id": "01t4a000000EaqRAAS","UnitPrice": -8551.00,"IsActive": true,"UseStandardPrice": false,"CreatedDate": "2020-04-04T00:36:18.000+0000","CreatedById": "0054a000000K7dGAAS","LastModifiedDate": "2020-06-08T23:45:02.000+0000","LastModifiedById": "0054Y000000WKZGQA4","SystemModstamp": "2020-06-08T23:45:02.000+0000","ProductCode": "Grant20200200-168","IsDeleted": false,"IsArchived": false,"External_ID__c": "00D5P0000008aiy_01u5P000000acmoQAA","Product_Name__c": "MEB Subsidy - Faculty of Engineering - Master of Professinal Engineering"}]', List<PricebookEntry>.class);
        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator(
                wrapper
            );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new priceBookEntrySelectorMock()
            );
         oppLineItemCreator.pricebook = new Pricebook2(Name = 'International', 
            Description = 'International', IsActive = true 
        );
        oppLineItemCreator.execute();

        System.assertEquals(oppLineItemCreator.oppLineList[0].UnitPrice, -8551.00, 
            'Expected the prices returned to match based on usual degrees ' 
            + 'where they do not have unit sets.'
        );
    }


    @isTest
    static void shouldThrowExceptionWhenNoMatchingPricebookEntryIsFoundForOnlyCourseCode() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Code__c": "DNF999", "Course_Product_ID__c": "DNF999","Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';
        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
            Application_Course_Preference__c.class);
        acpList.add(acp);

        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator(
                //opp, acpList, new List<PricebookEntry>()
                getOfferWizardWrapper(opp, getMirrorClause(acpList), acpList)
            );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new priceBookEntrySelectorMock()
            );
        oppLineItemCreator.pricebook = new Pricebook2(Name = 'International', 
            Description = 'International', IsActive = true 
        );
        
        try {
            oppLineItemCreator.convertAcpsToOppLineItems();
            System.assert(false, 
                'Expected exception because there is no matching course product Id'
            );
        } catch (Exception e) {
            System.assert(true, 
                'Expected exception because there is no matching course product Id'
            );
        }
    }

    @isTest
    static void shouldThrowExceptionWhenNoMatchingPricebookEntryIsFoundForOnlyCourseCodeAndUnitSet() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';
        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Code__c": "DNF999", "Course_Product_ID__c": "DNF999_XXX123","Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';
        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator(
                //opp, acpList, new List<PricebookEntry>()
                getOfferWizardWrapper(opp, getMirrorClause(acpList), acpList)
            );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new priceBookEntrySelectorMock()
            );
        oppLineItemCreator.pricebook = new Pricebook2(Name = 'International', 
            Description = 'International', IsActive = true 
        );
        
        try {
            oppLineItemCreator.convertAcpsToOppLineItems();
            System.assert(false, 
                'Expected exception because there is no matching course product Id'
            );
        } catch (Exception e) {
            System.assert(true, 
                'Expected exception because there is no matching course product Id'
            );
        }
    }


    @isTest
    static void shouldMatchPricebookEntryForDiplomaWhenDataExists() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';

        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();
       
        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Code__c": "2607", "Course_Product_ID__c": "2607_MC-BUS-1A","Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';
        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator(
                //opp, acpList, new List<PricebookEntry>()
                getOfferWizardWrapper(opp, getMirrorClause(acpList), acpList)
            );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new PriceBookEntrySelectorMock()
            );
        oppLineItemCreator.pricebook = new Pricebook2(
            Name = 'International', Description = 'International', 
            IsActive = true 
        );
        oppLineItemCreator.convertAcpsToOppLineItems();

        System.assertEquals(oppLineItemCreator.oppLineList[0].UnitPrice, 260799, 
            'Expected price book entry to match for diploma and diploma uses ' +
            ' course code and unit sets'
        );
    }

    @isTest
    static void shouldMatchPricebookEntryUsingFallbackToCourseCodeMatchWhenIsUniCourse() {
        
        Opportunity opp = new Opportunity();
        opp.Id = '0065P000002F33pQAC';

        List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

        String acpString = '{"attributes":{"type":"Application_Course_Preference__c"}, "Id": "a205P000000KurlQAC", "Name":"ACP-0001", "Course_Code__c": "E6001", "Course_Product_ID__c": "E6001_MAEMATS02","Course_Offering__r": {"attributes": {"type": "Course_Offering__c","url": "/services/data/v49.0/sobjects/Course_Offering__c/a2B4Y0000001GZoUAM"},"Id": "a2B4Y0000001GZoUAM","Start_Date__c": "2020-07-26","End_Date__c": "2022-06-29"},"Application__r": {"attributes": {"type": "Application__c","url": "/services/data/v49.0/sobjects/Application__c/a244Y0000001GRyQAM"},"Id": "a244Y0000001GRyQAM","Campus_Location__c": "Australia","Agent__c": "0014Y000003nfuaQAA","Residency_Status__c": "INTRNTNL"},"Outcome_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PTQAY"},"Id": "a3m4Y00000002PTQAY","System_Code__c": "OFFER"}}';
        Application_Course_Preference__c acp = 
            (Application_Course_Preference__c) JSON.deserialize(acpString, 
                Application_Course_Preference__c.class);
        acpList.add(acp);

        OpportunityLineItemService.OppLineItemCreator oppLineItemCreator = 
            new OpportunityLineItemService.OppLineItemCreator( getOfferWizardWrapper(opp, getMirrorClause(acpList), acpList) );
        oppLineItemCreator.priceBookEntrySelector = 
            (PriceBookEntriesSelector) Test.createStub(
                PriceBookEntriesSelector.class, new PriceBookEntrySelectorMock()
            );
        oppLineItemCreator.pricebook = new Pricebook2(Name = 'International', 
            Description = 'International', IsActive = true 
        );
        oppLineItemCreator.convertAcpsToOppLineItems();

        System.assertEquals(oppLineItemCreator.oppLineList[0].UnitPrice, 6001, 
            'Expect a match using the fallback logic for a uni course that has '
            + ' a course code and unit set, but product only exists for the ' 
            + 'course code.'
        );
    }


    private class PriceBookEntrySelectorMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {
                
            // Map<String, PricebookEntry> selectByProduct2ExternalId(string pbId, Set<String> productIds)
            if ('selectPricebook2ByExtId'.equals(stubbedMethodName)) {
                String pricebook2ExtId = (String) listOfArgs[0];
                if (pricebook2ExtId == 'AU_INT') {
                    return (Pricebook2) JSON.deserialize('{"attributes":{"type":"Pricebook2","url":"/services/data/v49.0/sobjects/Pricebook2/01s4a0000000HnhAAE"},"Id":"01s4a0000000HnhAAE"}', Pricebook2.class);
                }
            }
            if ('selectByProduct2ExternalId'.equals(stubbedMethodName)) {
                if (!listOfArgs.isEmpty()) {
                    Map<String, PricebookEntry> queryResult = new Map<String, PricebookEntry>();

                    // get second parameter,. we're only interested in productIds for unit testing purposes
                    Set<String> productIdsArg = (Set<String>) listOfArgs[1];
                    if (productIdsArg.contains('F20031')) {
                        String pricebookEntry1String = '{"attributes":{"type":"PricebookEntry"},"Id":"01u5P000000aOWeQAM","Name":"Diploma x","UnitPrice":31,"Product2":{"attributes":{"type":"Product2"},"External_Id__c":"F20031","Product_Bundle__c":"a1u5P000000aOWeQAM","Product_Bundle__r":{"attributes":{"type":"Product2"},"ProductCode":"BUNUNI"}}}';
                        PricebookEntry pricebookEntry1 = 
                            (PricebookEntry) JSON.deserialize(
                                pricebookEntry1String, 
                                PricebookEntry.class
                            );
                        queryResult.put('F20031', pricebookEntry1);
                    }
                    if (productIdsArg.contains('2607_MC-BUS-1A')) {
                        String pricebookEntry2String = '{"attributes":{"type":"PricebookEntry"},"Id":"01u5P000000aOWeQAM","Name":"Diploma x","UnitPrice":260799,"Product2":{"attributes":{"type":"Product2"},"External_Id__c":"2607_MC-BUS-1A","Product_Bundle__c":"a1u5P000000aOWeQA1", "Product_Bundle__r":{"attributes":{"type":"Product2"},"ProductCode":"BUNDIP"}}}';
                        PricebookEntry pricebookEntry2 = (PricebookEntry) JSON.deserialize(pricebookEntry2String, PricebookEntry.class);
                        queryResult.put('2607_MC-BUS-1A', pricebookEntry2);
                    }
                    if (productIdsArg.contains('2607')) {
                        String pricebookEntry3String = '{"attributes":{"type":"PricebookEntry"},"Id":"01u5P000000aOWeQAM","Name":"Diploma x","UnitPrice":2607,"Product2":{"attributes":{"type":"Product2"},"External_Id__c":"2607","Product_Bundle__c":"a1u5P000000aOWeQA1", "Product_Bundle__r":{"attributes":{"type":"Product2"},"ProductCode":"BUNDIP"}}}';
                        PricebookEntry pricebookEntry3 = (PricebookEntry) JSON.deserialize(pricebookEntry3String, PricebookEntry.class);
                        queryResult.put('2607', pricebookEntry3);
                    }
                    if (productIdsArg.contains('E6001')) {
                        String pricebookEntry4String = '{"attributes":{"type":"PricebookEntry"},"Id":"01u5P000000aOWeQAM","Name":"Master of x","UnitPrice":6001,"Product2":{"attributes":{"type":"Product2"},"External_Id__c":"E6001","Product_Bundle__c":"a1u5P000000aOWeQAM", "Product_Bundle__r":{"attributes":{"type":"Product2"},"ProductCode":"BUNUNI"}}}';
                        PricebookEntry pricebookEntry4 = (PricebookEntry) JSON.deserialize(pricebookEntry4String, PricebookEntry.class);
                        queryResult.put('E6001', pricebookEntry4);
                    }
                    return queryResult;
                }
            }
            return null;
        }

    }
}