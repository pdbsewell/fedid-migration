/**
 * @author Ibrahim Rumi
 * @date 12.02.2022
 * @group Event Management
 * @description Selector class for conference360__Session__c object (Blackthorn)
 **/
public with sharing class BTSessionSelector extends BaseSelector {

	public BTSessionSelector() {
		super();
    }
     /**
     * @description Returns the object type
     */
	public Schema.SObjectType getSObjectType() {
		return conference360__Session__c.sObjectType;
	}

     /**
     * @description Select records filtered by Event IDs
     * @return List of conference360__Session__c records
     */
    public List<conference360__Session__c> selectById(Set<Id> eventIds) {
        String queryString = String.format(
          'SELECT Id FROM {0} WHERE conference360__Event__c IN :eventIds',
          new List<String>{
                  getSObjectName()
          }
      );
      return (List<conference360__Session__c>) Database.query(queryString);
    }
}