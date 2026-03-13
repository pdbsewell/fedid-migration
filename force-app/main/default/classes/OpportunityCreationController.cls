/**
*  @author idha0002
*  @date (10-03-2021)
*  @group Enterprise Engage
*  @description Used to create Opportunity and Collaborators
*  Modifications Log
*  Ver   Date         Author          Modification
*  1.0   2021-03-10 - Inderpal Dhanoa - Initial Creation
*  1.1   2021-06-25 - Inderpal Dhanoa - Add Category to payload
*  1.2   2021-08-31 - Inderpal Dhanoa - ENGAGEIE-1014 Add Primary Contact to payload & remove Private Flag
*  1.3   2021-09-07 - Inderpal Dhanoa - ENGAGEIE-1062 Null Handling fix for AccountId
*  1.4   2021-04-11 - Inderpal Dhanoa - ENGAGEIE-1173 Adding Default Opportunity Team members
*  1.5   2023-09-04 - Davey Yu        - ENGAGEIE-1729/1730 Update Stage to Prospecting
**/
public with sharing class OpportunityCreationController {
    
    @AuraEnabled
    public static string saveOpportunityAndCollaborators(String opportunityRecord, String collaborator){
        try{
            Map<String, Object> parsedOpportunityRecord = (Map<String, Object>)JSON.deserializeUntyped(opportunityRecord);
            Map<String, Object> parsedCollaborator = (Map<String, Object>)JSON.deserializeUntyped(collaborator);
            system.debug('#####parsedOpportunityRecord'+parsedOpportunityRecord);
            system.debug('#####parsedCollaborator'+parsedCollaborator);
            // Insert Enterprise RecType Opportunity
            Opportunity newOpportunity = new Opportunity();
            newOpportunity.Name = (String)parsedOpportunityRecord.get('Name');
            if(parsedOpportunityRecord.containsKey('AccountId')){
                if(parsedOpportunityRecord.get('AccountId') == '' || parsedOpportunityRecord.get('AccountId') == null){
                    newOpportunity.AccountId = null;
                }else{
                    newOpportunity.AccountId = (Id)parsedOpportunityRecord.get('AccountId');    
                }
            }
			newOpportunity.PrimaryContact__c = parsedOpportunityRecord.containsKey('PrimaryContactId') ? (Id)parsedOpportunityRecord.get('PrimaryContactId') : null;//ENGAGEIE-1730 Remove field from the component
            //ENGAGE-1750 check if amount is not blank
            if((String)parsedOpportunityRecord.get('Amount') != null && (String)parsedOpportunityRecord.get('Amount') != ''){
           		newOpportunity.Amount = Decimal.valueOf((String)parsedOpportunityRecord.get('Amount'));
            }
            newOpportunity.Description = (String)parsedOpportunityRecord.get('Description');
            newOpportunity.CloseDate = Date.valueOf((String)parsedOpportunityRecord.get('CloseDate'));
			//newOpportunity.Category__c = (String)parsedOpportunityRecord.get('Category');  //ENGAGEIE-1730 Remove field from the component
            //newOpportunity.StageName = 'Identify Opportunity'; //ENGAGEIE-1729 updated to Prospecting
            newOpportunity.StageName = 'Prospecting'; //ENGAGEIE-1729 Update Stage to Prospecting
            newOpportunity.Type = 'Standard';
            newOpportunity.Visibility_Category__c = (String)parsedOpportunityRecord.get('VisibilityCategory');
            newOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();
            //START OF ENGAGEIE-1730 - Added new fields on express opportunity component
            newOpportunity.Service_Catalogue_Alignment__c = (String)parsedOpportunityRecord.get('ServiceCatalogue');
            newOpportunity.Breadth_of_Strategic_Alignment__c = (String)parsedOpportunityRecord.get('StrategicAlignment');
            newOpportunity.Broad_area_s_of_interest__c = (String)parsedOpportunityRecord.get('AreasOfInterest');
            //END OF ENGAGEIE-1730
            insert newOpportunity;

            // Insert Collaborators
            if(!parsedCollaborator.isEmpty()){
                Opportunity_Collaborator__c newOpportunityCollaborator = new Opportunity_Collaborator__c();
                //ENGAGE-1750 check if allocated amount is not blank

                if(!String.isBlank((String)parsedOpportunityRecord.get('allocatedAmount'))){
                	newOpportunityCollaborator.Value_Involvement__c = Decimal.valueOf((String)parsedCollaborator.get('allocatedAmount'));
                }
                newOpportunityCollaborator.Lead__c = true;
                newOpportunityCollaborator.Opportunity__c = newOpportunity.Id; 
                newOpportunityCollaborator.Organisation__c = (Id)parsedCollaborator.get('collaboratorId');   
                newOpportunityCollaborator.Relationship_Type__c = 'Internal Organisation';
                newOpportunityCollaborator.RecordTypeId = Schema.SObjectType.Opportunity_Collaborator__c.getRecordTypeInfosByName().get('Opportunity').getRecordTypeId();
                insert newOpportunityCollaborator;
            }    

			// Insert Team Members
            if((Boolean)parsedOpportunityRecord.get('TeamMember')){
                List<OpportunityTeamMember> l_defaultTeamMebers = new List<OpportunityTeamMember>();
                for(UserTeamMember userTeam : [SELECT OpportunityAccessLevel,TeamMemberRole,UserId 
                                               FROM UserTeamMember WHERE OwnerId = :UserInfo.getUserId()]){
                    OpportunityTeamMember newOpportunityTeamMember = new OpportunityTeamMember(OpportunityAccessLevel = userTeam.OpportunityAccessLevel, TeamMemberRole = userTeam.TeamMemberRole, OpportunityId = newOpportunity.Id, UserId = userTeam.UserId); 
                    l_defaultTeamMebers.add(newOpportunityTeamMember);
                }
                insert l_defaultTeamMebers;
            }			
            return String.valueOf(newOpportunity.Id);

        }catch (Exception e) {
            system.debug('#####e.getMessage()'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}