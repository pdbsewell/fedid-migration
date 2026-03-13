/**
* @description       : Action Plan Summary for collaborators. 
* @author            : rajesh.punjabi@monash.edu
* @group             : 
* @last modified on  : 04-10-2023
* @last modified by  : rajesh.punjabi@monash.edu
**/
public with sharing class ActionPlanEnquirySummaryController {
    
    /**
    * @description Get all action plan tasks and summarise.
    * @author rajesh.punjabi@monash.edu | 20-09-2023 
    * @param idEnquiryId 
    * @return List<Payload> 
    **/
    @AuraEnabled(cacheable=true)
    public static List<Payload> getActionPlanSummary(String idEnquiryId){
        try{
            Id idAccoutRT_HouseHold = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Household_Account').getRecordTypeId();
            
            List<Case> lstChildEnquiries = [SELECT Id, CaseNumber, Account.Name, Contact.Account.Name, Contact.Account.RecordTypeId, Referral_Group__c,  Enquiry_Type__c, Status, ParentId 
                                            FROM Case 
                                            WHERE ParentId=: idEnquiryId OR Id=:idEnquiryId];
            
            //.. Payload List - Enquiry fields only.
            List<Payload> lstPayload = new List<Payload> ();
            
            //.. Payload List - Enquiry and Action fields.
            List<Payload> lstPayloadwithAP = new List<Payload> ();
            
            //.. Payload List -All fields.
            List<Payload> lstPayloadAllFields = new List<Payload> ();
            
            //.. Set of Enqiury Ids
            Set<Id> setEnquiryIds = new Set<Id>();
            
            //.. Set of Action Plan Ids
            Set<Id> setActionPlanIds = new Set<Id>();
            
            //.. Enqury record with record Id.
            Map<Id, Case> mapEnquiriesWithId = new  Map<Id, Case>();
            
            //.. Enquiry Id and Payload Map
            Map<Id, Payload> mapEnqiuryIdPayload = new Map<Id, Payload>();
            
            //.. AP Id and Payload Map
            Map<Id, Payload> mapAPIdPayload = new Map<Id, Payload>(); 
            
            //.. Get all enquiries including parent enquriy
            for(Case oCase: lstChildEnquiries){
                mapEnquiriesWithId.put(oCase.Id, oCase);
                setEnquiryIds.add(oCase.Id);
            }
            
            Integer iRowCounter = 1;
            for(ActionPlan oAP: getActionPlans(setEnquiryIds)){
                if(mapEnquiriesWithId.containsKey (oAP.TargetId)){                
                    Case oCase = mapEnquiriesWithId.get(oAP.TargetId);
                    Payload oPayload = new Payload();
                    oPayload.rowNumber = iRowCounter;
                    oPayload.recordId = oCase.Id;
                    oPayload.recordIdURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Case/'+ oCase.Id +'/view';
                    oPayload.caseNumber = oCase.CaseNumber;
                    oPayload.accountName = oCase.Account.Name;
                    
                    //.. Set the icon for Parent and Child enquiry receords.
                    oPayload.iconParentChild = 'utility:case';
                    if(String.isBlank(oCase.ParentId)){
                        oPayload.iconParentChild = 'utility:cases';
                    }
                    oPayload.referralGroup = oCase.Referral_Group__c;
                    oPayLoad.actionPlanId = oAP.Id;
                    oPayload.actionPlanIdURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/ActionPlan/'+ oAP.Id +'/view';
                    oPayload.actionPlanName = oAP.Name;
                    oPayload.actionPlanStatus = oAP.ActionPlanState;
                    oPayload.totalTasks = 0;
                    oPayload.pendingTasks = 0;
                    oPayload.completedTasks = 0;
                    oPayload.completedPercentage = '';
                    lstPayloadwithAP.add(oPayload);
                    
                    //.. Action Plan Ids to get related tasks.
                    setActionPlanIds.add(oAP.Id);
                    mapAPIdPayload.put(oAP.Id, oPayload);
                    
                    //.. Total number of action plan records
                    iRowCounter = iRowCounter + 1;
                    oPayload.totalRecords = iRowCounter;
                }
            }
            
            //.. Get all task related to actions plans inlucding count.
            AggregateResult[] groupedResults = [SELECT ActionPlanId, ItemState, Count(Id)
                                                FROM ActionPlanItem
                                                WHERE ActionPlanId IN: setActionPlanIds
                                                AND ItemState != 'Deleted'
                                                GROUP BY ActionPlanId, ItemState];
            
            //.. Filter completed and pending tasks.        
            for (AggregateResult ar : groupedResults)  {            
                if(mapAPIdPayload.containsKey(String.valueOf(ar.get('ActionPlanId')))){
                    Payload oAPPayload = mapAPIdPayload.get(String.valueOf(ar.get('ActionPlanId')));
                    
                    if(ar.get('ItemState') == 'Completed'){
                        oAPPayload.completedTasks = Integer.valueOf(ar.get('expr0')); 
                    }
                    else {
                        oAPPayload.pendingTasks = Integer.valueOf(ar.get('expr0')); 
                    }
                    
                }
            }
            
            //.. Create Summary including task completion percentage.
            for(Payload oPayloadUpdate: mapAPIdPayload.values()){
                oPayloadUpdate.totalTasks = oPayloadUpdate.pendingTasks + oPayloadUpdate.completedTasks;
                if(oPayloadUpdate.totalTasks > 0){
                	Decimal dPercentage = (Decimal) oPayloadUpdate.completedTasks/oPayloadUpdate.totalTasks*100;
                    oPayloadUpdate.completedPercentage = String.valueOf(dPercentage.intValue());
                    lstPayloadAllFields.add(oPayloadUpdate);
                }
            }
            return lstPayloadAllFields;
        }
        catch (Exception e) {
            LogUtilityException.logException(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description Get list of actions plans for selected enquiries
    * @author rajesh.punjabi@monash.edu | 20-09-2023 
    * @param setEnquiryIds 
    * @return List<ActionPlan> 
    **/
    public static List<ActionPlan> getActionPlans(Set<Id> setEnquiryIds){
        List<ActionPlan> lstActionPlan = [SELECT Id, TargetId, ActionPlanState, Name
                                          FROM ActionPlan
                                          WHERE TargetId IN: setEnquiryIds];
        return lstActionPlan;
    }
    
    /**
    * @description Custom Metadata for Component.
    * @author rajesh.punjabi@monash.edu | 20-09-2023 
    **/
    public class Payload {
        //..Enqiury Id
        @AuraEnabled
        public Id recordId {get; set;}
        //.. create Id URL to navigate
        @AuraEnabled
        public String recordIdURL {get; set;}
        @AuraEnabled
        public String iconParentChild {get; set;}
        @AuraEnabled
        public Integer rowNumber {get; set;}
        // The case number
        @AuraEnabled
        public String caseNumber {get; set;}
        // The account name
        @AuraEnabled
        public String accountName {get; set;}
        // The referral group
        @AuraEnabled
        public String referralGroup {get; set;}
        //.. Action Plan Id
        @AuraEnabled
        public Id actionPlanId {get; set;}
        //.. create Id URL to navigate
        @AuraEnabled
        public String actionPlanIdURL {get; set;}
        //.. Action Plan Name
        @AuraEnabled
        public String actionPlanName {get; set;}
        //.. Action Plan Name
        @AuraEnabled
        public String actionPlanStatus {get; set;}
        //.. Total Tasks
        @AuraEnabled
        public Integer totalTasks {get; set;}
        //.. Pending Tasks
        @AuraEnabled
        public Integer pendingTasks {get; set;}
        //.. Compelte Tasks
        @AuraEnabled
        public Integer completedTasks {get; set;}
        @AuraEnabled
        public String completedPercentage {get; set;}
        @AuraEnabled
        public Integer totalRecords {get; set;}
    }
}