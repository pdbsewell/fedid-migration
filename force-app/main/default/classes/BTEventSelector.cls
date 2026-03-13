/**
 * @author       : Ibrahim Rumi
 * @date         : 21-06-2022
 * @group        : Event Management
 * @description  : Selector class for conference360__Event__c object (Blackthorn)
**/

public with sharing class BTEventSelector extends BaseSelector {

	public BTEventSelector() {
		super();
    }

    /**
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return conference360__Event__c.sObjectType;
	}

    /**
     * @description Select records filtered by IDs
     * @return List of conference360__Event__c records
     */
    public List<conference360__Event__c> selectById(Set<Id> idSet) {
		return (List<conference360__Event__c>) selectSObjectsById(idSet);
    }
    
    /**
     * @description Select records filtered by IDs
     * @return Map of conference360__Event__c records
     */
    public Map<Id, conference360__Event__c> selectMapById(Set<Id> idSet) {
		return new Map<Id, conference360__Event__c>(selectById(idSet));
    }

   /**
     * @description Returns events and event settings based on event Ids
     * @return List of conference360__Event__c records
     */
    public Map<Id,conference360__Event__c> selectExistingEventSettingsByEventIds(Set<Id> eventIdSet) {
      String queryString = String.format(
          'SELECT Id,conference360__Event_Settings__c,conference360__Event_Settings__r.Automate_Event_Item_Creation__c FROM {0} WHERE Id IN :eventIdSet', 
          new List<String>{
                  getSObjectName()
          }
      );
      return (new Map<Id, conference360__Event__c>((List<conference360__Event__c>) Database.query(queryString)));
    }
  
    /**
     * @description Returns events and event Items based on event Ids
     * @return List of conference360__Event__c records
     */
    public Map<Id,conference360__Event__c> selectExistingEventItemsByEventIds(Set<Id> eventIdSet) {
      String queryString = String.format(
          'select id,(select id,conference360__Type__c from conference360__Event_Items__r) FROM {0} WHERE Id IN :eventIdSet', 
          new List<String>{
                  getSObjectName()
          }
      );
      return (new Map<Id, conference360__Event__c>((List<conference360__Event__c>) Database.query(queryString)));
    }

  }