/*
* @author			Ayush Agrawal <ayush.agrawal@monash.edu>
* @group			Student Admin - Academic Progress
* @description		This class provides bulk CaseTeamMember management functionality.
*/

public with sharing class ManageCaseTeamMembersController {
    @AuraEnabled
    public static String execute(String recordId, String operation, List<String> studentIds, List<String> targetIds) {
        try {
            // Reference data.
            CaseTeamRole ctr = [SELECT Id FROM CaseTeamRole WHERE Name = 'Support' LIMIT 1];
            
            // Get Contact Ids.
            List<Contact> contacts = [SELECT
                                      Id, Monash_Email_Address__c, Person_Id_Unique__c, SAP_Staff_Id__c
                                      FROM Contact
                                      WHERE
                                      Monash_Email_Address__c IN :targetIds OR Person_Id_Unique__c IN :targetIds OR SAP_Staff_Id__c IN :targetIds ORDER BY SAP_Staff_Id__c NULLS FIRST];
            
            Map<String, Id> mapOfContactExternalIdToSalesforceId = new Map<String, Id>();
            for(Contact c : contacts) {
                if(!String.isEmpty(c.Person_Id_Unique__c)) {
                    mapOfContactExternalIdToSalesforceId.put(c.Person_Id_Unique__c, c.Id);
                    if(!String.isEmpty(c.Monash_Email_Address__c)) {
                        mapOfContactExternalIdToSalesforceId.put(c.Monash_Email_Address__c, c.Id);
                    }
                }
                
                if(!String.isEmpty(c.SAP_Staff_Id__c)) {
                    mapOfContactExternalIdToSalesforceId.put(c.SAP_Staff_Id__c, c.Id);
                    if(!String.isEmpty(c.Monash_Email_Address__c)) {
                        mapOfContactExternalIdToSalesforceId.put(c.Monash_Email_Address__c, c.Id);
                    }
                }
            }
            
            Map<Id, Case> cases = new Map<Id, Case>();
            if(!studentIds.isEmpty()) {
                cases = new Map<Id, Case>([SELECT Id, IsClosed
                             FROM Case
                             WHERE Contact.Person_Id_Unique__c IN :studentIds AND RecordType.DeveloperName = 'Academic_Progress_Assessment']);
            }

            // Process CaseTeamMembers.
            List<CaseTeamMember> caseTeamMembersToCreate = new List<CaseTeamMember>();
            List<CaseTeamMember> caseTeamMembersToDelete = new List<CaseTeamMember>();
            
            if(operation == 'Add') {
                if(!String.isBlank(recordId)) {
                    for(String targetId : targetIds) {
                        CaseTeamMember ctm = new CaseTeamMember();
                        ctm.MemberId = mapOfContactExternalIdToSalesforceId.get(targetId);
                        ctm.ParentId = recordId;
                        ctm.TeamRoleId = ctr.Id;
                        
                        caseTeamMembersToCreate.add(ctm);
                    }
                } else if(!studentIds.isEmpty()) {
                    for(String targetId : targetIds) {
                        for(Id caseId : cases.keySet()) {
                            CaseTeamMember ctm = new CaseTeamMember();
                            ctm.MemberId = mapOfContactExternalIdToSalesforceId.get(targetId);
                            ctm.ParentId = caseId;
                            ctm.TeamRoleId = ctr.Id;
                            
                            caseTeamMembersToCreate.add(ctm);
                        }
                    }
                }
            } else if(operation == 'Remove') {
                Set<Id> contactIds = new Set<Id>();
                
                for(String targetId : targetIds) {
                    contactIds.add(mapOfContactExternalIdToSalesforceId.get(targetId));
                }
                
                if(!String.isBlank(recordId)) {
                    List<CaseTeamMember> ctms = [SELECT Id FROM CaseTeamMember WHERE MemberId IN :contactIds AND ParentId = :recordId AND TeamRoleId = :ctr.Id];
                    caseTeamMembersToDelete.addAll(ctms);
                } else if(!studentIds.isEmpty()) {
                    List<CaseTeamMember> ctms = [SELECT Id FROM CaseTeamMember WHERE MemberId IN :contactIds AND ParentId IN :cases.keySet() AND TeamRoleId = :ctr.Id];
                    caseTeamMembersToDelete.addAll(ctms);
                }
            }
            
            if(!caseTeamMembersToCreate.isEmpty()) {
                Database.insert(caseTeamMembersToCreate, false);
            }
            
            if(!caseTeamMembersToDelete.isEmpty()) {
                Database.delete(caseTeamMembersToDelete, false);
            }
            
            return null;
        } catch(Exception e) {
            throw new AuraHandledException('System exception occured. Please get in touch with your Salesforce Administrator.');
        }
    }
}