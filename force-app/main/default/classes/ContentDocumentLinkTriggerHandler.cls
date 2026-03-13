/**
 * @File Name          : ContentDocumentLinkTriggerHandler.cls
 * @Description        : Service layer containing most business logic for Content Document
 * @Author             : Mathew Jose
 * @Group              : 
 * @Last Modified By   : Mathew Jose
 * @Last Modified On   : 11/12/2019, 11:11:11 AM
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    11/12/2019       Mathew Jose             Initial Version
**/
public class ContentDocumentLinkTriggerHandler {
    public class OpportunityLinkGeneratorForQuoteFiles extends TriggerAbstract { 
        Set<String> quoteIds = new Set<String>();
        Set<ID> cdlIds = new Set<ID>();
        public override void process(SObject rec) {
            ContentDocumentLink record = (ContentDocumentLink) rec;
            if (record.LinkedEntityId.getSobjectType() == SBQQ__Quote__c.getSobjectType()){
                cdlIds.add(record.Id);
                quoteIds.add(record.LinkedEntityId);
            }
        }
        public override void execute() {
            if(!cdlIds.isEmpty() && !quoteIds.isEmpty()){
                new ContentDocumentLinksService.QuoteToOppContentLinkGenerator(cdlIds,quoteIds).execute();
            }
        }
    }
}