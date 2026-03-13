/**
 * @author Nick Guia
 * @date 18.01.2021
 * @group Event Management
 * @description Selector class for conference360__Attendee__c object (Blackthorn)
 *   17.01.2022  Ibrahim Rumi    - EPBBS-2379 selectExistingAttendeesByEventIds method to fetch all attendees in an event
 **/
public with sharing class BTAttendeeSelector extends BaseSelector {

	public BTAttendeeSelector() {
		super();
    }

    /**
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return conference360__Attendee__c.sObjectType;
	}

    /**
     * @description Select records filtered by IDs
     * @return List of conference360__Attendee__c records
     */
    public List<conference360__Attendee__c> selectById(Set<Id> idSet) {
		return (List<conference360__Attendee__c>) selectSObjectsById(idSet);
    }
    
    /**
     * @description Select records filtered by IDs
     * @return Map of conference360__Attendee__c records
     */
    public Map<Id, conference360__Attendee__c> selectMapById(Set<Id> idSet) {
		return new Map<Id, conference360__Attendee__c>(selectById(idSet));
    }

   /**
     * @description Returns attendees based on event Ids
     * @return List of conference360__Attendee__c records
     */
    public List<conference360__Attendee__c> selectExistingAttendeesByEventIds(Set<Id> eventIdSet) {
      String queryString = String.format(
          'SELECT Id,conference360__Contact__c,conference360__Event__c,conference360__Registration_Status__c FROM {0} WHERE conference360__Event__c IN :eventIdSet', 
          new List<String>{
                  getSObjectName()
          }
      );
      return (List<conference360__Attendee__c>) Database.query(queryString);
    }

  public List<conference360__Attendee__c> selectAttendeesByAttendeeGroupIds(Set<Id> attGroupIdSet) {
    String queryString = String.format(
        'SELECT Id, conference360__Attendee_Group__c, is_Primary_Registrant__c, conference360__Registration_Status__c FROM {0} WHERE conference360__Attendee_Group__c IN :attGroupIdSet', 
        new List<String>{
                getSObjectName()
        }
    );
    return (List<conference360__Attendee__c>) Database.query(queryString);
  }
  
  }