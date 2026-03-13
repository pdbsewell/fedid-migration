@isTest(isParallel=true)
public with sharing class OfferACPProcessPostSignature_Test {
    @isTest static void test_postOfferSignatureACPUpdates(){
        OfferACPProcessPostSignature.postOfferSignatureACPUpdates(null);
        System.assert(true,'No update expected here');
    }
    @isTest static void shouldUpdateACPDefermentStatustoAccepted(){
        String opptyString = '[{"attributes": {"type": "Opportunity","url": "/services/data/v49.0/sobjects/Opportunity/0064Y0000029rzLQAQ"},"Id": "0064Y0000029rzLQAQ","Original_Offer__c":"0064Y0000028rzLQAP","StageName": "Signed","CloseDate": "2020-06-15","IsClosed": true,"OpportunityLineItems": {"totalSize": 1,"done": true,"records": [{"attributes": {"type": "OpportunityLineItem","url": "/services/data/v49.0/sobjects/OpportunityLineItem/00k4Y0000033KaWQAU"},"OpportunityId": "0064Y0000029rzLQAQ","Id": "00k4Y0000033KaWQAU","Application_Course_Preference__c": "a204Y0000009XJNQA2","PricebookEntryId": "01u4a000000YTfKAAW","Application_Course_Preference__r": {"attributes": {"type": "Application_Course_Preference__c","url": "/services/data/v49.0/sobjects/Application_Course_Preference__c/a204Y0000009XJNQA2"},"Id": "a204Y0000009XJNQA2","Deferred_Course_Offering__c": "a2n4Y00000002PrQAI","Deferment_Status_LOV__c": "a3m4Y00000002PrQAI","Deferment_Status_LOV__r": {"attributes": {"type": "List_of_Values__c","url": "/services/data/v49.0/sobjects/List_of_Values__c/a3m4Y00000002PrQAI"},"Id": "a3m4Y00000002PrQAI","Unique_Key__c": "PENDING-ADM_OFFER_DFRMNT_STATUS"}},"PricebookEntry": {"attributes": {"type": "PricebookEntry","url": "/services/data/v49.0/sobjects/PricebookEntry/01u4a000000YTfKAAW"},"Id": "01u4a000000YTfKAAW","Pricebook2Id": "01s4a0000000HnhAAE","Product2Id": "01t4a000000EadPAAS","Product2": {"attributes": {"type": "Product2","url": "/services/data/v49.0/sobjects/Product2/01t4a000000EadPAAS"},"Id": "01t4a000000EadPAAS","Product_Bundle__c": "01t4a000000EacRAAS","RecordTypeId": "0124a0000004JuJAAU"}}}]}}]';

        OfferACPProcessPostSignature.OfferACPProcessPostSignatureService handler = new OfferACPProcessPostSignature.OfferACPProcessPostSignatureService((List<Opportunity>)JSON.deserialize(opptyString, List<Opportunity>.class)).execute();
        System.assert(handler.acps.values()[0].Deferment_Status_LoV__r.Unique_Key__c == 'APPROVED-ADM_OFFER_DFRMNT_STATUS', 'ACP Deferment Status is Accepted');
    }
}