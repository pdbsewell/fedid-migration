/**
 * @File Name          : MirrorClauseServices.cls
 * @Description        : Service layer containing most business logic for Mirror_Clause__c object 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : 
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 5/19/2020, 5:17:12 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/18/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class MirrorClauseServices {
    public MirrorClauseServices() {}

    @AuraEnabled(cacheable=false)
    public static String getManualClauses(String selectedACPjson){
        List<Application_Course_Preference__c> acpList = (List<Application_Course_Preference__c>) System.JSON.deserialize(selectedACPjson, List<Application_Course_Preference__c>.class);
        List<MirrorClauseWrapper> clauseWrapperList = new List<MirrorClauseWrapper>();
        List<Mirror_Clause__c> mirrorClauses = new MirrorClauseSelector().selectActiveClauses();
        
        for(Application_Course_Preference__c acp: acpList){
            MirrorClauseWrapper mirrorClause = new MirrorClauseWrapper();
            mirrorClause.clauses = new List<Mirror_Clause__c>();
            for(Mirror_Clause__c clause: mirrorClauses){
                if(clause.Keywords__c <> null && clause.Keywords__c.contains(acp.Course_Code__c)){
                    mirrorClause.clauses.add(clause);
                }
            }
            mirrorClause.parentId = acp.Id;
            mirrorClause.parentName = acp.Name;
            mirrorClause.parentObject = acp;
            clauseWrapperList.add(mirrorClause);
        }
        return JSON.serialize(clauseWrapperList);
    }


    public class MirrorClauseWrapper{
        public String parentId;
        public String parentName;
        public sObject parentObject;
        public List<Mirror_Clause__c> clauses;
        public List<Associated_Clause__c> existingAssociatedClause;
        public MirrorClauseWrapper(){}
    }

}