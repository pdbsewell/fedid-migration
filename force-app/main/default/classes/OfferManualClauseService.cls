/**
* @description This class add manual clause to quote from assessor associated clause selection. 
* @author David Browaeys
* @group Offer
**/ 
public with sharing class OfferManualClauseService {
    Associated_Clause__c[] clauses;
    SBQQ__QuoteLine__c[] lines;
    SBQQ__Quote__c quote;
    public Map<String, APXT_Redlining__Managed_Clause__c> managedClausesToLink {get; set;}
    public OfferManualClauseService(Associated_Clause__c[] clauses, SBQQ__Quote__c quote, SBQQ__QuoteLine__c[] lines) {
        this.clauses = clauses;
        this.quote = quote;
        this.lines = lines;
    }
    public OfferManualClauseService execute(){
        this.managedClausesToLink = new Map<String, APXT_Redlining__Managed_Clause__c>();
        for (SBQQ__QuoteLine__c ql : this.lines){
            if (ql.Application_Course_Preference__c != null){      
                for (Associated_Clause__c c : clauses){
                    String key = c.Clause__c + '_' + ql.Application_Course_Preference__c;
                    
                    if (ql.SBQQ__RequiredBy__c != null && ql.Application_Course_Preference__c == c.ACP__c && this.managedClausesToLink.get(key) == null){
                        this.managedClausesToLink.put(key, new APXT_Redlining__Managed_Clause__c(
                            SBQQ_Quote__c = this.quote.Id,
                            APXT_Redlining__Clause_Revision__c = c.Clause__r.APXT_Redlining__Latest_Revision__c, 
                            APXT_Redlining__Latest_Revision_Text__c = c.Clause__r.APXT_Redlining__Text__c,
                            SBQQ_QuoteLine__c = c.Clause__r.Object_Level__c == 'SBQQ__QuoteLine__c' ? ql.SBQQ__RequiredBy__c : null
                        ));

                        //SET COURSE FEE REVIEW FLAG IN QUOTE
                        if(c.Clause__r.Clause_Review_Required__c	== true && this.quote.Clauses_Review_Required__c == false){
                            this.quote.Clauses_Review_Required__c = true;
                        }
                    }
                }
            }
        }
        return this;
    }
    public Boolean commitAll(){
        Boolean valid = true;
        List<APXT_Redlining__Managed_Clause__c> t = this.managedClausesToLink.values();
        Database.SaveResult[] result = Database.insert(t, false);
        for (Integer i = 0 ; i < t.size(); i++){
            if (result[i].isSuccess() == false){
                LogUtilityException.addLogEvent('APXT_Redlining__Managed_Clause__c',t[i],result[i].getErrors(),'Manual Clause Gen');
                valid = false;
            }
        }
        return valid;
    }
}