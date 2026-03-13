/**
*  @author idha0002
*  @date (13-07-2021)
*  @group Enterprise Engage
*  @description Used save Collaborators Internal/External with Enterprise Opportunity
*  Modifications Log
*  Ver   Date         Author          Modification
*  1.0   2021-07-13 - Inderpal Dhanoa - Initial Creation
**/
public with sharing class AttachCollaboratorsController {
    /*
     * Method Name: saveCollaborator
     * @param  collaboratorRecord JSON format of parameters for Collaborator creation
     * Description: Validate Edit access
    */
    @AuraEnabled
    public static String saveCollaborator(String collaboratorRecord) {
        try{
           Map<String, Object> parsedCollaborator = (Map<String, Object>)JSON.deserializeUntyped(collaboratorRecord);
            // Insert Collaborators
            if(!parsedCollaborator.isEmpty()){
                Opportunity_Collaborator__c newOpportunityCollaborator = new Opportunity_Collaborator__c();
                newOpportunityCollaborator.Value_Involvement__c = Decimal.valueof((String)parsedCollaborator.get('amount'));
                if(parsedCollaborator.get('lead') != 'undefined' || parsedCollaborator.get('lead') != null){
                    newOpportunityCollaborator.Lead__c = (Boolean)parsedCollaborator.get('lead');
                }
                newOpportunityCollaborator.Opportunity__c = (Id)parsedCollaborator.get('opportunityId');
                newOpportunityCollaborator.Organisation__c = (Id)parsedCollaborator.get('orgId');   
                String recTypeDeveloperName = (String)parsedCollaborator.get('collaboratorType');
                if(recTypeDeveloperName == 'Group'){
                    newOpportunityCollaborator.Relationship_Type__c = 'External Organisation';
                }else{
                    newOpportunityCollaborator.Relationship_Type__c = 'Internal Organisation';
                }
                newOpportunityCollaborator.RecordTypeId = Schema.SObjectType.Opportunity_Collaborator__c.getRecordTypeInfosByName().get(recTypeDeveloperName).getRecordTypeId();
                insert newOpportunityCollaborator;
                return String.valueOf(newOpportunityCollaborator.Opportunity__c);
            }           
            return '';
        }catch (Exception e) {
            LogUtilityException.logException(e);
			System.debug(LoggingLevel.ERROR, e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }
}