/**
 * @author			David Browaeys
 * @description		Trigger Handler for Conga Clause Trigger
 * @group Clauses
 */
public with sharing class ClauseTriggerHandler {
    /**
     * @decription Sync Conga Clause with a Mirror Clause
     * @group Clauses
     */
    public class ClauseUpsert extends TriggerAbstract { 
        Mirror_Clause__c[] mirrors = new Mirror_Clause__c[0];
        Set<ID> clauseids = new Set<ID>();
        public override void process(SObject rec) {
            process(rec,null);
        }
        public override void process(SObject rec, Sobject oldRec) {
            APXT_Redlining__Clause__c clause = (APXT_Redlining__Clause__c) rec;
            if (clause.Selection_Type__c == 'Manual' && clause.Object_Level__c == 'SBQQ__QuoteLine__c'){
                clauseids.add(clause.Id);
                records.add(clause);
            }
        }
        public override void execute() {
            Map<ID,String> criteria = new Map<ID,String>();
            for (Clause_Filtering_Criteria__c c : [SELECT Id, Clause__c, Filtered_Value__c FROM Clause_Filtering_Criteria__c WHERE Clause__c IN :clauseids AND Field__c = 'Application_Course_Preference__r.Course_Code__c']){
                String val = criteria.get(c.Clause__c); 
                criteria.put(c.Clause__c, (val != null ? (val + c.Filtered_Value__c + ',') : c.Filtered_Value__c));
            }
            for (APXT_Redlining__Clause__c clause : (APXT_Redlining__Clause__c[]) records){
                this.mirrors.add(new Mirror_Clause__c(
                    Clause__c = clause.Id,
                    External_ID__c = clause.Id,
                    Name = clause.Name, 
                    Notes__c = clause.Notes__c,
                    Text__c = clause.APXT_Redlining__Text__c,
                    Keywords__c = criteria.get(clause.Id)
                ));
            }
            upsert this.mirrors External_ID__c;
        }
    }
    /**
     * @decription Delete Mirror Clause when Conga Clause is deleted
     * @group Clauses
     */
    public class ClauseDelete extends TriggerAbstract { 
        private ID[] clauseIds = new ID[0];
        public override void process(SObject rec) {
            clauseIds.add(rec.Id);
        }
        public override void execute() {
            delete [SELECT ID FROM Mirror_Clause__c WHERE External_ID__c IN: clauseIds];
        }
    }
}