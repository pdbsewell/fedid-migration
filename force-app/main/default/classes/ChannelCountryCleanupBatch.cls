/**
* @author Stephen :oi
* @date 29.Nov.2022
* @group Batch Class
* @description  Batch Class to query Channel records where there is no country value, but has Line 4 as Country. Cleaning them using CountryServices.getISOCountryName and update the Country__c picklist. Note CountryServices.getISOCountryName will invoke a SOQL with limit clause to 1, therefore caution with batch size when invoking this class.
 * 2023-02-20   Ken McGuire   - Updated signature for get country services method
*/
public without sharing class ChannelCountryCleanupBatch implements Database.Batchable<SObject> {
    public String query;

    public ChannelCountryCleanupBatch() {
        this.query = 'SELECT Id, Country__c, Line_4__c FROM Channel__c WHERE Country__c = null AND Line_4__c != null AND is_Active__c = true';
    }

    public ChannelCountryCleanupBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC,List<SObject> scope) {
        List<Channel__c> channelsToUpdate = new List<Channel__c>();

        for(Channel__c channel : (List<Channel__c>) scope) {
            String isoCounty = CountryServices.getCountryName(channel.Line_4__c,CountryServices.FORMAT_ISO);
            if (!String.isBlank(isoCounty)) {
                channel.Country__c = isoCounty;
                channel.Is_Processed__c = false;
                channelsToUpdate.add(channel);
            }
        }

        update channelsToUpdate;
    }

    public void finish(Database.BatchableContext BC){}
}