/**
* @description  Apex batch job to create donor IDs.
*
* @author:      Ken Tang
* @date:        July 29, 2019
*/  

global class Batch_CreateDonorIds implements Database.Batchable<sObject> {
    
    global String query;
    global String objectName;

   /**
    * @description  Generate Donor IDs that will be used to assign to contacts/organisations.
    * 
    * @param num    Number of contacts or organisations that needs Donor IDs.
    */ 
    public static List<String> generateDonorIDs(Integer num) {
        Savepoint sp = Database.setSavepoint();
        List<ucinn_ascendv2__Donor_ID__c> crsIdList = new List<ucinn_ascendv2__Donor_ID__c>();

        for (Integer i = 0; i < num ; i++) {
            crsIdList.add(new ucinn_ascendv2__Donor_ID__c());
        }

        List<String>idList = new List<String>();

        insert crsIdList;
        
        //Boolean overrideExists = fieldExists('Donor_ID_Auto_Number_Override__c');
        Boolean overrideExists = false;
        
        String queryFieldNames;
        
        if (overrideExists) {
            queryFieldNames = 'Id, Name, Donor_ID_Auto_Number_Override__c';
        }
        else {
            queryFieldNames = 'Id, Name, ucinn_ascendv2__Donor_ID_Auto_Number__c';
        }
        
        String queryStr = 'SELECT ' + queryFieldNames + ' FROM ucinn_ascendv2__Donor_ID__c WHERE Id in :crsIdList';
        
        List<SObject> donorIdList = Database.query(queryStr);
        
        //system.debug('donorIdList: ' + donorIdList);
        
        String donorId;
        
        for (SObject donorIdRec : donorIdList) {               
            if (overrideExists) {
                donorId = (String)donorIdRec.get('Donor_ID_Auto_Number_Override__c');
            }
            else {
                donorId = (String)donorIdRec.get('ucinn_ascendv2__Donor_ID_Auto_Number__c');
            }
            
            idList.add(donorId);
        }

        // Rollback insert so that we dont have excess data
        Database.rollback(sp);

        return idList;
    }

   /**
    * @description  Starts the batch job.
    * 
    * @param bc     The batchable context associated with the Apex batch job.
    */ 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (String.isBlank(query)) {
            query = 'SELECT Id, ucinn_ascendv2__Donor_ID__c FROM ' + objectName + ' WHERE ucinn_ascendv2__Donor_ID__c = null';
        } 
        
        return Database.getQueryLocator(query);
    }

   /**
    * @description  Executes the batch job.  Basically, creates the donor IDs for contacts/organisations.
    * 
    * @param bc     The batchable context associated with the Apex batch job.
    * @param scope  The list of contacts, broken up into batches.
    */ 
    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        List<String> newCRSIds = generateDonorIDs(scope.size());
        
        system.debug('newCRSIds: ' + newCRSIds);

        Integer i = 0;
        
        for (SObject sObj : scope) {
            sObj.put('ucinn_ascendv2__Donor_ID__c', newCRSIds[i]);
            i++;
        }
        
        //database.update(scope, false);
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(objectName, false);
        update scope;
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger(objectName, true);
    }

   /**
    * @description  Finishes the batch job.  Here, does nothing.
    * 
    * @param bc     The batchable context associated with the Apex batch job.
    */ 
    global void finish(Database.BatchableContext BC) {
        
    }
}