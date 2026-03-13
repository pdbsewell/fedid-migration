/**
 * Services class to provide Opportunity Support
 * 
 * @author Mark Johnson - UC Innovation
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0		 27-AUG-2019	 Mark Johson			Initial Creation
 * 2.0       10-JAN-2024     Davey Yu     			ENGAGEIE-1841 Add new method validateDuplicateMonashSystemId to validate for potential duplicate based on Monash System Id 
 */

public class EngageOpportunityService {
    
    Static Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName();
    
	/*******************************************************************************
	* @description 	Set authorize and charge field to false UNLESS tender type category is set to 'Credit Card'
	*******************************************************************************/
	public class setAuthorizeAndCharge implements Triggers.Handler {
		public void run() {
			List<ucinn_ascendv2__Gift_Processing_Tender_Type__mdt> tenderTypeMDList = [SELECT ucinn_ascendv2__Tender_Type_Category__c, DeveloperName FROM ucinn_ascendv2__Gift_Processing_Tender_Type__mdt 
												WHERE ucinn_ascendv2__Tender_Type_Category__c = 'Credit Card'];
			Set<String> tenderTypesToAuthAndCharge = new Set<String>();
			for (ucinn_ascendv2__Gift_Processing_Tender_Type__mdt eachMD: tenderTypeMDList) {
				tenderTypesToAuthAndCharge.add(eachMD.DeveloperName);
			}

			Id giftRecordTypeId = EngageOpportunityService.recordTypeMap.get('Gift').getRecordTypeId();
			Id pledgeRecordTypeId = EngageOpportunityService.recordTypeMap.get('Pledge').getRecordTypeId();
			Id matchingGiftRecordTypeId = EngageOpportunityService.recordTypeMap.get('Matching_Gift').getRecordTypeId();
            Id recurringGiftRTId = EngageOpportunityService.recordTypeMap.get('Recurring_Gift').getRecordTypeId();

			Set<Id> recordTypesToConsider = new Set<Id>{giftRecordTypeId, pledgeRecordTypeId, matchingGiftRecordTypeId, recurringGiftRTId};

			// Loop through trigger new, if tender type is not in tenderTypesToAuthAndCharge set, then set authorize_and_charge__c to false
			List<Opportunity> opportunityList = (List<Opportunity>) Trigger.New;
			for (Opportunity eachOpp: opportunityList) {
				if (recordTypesToConsider.contains(eachOpp.recordTypeId) && !tenderTypesToAuthAndCharge.contains(eachOpp.ucinn_ascendv2__Tender_Type_for_Gifts__c)) {
					eachOpp.ucinn_ascendv2__Authorize_and_Charge__c = false;
				}
			}
		}
	}

