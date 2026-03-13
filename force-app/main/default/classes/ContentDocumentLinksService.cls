/**
 * @File Name          : ContentDocumentLinksService.cls
 * @Description        : Service layer containing most business logic for Content Document links
 * @Author             : Mathew Jose
 * @Group              : 
 * @Last Modified By   : Mathew Jose
 * @Last Modified On   : 11/12/2019, 11:11:11 AM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    11/12/2019       Mathew Jose             Initial Version
**/
public class ContentDocumentLinksService {
        @testVisible static Boolean testRequireReview = false;
        public inherited sharing class QuoteToOppContentLinkGenerator{ 
        /********VARIABLES**********/
        private Set<ID> cdlIds; 
        private Set<String> quoteIds;
        private ContentDocumentLink[] contentDocuments;
        /********CONSTRUCTORS**********/
        public QuoteToOppContentLinkGenerator(Set<ID> cdlIds, Set<String> quoteIds){
            this.cdlIds = cdlIds;
            this.quoteIds = quoteIds;
        }   
        /**
        * @description service method to link the content document from quote to opportunity
        * @author Mathew Jose
        * @return void
        **/        
        public void execute(){
            if (cdlIds == null || cdlIds.isEmpty()){
                return;
            }
            this.contentDocuments = new ContentDocumentLinksSelector().selectByIdWithEntityType(cdlIds).values();
            cloneContentDocumentLinkForOppty();
        }
        /**
         * revision     03.NOV.2020 - JM Mapanao - Added logic to cater Domestic Offer quote
         */
        public void cloneContentDocumentLinkForOppty(){
            List<ContentDocumentLink> cdlToInsert = new List <ContentDocumentLink>();
            List<Opportunity> opportunities = new List<Opportunity>();
            Map<Id, SBQQ__Quote__c> quoteMap = new QuotesSelector().selectByIdMap(quoteIds);
            for(ContentDocumentLink cdl : contentDocuments){
                if(quoteMap.get(cdl.LinkedEntityId) != null){
                    SBQQ__Quote__c quote = quoteMap.get(cdl.LinkedEntityId);
                    //clone link for opportunity
                    ContentDocumentLink opptyDoc = cdl.clone(false, false);
                    opptyDoc.ShareType = 'I';
                    opptyDoc.LinkedEntityId = quote.SBQQ__Opportunity2__c;
                    cdlToInsert.add(opptyDoc);
                    //Checking if it's the preview
                    if(String.valueOf(cdl.ContentDocument.Title).toLowerCase().contains(quote.Name.toLowerCase())){
                        if((String.valueOf(cdl.ContentDocument.Title).toLowerCase().contains('preview') || quote.Signature_Type__c == 'Wet Signature' || quote.Offer_Category__c == Constants.OPP_OFFERCATEGORY_DOMESTIC_OFFER) && ( quote.Sub_Status__c == 'Preview Requested' || quote.Sub_Status__c == 'Preview in QA' || quote.Sub_Status__c == 'Business request review')){
                            quote.Sub_Status__c = 'Preview in QA';
                            quote.Latest_Preview_Version_Id__c = cdl.ContentDocument.LatestPublishedVersionId;
                            quote.Latest_Preview_Generated_Date__c = Datetime.now();
                            quote.ISCA_Preview_Version_Number__c = quote.ISCA_Preview_Version_Number__c + 1;
                            //update quote
                            if (quote.SBQQ__Primary__c && quote.SBQQ__Opportunity2__r.StageName == 'Processing Offer'){
                                Opportunity opp = quote.SBQQ__Opportunity2__r;
                                opp.Preview_Ready__c = true;
                                opp.StageName = quote.Require_Review__c == true || testRequireReview == true ? 'Specialist Review' : 'Review Offer';
                                opp.NextStep = 'Please review offer preview before publishing, if technical changes are required please request specialist review';
                                opportunities.add(opp);
                            }
                        }else if(quote.SBQQ__Status__c == 'Published' && quote.Sub_Status__c == 'Details completed'){
                            // this is meant for the actual document generated when the student hit Accept.                                        
                            quote.Primary_Document__c = cdl.ContentDocument.LatestPublishedVersionId;
                            quote.Date_Document_Generated__c = Datetime.now();
                        }
                    }
                }
            }
            commitAll(cdlToInsert,opportunities,quoteMap.values());
        }
        public void commitAll( ContentDocumentLink[] cdlToInsert,List<Opportunity> opportunities, SBQQ__Quote__c[] quotes){
            Database.SaveResult[] result1 = Database.insert(cdlToInsert, false);
            for (Integer i = 0 ; i < cdlToInsert.size(); i++){
                if (result1[i].isSuccess() == false) LogUtilityException.addLogEvent('ContentDocumentLink',cdlToInsert[i],result1[i].getErrors(),'ISCA Contract generation on quote'); 
            }           
            SBQQ.TriggerControl.disable();
            Database.SaveResult[] result2 = Database.update(quotes, false);
            for (Integer i = 0 ; i < quotes.size(); i++){
                if (result2[i].isSuccess() == false){
                    LogUtilityException.addLogEvent('SBQQ__Quote__c',quotes[i],result2[i].getErrors(),'ISCA Contract generation on quote'); 
                }
            }
            Database.SaveResult[] result3 = Database.update(opportunities, false);
            for (Integer i = 0 ; i < opportunities.size(); i++){
                if (result3[i].isSuccess() == false) LogUtilityException.addLogEvent('Opportunity',opportunities[i],result3[i].getErrors(),'Opportunity ready for Review'); 
            }    
            
        }
    }
}