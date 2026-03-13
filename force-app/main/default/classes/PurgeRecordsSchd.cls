/*
 * @author          Shalini Mendu
 * @date			23/03/2020
 * @group			Admissions
 * @description     Scheduler to pick all the purge records from the Custom Metadata type
 * @revision        6/05/2019  - Shalini Mendu - Initial version	
 *                  23/03/2020 - Stefan Scheit - Replaced (unnecessary) exception log record entry with a standard debug method
 * 					22/03/2021 - Martin Cadman - Re-introduced exception logging to track records being removed
 *                  10/02/2022 - Shalini Mendu - Rewriting code to process 25 records each time and to kick off Batchable- SFTG-2366 
 */
public without sharing class PurgeRecordsSchd implements Schedulable {
   
    public static Integer BATCHSIZE = 25; 
    public void execute(SchedulableContext sc) 
    {
         List<Purge_Recs__mdt> mdtList = [SELECT Id,Object__c, Older_than__c,BatchSize__c, Filter_Criteria__c,Filter_By_Date__c, label, Order_By__c, Limit__c FROM Purge_Recs__mdt
                                          WHERE  Active__c = true];
       
        if(!mdtList.isEmpty()) 
        {
            Database.executeBatch(new PurgeRecordsBatch(mdtList[0], mdtList), mdtList[0].BatchSize__c!=null?Integer.valueOf(mdtList[0].BatchSize__c): BATCHSIZE);
        }
    }
}