	/*******************************************************************************
	* @description 	Validates that a user has an assignment to the related record.
	*******************************************************************************/
	public class validateThatUserHasAssignment implements Triggers.Handler {
		public void run() {

			Set<Id> contactIdSet = new Set<Id>();
			Set<Id> accountIdSet = new Set<Id>();
			List<Opportunity> opportunityList = (List<Opportunity>) Trigger.New;

			Set<Id> contactIdsThatHaveAssignments = new Set<Id>();
			Set<Id> accountIdsThatHaveAssignments = new Set<Id>();

			Id recordTypeId = EngageOpportunityService.recordTypeMap.get('Proposal').getRecordTypeId();
			Id bequestRecordTypeId = EngageOpportunityService.recordTypeMap.get('Bequest_Proposal').getRecordTypeId();

			for (Opportunity opportunity : opportunityList) {
				if (opportunity.RecordTypeId == recordTypeId || opportunity.RecordTypeId == bequestRecordTypeId) {
					contactIdSet.add(opportunity.Ucinn_ascendv2__Contact__c);
					accountIdSet.add(opportunity.AccountId);
				}
			}

			if (contactIdSet.isEmpty() && accountIdSet.isEmpty()) return;
            
            List<Ucinn_ascendv2__Assignment__c> assignmentList = [	SELECT 	Ucinn_ascendv2__Contact__c, 
																			Ucinn_ascendv2__Account__c 
																	FROM Ucinn_ascendv2__Assignment__c
																	WHERE (Ucinn_ascendv2__Contact__c IN: contactIdSet
																	OR Ucinn_ascendv2__Account__c IN: accountIdSet)
																	AND Ucinn_ascendv2__Assignment_End_Date__c = null
																	AND Ucinn_ascendv2__Assigned_Relationship_Manager_User__c =: UserInfo.getUserId()];

			for (Ucinn_ascendv2__Assignment__c assignment : assignmentList) {
				if (assignment.Ucinn_ascendv2__Contact__c != null) {
					contactIdsThatHaveAssignments.add(assignment.Ucinn_ascendv2__Contact__c);
				}
				if (assignment.Ucinn_ascendv2__Account__c != null) {
					accountIdsThatHaveAssignments.add(assignment.Ucinn_ascendv2__Account__c);
				}
			}

            Boolean userHasPermission = false;
			List<String> allGroupNames = new List<String>();
            List<String> roleRelatedGroupIds = new List<String>();
            String groupName;
            
            for (Group g : [SELECT Id, RelatedId FROM Group WHERE RelatedId =: UserInfo.getUserRoleId()]) {
                roleRelatedGroupIds.add(g.id);
            }
            
            //Get list of group names that user is a part of
			for (GroupMember gm : [SELECT Id, Group.DeveloperName FROM GroupMember 
                                   WHERE (UserOrGroupId = :UserInfo.getUserId() AND Group.Type='Regular')
                                   OR (UserOrGroupId IN :roleRelatedGroupIds AND Group.Type = 'Regular')]) {
				
				allGroupNames.add(gm.Group.DeveloperName);
			}
            
			//Check if user is part of Bypass Proposal Validation public group
            for (String thisGroupName : allGroupNames) {
                groupName = thisGroupName;
                if (groupName.equals('Bypass_Proposal_Validation')) {
                    userHasPermission = true;
                }
            }
            
			for (Opportunity opportunity : opportunityList) {

				if (opportunity.RecordTypeId != recordTypeId && opportunity.RecordTypeId != bequestRecordTypeId) continue;

				if (!userHasPermission && opportunity.Ucinn_ascendv2__Contact__c != null && !contactIdsThatHaveAssignments.contains(opportunity.Ucinn_ascendv2__Contact__c)) {
					opportunity.addError('An active assignment to the contact/prospect is necessary before creating a proposal. Please create an assignment request.');
				}
				if (!userHasPermission && opportunity.AccountId != null && !accountIdsThatHaveAssignments.contains(opportunity.AccountId)) {
					opportunity.addError('An active assignment to the contact/prospect is necessary before creating a proposal. Please create an assignment request.');
				}
			}
		}
	}
    
     /**
     * @description Validate for potential duplicate enterprise opportunity based on Monash System ID
     * @param       None
     * @return      Error Message
     * @revision    10-01-2024     Davey Yu       Initial Creation
     */
	public class validateDuplicateMonashSystemId Implements Triggers.Handler{
		public void run() {
			Set<String> monashSystemIdSet = new Set<String>();
            List<Opportunity> opportunityList = (List<Opportunity>) Trigger.New;
			Map<Id,Opportunity> opportunityMap = (Map<Id,Opportunity>) Trigger.OldMap;
			Map<String, Opportunity> dupplicateOpportunityMap = new Map<String, Opportunity>();
		
			Id recordTypeId = EngageOpportunityService.recordTypeMap.get('Enterprise').getRecordTypeId();
            Id profileId=userinfo.getProfileId();
		    List<Profile> profileNames = [Select Id,Name from Profile where Id=:profileId]; 
            
            if(profileNames.size() > 0 && !profileNames[0].Name.contains('Integration')){// should not run for integration user

                //Loop through the opportunity records and store the monash system id on a set
                for (Opportunity opportunity : OpportunityList) {
                    //udpate trigger event
                    if(opportunityMap !=  null){
                        if(opportunity.RecordTypeId == recordTypeId && opportunity.Monash_System_ID__c != null
                            && Opportunity.Monash_System_Id__c != OpportunityMap.get(opportunity.id).Monash_System_Id__c){
                            monashSystemIdSet.add(opportunity.Monash_System_ID__c);
                        }
                    }else{//new trigger event
                        
                        if(opportunity.RecordTypeId == recordTypeId && opportunity.Monash_System_ID__c != null) {
                            monashSystemIdSet.add(opportunity.Monash_System_ID__c);
                        }
                    }
                }
                
                if (monashSystemIdSet.isEmpty()) return;
    
                //Check if there is already an existing enteprise opportunity records based on monash system id et
                List<Opportunity> duplicateOpportunityList = new List<Opportunity>();
                duplicateOpportunityList = [Select id, Monash_System_Id__c, Name, PURE_Application_ID__c 
                                            FROM Opportunity 
                                            WHERE Monash_System_Id__c IN: monashSystemIdSet];
                if(duplicateOpportunityList.size() > 0){
                    for(Opportunity dupOpp: duplicateOpportunityList){
                        //store the duplicate enterprise opportunity on a map where monash system id is the unique key
                        dupplicateOpportunityMap.put(dupOpp.Monash_System_Id__c, dupOpp);
                    }
                }
                
                //Throw an error message when a duplicate is found
                for (Opportunity opportunity : opportunityList) {
                    if (opportunity.RecordTypeId == recordTypeId){
                        if (dupplicateOpportunityMap.get(opportunity.Monash_System_Id__c) !=  null) {
                            opportunity.addError('Potential Duplicate Opportunity  with the same System ID.' + 
                            '<br/>'+'Name: ' + dupplicateOpportunityMap.get(opportunity.Monash_System_Id__c).Name +
                            '<br/>'+', Monash System Id: '+ dupplicateOpportunityMap.get(opportunity.Monash_System_Id__c).Monash_System_Id__c);
                        }
                    
                    }
                }
            }
        }
	}
    
