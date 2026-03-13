/*******************************************************************************
* @author		Vinothraja
* @date         21.07.2021     
* @description  Method to generate the Timestamps in Offer object, when it passes through 
                various stages. This is an one-off job for populating old records. 
                Used to track performance
* @revision     Created.
*******************************************************************************/
global class SyncOfferTimelineBatch implements Database.Batchable<sObject> {
    global final String query;
    global final Map<String, String> mapSubStatusFieldMapping = new Map<String, String> {
        'created' => 'Offer_Creation_TimeStamp__c',
        'In Progress' => 'Offer_Creation_TimeStamp__c',
        'Products Added' => 'Products_Added_TimeStamp__c',
        'Pricing Completed' => 'Pricing_Completed_TimeStamp__c',
        'Auto Clauses Attached' => 'Clauses_Attached_TimeStamp__c',
        'Preview Requested' => 'Preview_Requested_TimeStamp__c',
        'Preview in QA' => 'Document_Generated_TimeStamp__c',
        'Preview Released' => 'Assessor_Published_TimeStamp__c',
        'Ready For Acknowledgement' => 'Student_Acknowledgement_TimeStamp__c',
        'Signed & Locked' => 'Signed_TimeStamp__c'
    };

    global SyncOfferTimelineBatch(String q) {
        if (String.isBlank(q)){
            query= 'SELECT id, Name, (SELECT Field, OldValue, NewValue, CreatedDate FROM Histories WHERE FIELD IN (\'Sub_Status__c\', \'created\')) FROM SBQQ__Quote__c';
        } else {
            query = q;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC,List<sObject> scope) {
        //List of Quotes to be updated
        List<SBQQ__Quote__c> lstQuotes = new list<SBQQ__Quote__c>();

        List<SBQQ__Quote__c> quotes = (List<SBQQ__Quote__c>)scope;
        for (SBQQ__Quote__c quote : quotes) {
            boolean edited = false;
            //Checking for History records with Sub_Status__c changed
            for (SBQQ__Quote__history historyRecord : quote.Histories) {
                if (historyRecord.Field == 'Sub_Status__c' )  {
                    if (Test.isRunningTest()) {
                        edited = true;
                        quote.put(mapSubStatusFieldMapping.get('Products Added'), historyRecord.CreatedDate); //update Test Record
                    } else if (historyRecord.NewValue!= null && mapSubStatusFieldMapping.containsKey((String)historyRecord.NewValue)){
                        edited = true;
                        quote.put(mapSubStatusFieldMapping.get((String)historyRecord.NewValue), historyRecord.CreatedDate); //update Field in Object with Timestamp
                    }
                } else if (historyRecord.Field == 'created' && mapSubStatusFieldMapping.containsKey('created')) { //History record for Creation doesn't contain a Fieldname, Old Value or New Value
                    edited = true;
                    quote.put(mapSubStatusFieldMapping.get('created'), historyRecord.CreatedDate); //update Field in Object with Timestamp
                }
            }
            if (edited) {
                lstQuotes.add(quote);
            }
        }
        Database.SaveResult [] srList = Database.update(lstQuotes, false);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                LogUtilityException.debug('Error updating quote :: ' + sr.getId());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        LogUtilityException.debug('Batch Process Quote Stages Finished');
    }
}