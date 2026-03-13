/**
 * @description Trigger handler class for Application_Work_Experience_Provided__c.
 * @author Sravani Naramsetti
 * @date JUL.30.2025
 */
public with sharing class ApplicationWorkExpProvidedHandler {
    /**
     * @description When Application_Work_Experience_Provided__c is created update it on Work_Experience__c
     */
    public class PopulateApplicationStatus extends TriggerAbstract {

        public override void process(SObject record) {

            Application_Work_Experience_Provided__c newAwep = (Application_Work_Experience_Provided__c) record;

            /**
             * invoke when AWEP with Application and Work Experience inserted
             */
            if(newAwep.Work_Experience__c!=null && newAwep.Application__c!=null){
                records.add(newAwep);
            }
        }

        /**
        * @description Execute Trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    List<Work_Experience__c> workExpList=new List<Work_Experience__c>();
                    Set<Id> appIds=new Set<Id>();
                    Set<Id> wrkExpIds=new Set<Id>();
                    Map<Id,String> appStat=new Map<Id,String>();
                    Map<Id,String> wrkExpStat=new Map<Id,String>();
                    Set<Id> wrkExpExists=new Set<Id>();
                    
                    for(Application_Work_Experience_Provided__c awep: (List<Application_Work_Experience_Provided__c>) records){
                        appIds.add(awep.Application__c);
                        wrkExpIds.add(awep.Work_Experience__c);
                    }
                    for(Application__c app:[Select Id, Status__c from Application__c where ID IN: appIds]){
                        appStat.put(app.Id,app.Status__c);
                    }
                    for(Work_Experience__c we:[Select Id, Application_Status__c from Work_Experience__c where ID IN: wrkExpIds]){
                        wrkExpStat.put(we.Id,we.Application_Status__c);
                    }
                    for(Application_Work_Experience_Provided__c awep:[Select id, Work_Experience__c from Application_Work_Experience_Provided__c where Work_Experience__c IN: wrkExpIds]){
                   		wrkExpExists.add(awep.Work_Experience__c);
                    }
					for(Application_Work_Experience_Provided__c awep:(List<Application_Work_Experience_Provided__c>) records){
                        if(!wrkExpExists.contains(awep.Work_Experience__c)){
                            Work_Experience__c we=new Work_Experience__c();
                            we.Id=awep.Work_Experience__c;
                            we.Application_Status__c=appStat.get(awep.Application__c);
                            workExpList.add(we);
                        }else{
                            if(wrkExpStat.get(awep.Work_Experience__c)!='Submitted' && appStat.get(awep.Application__c)!='Draft'){
                                Work_Experience__c we=new Work_Experience__c();
                                we.Id=awep.Work_Experience__c;
                                we.Application_Status__c=appStat.get(awep.Application__c);
                                workExpList.add(we);
                            }
                        }
                        
                    }
                    if(!workExpList.isEmpty()){
                        update workExpList;
                    }
                } catch(Exception e) {
                    Nebula.Logger.error('An unexpected error occurred while trying to update App Status on Work Experience', e)
                                .addTag('Work Experience');
                }
                Nebula.Logger.saveLog();
            }
        }
    }

}