    /*******************************************************************************
	* @description 	prepopulate fields for before insert.
	*******************************************************************************/
	public class prepopulateFields implements Triggers.Handler {
        public void run() {
            
            Id recordTypeId = EngageOpportunityService.recordTypeMap.get('Proposal').getRecordTypeId();
			Id bequestRecordTypeId = EngageOpportunityService.recordTypeMap.get('Bequest_Proposal').getRecordTypeId();
            Id giftRecordTypeId = EngageOpportunityService.recordTypeMap.get('Gift').getRecordTypeId();
            Id recurringGiftRTId = EngageOpportunityService.recordTypeMap.get('Recurring_Gift').getRecordTypeId();
            Id pledgeRecordTypeId = EngageOpportunityService.recordTypeMap.get('Pledge').getRecordTypeId();
            
            List<Opportunity> opportunityList = (List<Opportunity>) Trigger.New;
            Map<Id,Opportunity> opportunityMap = (Map<Id,Opportunity>) Trigger.OldMap;
            
            for (Opportunity opportunity : opportunityList) {
                
             	 // setup PrimaryContact__c value for all the Opportunity created from internal gift processing screen
                // so that when a apex batch runs in community user context, batch will have access to all the 
                // Opportunity records related to Contact and will calculate life time fund summery calculation correctly
                
                 if (opportunity.RecordTypeId == recordTypeId || opportunity.RecordTypeId == bequestRecordTypeId ||
                      opportunity.RecordTypeId == giftRecordTypeId || opportunity.RecordTypeId == recurringGiftRTId ||
                      opportunity.RecordTypeId == pledgeRecordTypeId) {
                          if(opportunityMap !=null){
                           	if(opportunity.Ucinn_ascendv2__Contact__c !=null && opportunityMap.get(opportunity.id).Ucinn_ascendv2__Contact__c
                               != opportunity.Ucinn_ascendv2__Contact__c){
                            	opportunity.PrimaryContact__c =  opportunity.Ucinn_ascendv2__Contact__c; 
                          	}	   
                          }
                          else{
                              if(opportunity.Ucinn_ascendv2__Contact__c !=null){
                               	opportunity.PrimaryContact__c =  opportunity.Ucinn_ascendv2__Contact__c;    
                              }                              
                          }
                          
					}       
            	}    
       	   }
    }

