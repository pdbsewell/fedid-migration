/**
 * @File Name          : AssociatedClauseService.cls
 * @Description        : Service layer containing most business logic for Associated_Clause__c object 
 * @Author             : jasmin.rudio@monash.edu
 * @Group              : Offer
 * @Last Modified By   : jasmin.rudio@monash.edu
 * @Last Modified On   : 07-08-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    5/19/2020   jasmin.rudio@monash.edu     Initial Version
**/
public with sharing class AssociatedClauseService {
    public AssociatedClauseService() {}
    /**
     * method that return Associated Clause related to the Opportunity record
     * @param  oppty parent record - Opportunity 
     * @param  mirrorClauses list of MirrorClauseWrapper
     * @return list of Associated_Clause__c
     */
    public static List<Associated_Clause__c> createAssociatedClause(Opportunity oppty,
                                                                    List<MirrorClauseServices.MirrorClauseWrapper> mirrorClauses){
        return new AssociatedClauseComposer(oppty, mirrorClauses, null, null).execute();
    }

    /**
     * Static method that return Associated Clause related to the selected Bulk Data Processing record
     * @param  bdp parent record - Bulk Data Processing 
     * @param  mirrorClauses list of selected Mirror_Clause__c
     * @return list of Associated_Clause__c
     */
    public static List<Associated_Clause__c> createBDPAssociatedClause(Bulk_Data_Processing__c bdp, List<Mirror_Clause__c> mirrorClauses){
        return new AssociatedClauseComposer(null, null, bdp, mirrorClauses).execute();
    }

    /**
     * Static method that return Associated Clause related based on the parent lookup field
     * @param  parentField API name of a parent object (e.g. Opportunity__c) 
     * @param  parentId record id of a parent object
     * @return list of Associated_Clause__c
     */
    @AuraEnabled(cacheable = true)
    public static List<Associated_Clause__c> getAssocClauseByParentId(String parentField, String parentId){
        return new AssociatedClauseSelector().selectClausesByParentId(parentField, parentId);
    }

    public class AssociatedClauseComposer{
        List<Associated_Clause__c> associatedClauses;
        List<MirrorClauseServices.MirrorClauseWrapper> mirrorClausesWrapper;
        List<Mirror_Clause__c> mirrorClauses;
        Opportunity oppty;
        Bulk_Data_Processing__c bdpRec;

        public AssociatedClauseComposer(Opportunity oppty, 
                                        List<MirrorClauseServices.MirrorClauseWrapper> mirrorClausesWrapper,
                                        Bulk_Data_Processing__c bdp, 
                                        List<Mirror_Clause__c> mirrorClauses){
            this.associatedClauses = new List<Associated_Clause__c>();
            this.mirrorClausesWrapper = mirrorClausesWrapper;
            this.mirrorClauses = mirrorClauses;
            this.oppty = oppty;
            this.bdpRec = bdp;
        }

        public List<Associated_Clause__c> execute(){
            if(this.oppty != null){
                return createAssociatedClause();

            }else if(this.bdpRec != null){
                return createBDPAssociatedClause();
            }

            return new List<Associated_Clause__c>();
        }

        /**
         * method that return Associated Clauses related to the Opportunity record
         * @return list of Associated_Clause__c
         */
        private List<Associated_Clause__c> createAssociatedClause(){
            List<Associated_Clause__c> associatedClauses = new List<Associated_Clause__c>();
            for(MirrorClauseServices.MirrorClauseWrapper clause: this.mirrorClausesWrapper){
                for(Mirror_Clause__c mirror: clause.clauses){
                    Associated_Clause__c assocClause = setValues(mirror, clause);
                    associatedClauses.add(assocClause); 
                }
            }
            return associatedClauses;
        }

        /**
         * method that return Associated Clauses related to the Bulk Processing Data record
         * @return list of Associated_Clause__c
         */
        private List<Associated_Clause__c> createBDPAssociatedClause(){
            Set<String> mirrorClauseIds = new Set<String>();
            List<Associated_Clause__c> associatedClauses = new List<Associated_Clause__c>();
            for(Mirror_Clause__c mirror: this.mirrorClauses){
                Map<String, Associated_Clause__c> assocClauseMap = mapAssocClauseByMirrorId(this.bdpRec.Associated_Clauses__r);
                if(assocClauseMap.isEmpty() || assocClauseMap.get(mirror.Id) == null){
                    Associated_Clause__c assocClause = setValues(mirror, null);
                    associatedClauses.add(assocClause); 
                }
            }
            return associatedClauses;
        }

        /**
         * reusable method that compose Associated Clauses record
         * @return Associated_Clause__c with parent records
         */
        private Associated_Clause__c setValues(Mirror_Clause__c mirror, MirrorClauseServices.MirrorClauseWrapper clauseWrapper){
            Associated_Clause__c assocClause = new Associated_Clause__c();
            assocClause.ACP__c = (clauseWrapper != null ? clauseWrapper.parentId : null);
            assocClause.Clause__c = mirror.Clause__c;
            assocClause.Mirror_Clause__c = mirror.Id;
            assocClause.Opportunity__c = (this.oppty != null ? this.oppty.Id : null);
            assocClause.Offer_Request__c = (this.bdpRec != null ? this.bdpRec.Id : null);

            //relate existing BDP clauses into the new Opportunity in Offer Wizard
            if(clauseWrapper != null && clauseWrapper.existingAssociatedClause != null){
                System.debug('** clauseWrapper: ' + clauseWrapper);
                for(Associated_Clause__c assoc: clauseWrapper.existingAssociatedClause){
                    if(assoc.Mirror_Clause__c == mirror.Id){
                        assocClause.Id = assoc.Id;
                        assocClause.Offer_Request__c = assoc.Offer_Request__c;
                        break;
                    }
                }
            }
            return assocClause;
        }
        
        /**
         * method that return Associated Clause map where Mirror_Clause__c as key
         * @param  clauseList Associated_Clause__c record list
         * @return map of Associated_Clause__c - key: Mirror_Clause__c, value: Associated_Clause__c record
         */
        private Map<String, Associated_Clause__c> mapAssocClauseByMirrorId(Associated_Clause__c[] clauseList){
            Map<String, Associated_Clause__c> assosClauseMap = new Map<String, Associated_Clause__c>();
            for(Associated_Clause__c ac: clauseList){
                assosClauseMap.put(ac.Mirror_Clause__c, ac);
            }
            return assosClauseMap;
        }

    }

    

    
    
}