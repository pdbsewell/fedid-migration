/**
* @description This class set up managed clauses relevant to the quote line/quote base on a set of criteria defined by the business.
* @author David Browaeys
* @group Offer
**/ 
public inherited sharing class OfferClauseService{ 
    /********VARIABLES**********/
    @TestVisible private Map<String,APXT_Redlining__Managed_Clause__c> managedClausesToLink;
    @TestVisible private List<SBQQ__QuoteLine__c> quoteLinesList; 
    @TestVisible private List<APXT_Redlining__Clause__c> allClauses;
    @TestVisible private Map<ID, Clause_Filtering_Criteria__c> criteriaInError; 
    @TestVisible private Map<Id,SBQQ__Quote__c> quotes;
    @TestVisible private Group[] techQueue {get {
        if ( techQueue == null ){
            techQueue = [SELECT Id, Name, Type 
                        FROM    Group 
                        WHERE   Type = 'Queue'
                        AND     DeveloperName =: Constants.TECHNICAL_OFFER_QUEUE
                        LIMIT 1];
        }
        return techQueue;
    } private set;}
    /********CONSTRUCTORS**********/
    public OfferClauseService( List<SBQQ__QuoteLine__c> quoteLines ){
        this.quoteLinesList = quoteLines;
        this.managedClausesToLink = new Map<String,APXT_Redlining__Managed_Clause__c>();
        this.criteriaInError = new Map<ID, Clause_Filtering_Criteria__c>();
        this.quotes = new Map<Id,SBQQ__Quote__c>();
    }         
    public void execute(){
        allClauses = new ClausesSelector().selectAllWithCriteriaBySelectionType('Auto');
        Group[] techQueue;
        for(SBQQ__QuoteLine__c ql:quoteLinesList){
            if(quotes.get(ql.SBQQ__Quote__c) != null && quotes.get(ql.SBQQ__Quote__c).Sub_Status__c == 'Offer creation/update error'){  //is the quote already in error ? 
                continue;
            }        
            try { 
                for (APXT_Redlining__Clause__c clause : allClauses){    //evaluate clause 
                    if (clause.Object_Level__c == 'SBQQ__Quote__c' || clause.Object_Level__c == 'SBQQ__QuoteLine__c') {
                        evaluateClause(clause, ql);     
                    }
                }
            }catch(Exception err){  //something wrong report it to the clause and send to 
                sendQuoteToTechError(ql,err.getMessage());
            }
        }
        commitAll();
    }
	/**
	 * @description This method attached specific clause to quote and quote line base on specific clause filtering criteria 
	 * @param clause a clause to evaluate
	 * @param ql quote line to evaluate
	 **/
    @TestVisible private void evaluateClause(APXT_Redlining__Clause__c clause, SBQQ__QuoteLine__c ql){          
        if (clause.Always_Display__c || 
            clause.Filtering_Criteria__r == null || 
            clause.Filtering_Criteria__r.isEmpty() == true || 
            evaluateClauseCriteria(clause.Filtering_Criteria__r, ql) == true){
            //Set the managed clause field values
            String key = clause.Object_Level__c == 'SBQQ__QuoteLine__c' ? (String.valueOf(clause.Id) + String.valueOf(ql.Application_Course_Preference__c)) : (String.valueOf(clause.Id) + String.valueOf(clause.Location_In_Offer__c));
            this.managedClausesToLink.put(key,new APXT_Redlining__Managed_Clause__c(
                SBQQ_Quote__c = ql.SBQQ__Quote__c,
                APXT_Redlining__Clause_Revision__c = clause.APXT_Redlining__Latest_Revision__c, 
                APXT_Redlining__Latest_Revision_Text__c = clause.APXT_Redlining__Text__c,
                SBQQ_QuoteLine__c = clause.Object_Level__c == 'SBQQ__QuoteLine__c' ? ql.SBQQ__RequiredBy__c : null
            ));
            SBQQ__Quote__c q = quotes.get(ql.SBQQ__Quote__c);
            if (q == null) {
                q = new SBQQ__Quote__c(Id = ql.SBQQ__Quote__c, Sub_Status__c = 'Auto Clauses Attached');
            }
            //SET COURSE FEE REVIEW FLAG IN QUOTE
            if(clause.Clause_Review_Required__c	== true && q.Clauses_Review_Required__c == false){
                q.Clauses_Review_Required__c = true;
            }
            this.quotes.put(ql.SBQQ__Quote__c, q);
        }
        
    }
	/**
	 * @description This method process and evaluate a specific set of criteria of a clause to a quote line 
	 * @param criterias list of clause filtering criteria to evaluate
	 * @param ql quote line to evaluate
	 **/
    @TestVisible private Boolean evaluateClauseCriteria(Clause_Filtering_Criteria__c[] criterias, SBQQ__QuoteLine__c ql){
        for (Clause_Filtering_Criteria__c criteria : criterias){
            try{
                if (criteriaInError.get(criteria.Id) != null || CriteriaEvaluator.isMeetingCriteria(ql,criteria.Field__c,criteria.Filtered_Value__c,criteria.Operator__c) == false){
                    return false;
                }
            }catch(Exception e){    //something went wrong with a criteria and record must be reviewed by business
                criteria.System_Log__c = e.getMessage();
                criteria.In_Error__c = true;
                criteriaInError.put(criteria.Id,criteria);
                return false;
            }
        }
        return true;
    }
	/**
	 * @description This method send quote to tech queue as something went wrong during evaluation
	 * @param ql quote line to throw an error
	 * @param error error message that was encountered
	 **/
    @TestVisible private void sendQuoteToTechError(SBQQ__QuoteLine__c ql, String error){
        this.quotes.put(ql.SBQQ__Quote__c,
            new SBQQ__Quote__c(
                Id = ql.SBQQ__Quote__c, Sub_Status__c = 'Offer creation/update error',
                Sub_status_changed_on__c = system.now(),
                Error_Log__c = 'Technical error adding clauses to quote. ' + error,
                OwnerId = techQueue[0].Id
            )
        );
    }
	
	/**
	 * @description perform all dml statements for managed clause, oppties, quotes, criteria in error
	 **/
    @TestVisible private void commitAll(){
        //insert managed clause
        List<APXT_Redlining__Managed_Clause__c> t2 = managedClausesToLink.values();
        Database.SaveResult[] result2 = Database.insert(t2, false);
        for (Integer i = 0 ; i < t2.size(); i++){
            if (result2[i].isSuccess() == false) LogUtilityException.addLogEvent('APXT_Redlining__Managed_Clause__c',t2[i],result2[i].getErrors(),'Quote Managed Clause Calc');
        }
                
        // update opp with errors
        List<Opportunity> oppErrs = new List<Opportunity>();
        List<SBQQ__Quote__c> t1 = quotes.values();
        for (Integer i = 0 ; i < t1.size(); i++){
            if (t1[i].Sub_Status__c == 'Offer creation/update error') oppErrs.add(new Opportunity(id = t1[i].SBQQ__Opportunity2__c, StageName = 'Specialist Review', NextStep = ''));
        }
        Database.SaveResult[] resultOpps = Database.update(oppErrs, false);
        
        // update quote back
        SBQQ.TriggerControl.disable();
        Database.SaveResult[] result1 = Database.update(t1, false);
        SBQQ.TriggerControl.enable();
        for (Integer i = 0 ; i < t1.size(); i++){
            if (result1[i].isSuccess() == false) LogUtilityException.addLogEvent('SBQQ__Quote__c',t1[i],result1[i].getErrors(),'Quote Managed Clause Calc');
        }
        Database.update(criteriaInError.values(),false);
    }
}