	/*******************************************************************************
	* @description 	Associates an opportunity with a proposal's opportunity team.
	*******************************************************************************/
	public class ReassociateOpportunityTeams implements Triggers.Handler {
		public void run() {
			List<Opportunity> opportunityList = (List<Opportunity>) Trigger.New;
			List<Opportunity> opportunityListToAddTeam = new List<Opportunity>();
			List<Id> opportunityListToAddTeamIds = new List<Id>();
			List<Id> opportunityProposalIdList = new List<Id>();
			Map<Id, Opportunity> opportunityOldMap = (Map<Id, Opportunity>) Trigger.OldMap;
			Map<Id, Opportunity> proposalIdToGiftOrPledgeRec = new Map<Id, Opportunity>();

			List<OpportunityTeamMember> opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();

			Id giftRecordTypeId = EngageOpportunityService.recordTypeMap.get('Gift').getRecordTypeId();
			Id pledgeRecordTypeId = EngageOpportunityService.recordTypeMap.get('Pledge').getRecordTypeId();
			Id matchingGiftRecordTypeId = EngageOpportunityService.recordTypeMap.get('Matching_Gift').getRecordTypeId();

			for (Opportunity opportunity : opportunityList) {
				if (opportunity.RecordTypeId == giftRecordTypeId || opportunity.RecordTypeId == pledgeRecordTypeId || opportunity.RecordTypeId == pledgeRecordTypeId) {
					if (Trigger.IsInsert && opportunity.ucinn_ascendv2__Proposal__c != null) {
						//Add gift or pledge rec to list
						opportunityListToAddTeam.add(opportunity);
						opportunityListToAddTeamIds.add(opportunity.Id);

						//Add proposal ID to list
						opportunityProposalIdList.add(opportunity.ucinn_ascendv2__Proposal__c);

						//Map of proposal ID to gift or pledge rec
						proposalIdToGiftOrPledgeRec.put(opportunity.ucinn_ascendv2__Proposal__c, opportunity);
					} else if (Trigger.IsUpdate && opportunity.ucinn_ascendv2__Proposal__c != null && (opportunity.ucinn_ascendv2__Proposal__c != opportunityOldMap.get(opportunity.Id).ucinn_ascendv2__Proposal__c)) {
						opportunityListToAddTeam.add(opportunity);
						opportunityListToAddTeamIds.add(opportunity.Id);
						opportunityProposalIdList.add(opportunity.ucinn_ascendv2__Proposal__c);
						proposalIdToGiftOrPledgeRec.put(opportunity.ucinn_ascendv2__Proposal__c, opportunity);
					}
				}
			}

			//Fetch all opportunity team members associated with the proposals and with the gift/pledge recs.
			List<OpportunityTeamMember> opportunityTeamMembers = new List<OpportunityTeamMember>();
            if(!opportunityProposalIdList.isEmpty() || !opportunityListToAddTeam.isEmpty()) {
                opportunityTeamMembers = [ SELECT 	OpportunityId, 
                                                        TeamMemberRole, 
                                                        Start_Date__c, 
                                                        End_Date__c,
                                                        UserId
                                                FROM OpportunityTeamMember 
                                                WHERE 	OpportunityId IN: opportunityProposalIdList OR
                                                        OpportunityId IN: opportunityListToAddTeam];
            }
			Map<Id, Set<Id>> proposalToUserId = new Map<Id, Set<Id>>();
			Map<Id, Set<Id>> pledgeOrGiftToUserId = new Map<Id, Set<Id>>();

			for (OpportunityTeamMember opportunityTeamMem : opportunityTeamMembers) {
				if (opportunityProposalIdList.contains(opportunityTeamMem.OpportunityId)) {
					if (proposalToUserId.containsKey(opportunityTeamMem.OpportunityId)) {
						proposalToUserId.get(opportunityTeamMem.OpportunityId).add(opportunityTeamMem.UserId);
					} else {
						proposalToUserId.put(opportunityTeamMem.OpportunityId, new Set<Id>{opportunityTeamMem.UserId});
					}
				} else if (opportunityListToAddTeamIds.contains(opportunityTeamMem.OpportunityId)) {
					if (pledgeOrGiftToUserId.containsKey(opportunityTeamMem.OpportunityId)) {
						pledgeOrGiftToUserId.get(opportunityTeamMem.OpportunityId).add(opportunityTeamMem.UserId);
					} else {
						pledgeOrGiftToUserId.put(opportunityTeamMem.OpportunityId, new Set<Id>{opportunityTeamMem.UserId});
					}
				}
			}

			for (OpportunityTeamMember opportunityTeamMem : opportunityTeamMembers) {
				if ((opportunityProposalIdList.contains(opportunityTeamMem.OpportunityId)) &&
					(opportunityTeamMem.TeamMemberRole == 'Fundraiser' || opportunityTeamMem.TeamMemberRole == 'Fundraiser - Lead') &&
					(opportunityTeamMem.End_Date__c == null || opportunityTeamMem.End_Date__c > Date.Today())) {

					Opportunity giftOrPledgeRec = proposalIdToGiftOrPledgeRec.get(opportunityTeamMem.OpportunityId);
					Boolean addOppMember = true;

					if (pledgeOrGiftToUserId.get(opportunityTeamMem.OpportunityId) != null &&
						proposalToUserId.get(opportunityTeamMem.OpportunityId).contains(opportunityTeamMem.UserId) && 
						pledgeOrGiftToUserId.get(opportunityTeamMem.OpportunityId).contains(opportunityTeamMem.UserId)) {
							addOppMember = false;
					}

					if (addOppMember) {
						OpportunityTeamMember newOppTeamMember = opportunityTeamMem.clone();
						newOppTeamMember.OpportunityId = giftOrPledgeRec.Id;
						opportunityTeamMembersToInsert.add(newOppTeamMember);
					}
				}
			}

			insert opportunityTeamMembersToInsert;
		}
	}


