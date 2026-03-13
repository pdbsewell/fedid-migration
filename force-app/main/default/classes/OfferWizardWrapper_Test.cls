/**
 * @File Name          : OfferWizardWrapper_Test.cls
 * @Description        : OfferWizardWrapper test class
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/26/2020, 8:28:36 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/26/2020   jasmin.rudio@monash.edu     Initial Version
**/
@isTest
public class OfferWizardWrapper_Test {
    @isTest
    private static void offerWrapper(){
        Test.startTest();
            OfferWizardWrapper wrapper = new OfferWizardWrapper();
            wrapper.opptyRecord = new Opportunity();
            wrapper.selectedACPList = new List<Application_Course_Preference__c>();
            wrapper.additionalProducts = new List<PricebookEntry>();
            wrapper.selectedClauses = new List<MirrorClauseServices.MirrorClauseWrapper>();
            wrapper.courseOfferingByAcpId = new Map<String, Course_Offering__c>();
            wrapper.additionalACPClauses = new Map<String, String>();
            wrapper.additionalBahasaACPClauses= new Map<String, String>();
            wrapper.bahasaOfferCondition = '';
            System.assert(true,'Wrapper class is valid');
        Test.stopTest();
    }
}