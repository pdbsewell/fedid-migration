/**
* @author KL
* @date 15.05.2020
*
* @group Duplicate Management
*
* @description Service class providing features needed for Duplicate Management
*
* @revision
*           15.05.2020 - KL: Initial Create
*/
public class DupCheckServices {

    // TO DO: confirm with JM if any issues moving this to My.App level class
    static final String DUPLICATE_PERFECT_MATCH_NAME = 'Contact_Perfect_Match';
    static final String DUPLICATE_PARTIAL_MATCH_NAME = 'Contact_Potential_Match';
    static final String DUPLICATE_LOOSE_MATCH_NAME = 'Contact_Loose_Match';

    static final String taskDupCheckRequired = 'Required';
    static final String taskDupCheckNotRequired = 'Not Required';
    static final String taskDupCheckCompleted = 'Completed';

    public class PerformContactPointReprime implements IPlatformEventInvocable {
        
        private Set<Id> ContactIDs = new Set<Id>();

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.ContactIDs);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					//first, cast the get return of List<Object> into List<Id>
					List<Object> objList = (List<Object>) payload.get('contactId');
					//then, instantiate a Set out of it
					for(Object io : objList) {
						//parse object to ID
						this.ContactIDs.add(Id.valueOf(io.toString()));
					}
				}
			}
		}
        
        public void run() {
            for (Id loopId : this.ContactIDs) {
                // now invoke Platform team supplied logic to recalculate primaries
                ContactServices.invokeReCalculateContactPrimaryContactPoints(new Set<Id>{loopId});
            }                
        }        

    }
    
    public class PerformContactPointRehash implements IPlatformEventInvocable {

        private Set<Id> ContactIDs = new Set<Id>();
        
        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.ContactIDs);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					//first, cast the get return of List<Object> into List<Id>
					List<Object> objList = (List<Object>) payload.get('contactId');
					//then, instantiate a Set out of it
					for(Object io : objList) {
						//parse object to ID
						this.ContactIDs.add(Id.valueOf(io.toString()));
					}
				}
			}
		}        
        
        public void run() {
            for (Id loopId : this.ContactIDs) {
                // instantiate wrapper and invoke Platform team supplied logic
                ContactServices.RePopulateHashFoAllContactPointsWrapper result = new ContactServices.RePopulateHashFoAllContactPointsWrapper();
                result = ContactServices.rePopulateHashFoAllContactPoints(new Set<Id>{loopId});
                
                // process results, remove / delete duplicate records
                List<SObject> recordsToUpdate = result.vrecordsToUpdate;
                if (result.vsrList != null && !result.vsrList.isEmpty()) {
                    
                    Integer counter = 0;
                    List<Database.DeleteResult> drList = new List<Database.DeleteResult>();
                    List<Id> dupRecordsToDelete = new List<Id>();
                    
                    for (Database.SaveResult sr : result.vsrList) {
                        // if (!sr.isSuccess() && sr.getErrors().getStatusCode() == 'DUPLICATE_VALUE') {
                        if (!sr.isSuccess()) {
                            for (Database.Error dbErr : sr.getErrors()) {
                                // TO DO: below is not really ideal, but seems dbErr.getStatusCode() returns a funny 'StatusCode' type and not string.
                                // Needs more research into this one.
                                if (dbErr.getMessage().contains('duplicate value found')) {
                                    system.debug('!@# recordsToUpdate.get(counter).Id = ' + recordsToUpdate.get(counter).Id);
                                    dupRecordsToDelete.add(recordsToUpdate.get(counter).Id);    
                                }
                                
                            }
                        }
                        counter++;
                    }
                    
                    if (!dupRecordsToDelete.isEmpty() || dupRecordsToDelete != null) {
                        database.delete(dupRecordsToDelete, false);
                    }
                }
                
                // now invoke Platform team supplied logic to recalculate primaries
                // ContactServices.invokeReCalculateContactPrimaryContactPoints(new Set<Id>{loopId});
                Async_Process__e evt = createPayload(loopId);
                EventBus.publish(evt);
            }                
        }
        
        private Async_Process__e createPayload(Id conId) {            
            Async_Process__e evt;
            
            if(conId != null) {
                AsyncProcessPayload payload = new AsyncProcessPayload();
                payload.put ('contactId', new Set<Id> {conId});
                evt = new Async_Process__e (
                    Process_Name__c = 'DupCheckServices.PerformContactPointReprime',
                    Parameter__c = payload.serialize()
                );
            }            
            return evt;
        }
    }

    public class PerformMatchAndMerge implements IPlatformEventInvocable {
    
        private Set<Id> appIDs = new Set<Id>();

        public void execute(List<AsyncProcessPayload> payload) {
			try {
				initialize(payload);
				run();
			} catch(Exception e) {
				LogUtilityException.logException(e, this.appIDs);
			} finally {
				LogUtilityException.getLimits();
			}
		}

		private void initialize(List<AsyncProcessPayload> payloads) {
			if(payloads != null) {
				for(AsyncProcessPayload payload : payloads) {
					//first, cast the get return of List<Object> into List<Id>
					List<Object> objList = (List<Object>) payload.get('appId');
					//then, instantiate a Set out of it
					for(Object io : objList) {
						//parse object to ID
						this.appIDs.add(Id.valueOf(io.toString()));
					}
				}
			}
		}

        public void run() {

            List<Application__c> appsToUpdate = new List<Application__c>();

            for (Application__c appInLoop : [
                SELECT Applicant__c, Applicant__r.Id, Applicant__r.Previous_Monash_ID__c, Applicant__r.Email,
                Applicant__r.Personal_Email__c, Applicant__r.Monash_Email_Address__c, Task_Duplicate_Check__c
                FROM Application__c
                WHERE Id IN :this.appIDs
            ]) {
                // TO DO: when time permits, remove the dup check status from overall assessment solution altogether if not needed in orchestrator anymore,
                // just leaving for now to minimise risk of too many changes
                Boolean hasPotentialMatch = false;
                Set<Id> potentialDuplicateContactIds = new Set<Id>();
                
                // set dup check task status to a default of 'not required' to start with
                Application__c appToUpdate = new Application__c(
                    Id = appInLoop.Id
                );

                // Find if there are Perfect Match result
                Set<Id> perfectMatchContactIds = new Set<Id>();
                perfectMatchContactIds = TaskDupCheckHelper.findDuplicateContacts(new Set<Id>{appInLoop.Applicant__r.Id}, DUPLICATE_PERFECT_MATCH_NAME);

                if (!perfectMatchContactIds.isEmpty()) {
                    // Invoke codes for Perfect Match Merge
                    TaskDupCheckHelper helper = new TaskDupCheckHelper();
                    helper.init(appInLoop.Applicant__r.Id, perfectMatchContactIds);
                }

                // Find if there are Potential Match and/or Loose Match and/or email search and/or person id match
                List<Contact> contactList = TaskDupCheckHelper.queryContactFieldsForSearchingDuplicates(appInLoop.Applicant__r.Id);

                potentialDuplicateContactIds = TaskDupCheckHelper.findPotentialDuplicateContacts(contactList.get(0));
                if (!potentialDuplicateContactIds.isEmpty()) {
                    hasPotentialMatch = true;
                }

                // Update App record's status to 'Sent for Submission' to trigger off existing process
                if (!perfectMatchContactIds.isEmpty() && !hasPotentialMatch) {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckCompleted;
                    appToUpdate.Status__c = MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS;
                } else if ((!perfectMatchContactIds.isEmpty() && hasPotentialMatch) || (perfectMatchContactIds.isEmpty() && hasPotentialMatch)) {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckRequired;
                } else {
                    appToUpdate.Task_Duplicate_Check__c = taskDupCheckNotRequired;
                    appToUpdate.Status__c = MyApplicationUtilities.APP_SENT_FOR_SUBMIT_STATUS;
                }
                appsToUpdate.add(appToUpdate);
            }

            //Commit records to database
            List<Database.SaveResult> srList = Database.update(appsToUpdate, false);
            logExceptions(srList);

        }

		//TODO : move this to LogUtilityExceptions
		private void logExceptions(List<Database.SaveResult> srList) {
			if(srList != null && !srList.isEmpty()) {
				for(Database.SaveResult iSr : srList) {
					if(!iSr.isSuccess()) { 
						//TODO : we may want to log all errors once we move this to LogUtilityExceptions
						Database.Error err = iSr.getErrors()[0]; //get first instance of error
						LogUtilityException.logExceptionMSG(
							'DupCheckServices.PerformMatchAndMerge', 
							iSr.getId(), 
							'Status Code : ' + err.getStatusCode() + ' Message : ' + err.getMessage());
					}
				}
			}
		}

    }
}