	public class processMajorGifts implements Triggers.Handler {
		List<Contact> contactsToUpdate = new List<Contact>();
		List<Account> accountsToUpdate = new List<Account>();

		Set<Id> contactsWithMajorGiftUpdates = new Set<Id>();
		Set<Id> accountsWithMajorGiftUpdates = new Set<Id>();
		List<Contact> contactsAndMajorGifts = new List<Contact>();
		List<Account> accountsAndMajorGifts = new List<Account>();


		public void run() {
			populateMajorDonorFlag();
			updateContactsAndAccounts();
		}

		/*******************************************************************************
		* @description  Populates major donor flag on contacts if contacts has major gift
		*******************************************************************************/
		private void populateMajorDonorFlag() {

			populateContactAndAccountLists(Trigger.New);

			//Set should already be populated on update due to existence of triggerNew as well as triggerOld.
			if (!Trigger.isUpdate) populateContactAndAccountLists(Trigger.Old);

			if (!contactsWithMajorGiftUpdates.isEmpty()) populateContactsWithMajorGiftsList();
			if (!accountsWithMajorGiftUpdates.isEmpty()) populateAccountsWithMajorGiftsList();

			for (Contact con : contactsAndMajorGifts) {
				if (con.Major_Donor__c == true && con.Ucinn_ascendv2__Opportunities_Contact__r.isEmpty()) {
					con.Major_Donor__c = false;
					contactsToUpdate.add(con);
				} else if (con.Major_Donor__c == false && !con.Ucinn_ascendv2__Opportunities_Contact__r.isEmpty()) {
					con.Major_Donor__c = true;
					contactsToUpdate.add(con);
				}
			}

			for (Account acc : accountsAndMajorGifts) {
				if (acc.Major_Donor__c == true && acc.Opportunities.isEmpty()) {
					acc.Major_Donor__c = false;
					accountsToUpdate.add(acc);
				} else if (acc.Major_Donor__c == false && !acc.Opportunities.isEmpty()) {
					acc.Major_Donor__c = true;
					accountsToUpdate.add(acc);
				}
			}
		}


		/*******************************************************************************
		* @description  Query for all non closed lost major gifts from selected contacts
		*******************************************************************************/
		private void populateContactsWithMajorGiftsList() {
			contactsAndMajorGifts = [SELECT Id, 
											Major_Donor__c,
											(SELECT Id 
											FROM Ucinn_ascendv2__Opportunities_Contact__r 
											WHERE StageName != 'Closed Lost'
											AND  (RecordType.DeveloperName = 'Proposal' AND RecordType.NamespacePrefix = 'ucinn_ascendv2'))
									FROM Contact WHERE Id IN: contactsWithMajorGiftUpdates ];

		}


		/*******************************************************************************
		* @description  Query for all non closed lost major gifts from selected accounts
		*******************************************************************************/
		private void populateAccountsWithMajorGiftsList() {
			accountsAndMajorGifts = [SELECT Id, 
											Major_Donor__c,
											(SELECT Id 
											FROM Opportunities
											WHERE StageName != 'Closed Lost'
											AND  (RecordType.DeveloperName = 'Proposal' AND RecordType.NamespacePrefix = 'ucinn_ascendv2'))
									FROM Account WHERE Id IN: accountsWithMajorGiftUpdates ];
		}


		/*******************************************************************************
		* @description  Populate sets of contact and account ids from triggerNew and triggerOld
		*******************************************************************************/
		private void populateContactAndAccountLists(List<SObject> triggerList) {
			if (triggerList != null) {
				for (Opportunity opp : (List<Opportunity>) triggerList) {
					if (opp.Ucinn_ascendv2__Contact__c != null) {
						contactsWithMajorGiftUpdates.add(opp.Ucinn_ascendv2__Contact__c);
					} else if (opp.AccountId != null) {
						accountsWithMajorGiftUpdates.add(opp.AccountId);
					}
				}
			}
		}

		/*******************************************************************************
		* @description  Perform dml to add or remove major donor flag on contacts
		*******************************************************************************/
		private void updateContactsAndAccounts() {
			//Disable to prevent unecessary trigger execution
			TriggerCommon.disableTrigger('Contact');
			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', false);

			update contactsToUpdate;

			TriggerCommon.enableTrigger('Contact');
			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Contact', true);

			//Disable to prevent unecessary trigger execution
			TriggerCommon.disableTrigger('Account');
			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Account', false);

			update accountsToUpdate;

			TriggerCommon.enableTrigger('Account');
			ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('Account', true);
		}
	}

}