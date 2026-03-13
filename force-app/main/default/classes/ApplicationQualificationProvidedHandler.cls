/**
 * @description Trigger handler class for Application_Qualification_Provided__c.
 * @author Sravani Naramsetti
 * @date JUL.18.2025
 */
public with sharing class ApplicationQualificationProvidedHandler {
    /**
     * @description When Application Status is changed update it on Contact Qualification
     */
    public class PopulateApplicationStatus extends TriggerAbstract {

        public override void process(SObject record) {

            Application_Qualification_Provided__c newAqp = (Application_Qualification_Provided__c) record;

            /**
             * invoke when AQP with Application and Contact Qual inserted
             */
            if(newAqp.Contact_Qualification__c!=null && newAqp.Application__c!=null){
                records.add(newAqp);
            }
        }

        /**
        * @description Execute Trigger
        * @author
        **/
        public override void execute() {
            if(!records.isEmpty()) {
                try {
                    List<Contact_Qualification__c> contQualList=new List<Contact_Qualification__c>();
                    Set<Id> appIds=new Set<Id>();
                    Map<Id,String> appStat=new Map<Id,String>();
                    for(Application_Qualification_Provided__c aqp: (List<Application_Qualification_Provided__c>) records){
                        appIds.add(aqp.Application__c);
                    }
                    for(Application__c app:[Select Id, Status__c from Application__c where ID IN: appIds]){
                        appStat.put(app.Id,app.Status__c);
                    }
					for(Application_Qualification_Provided__c aqp:(List<Application_Qualification_Provided__c>) records){
                        Contact_Qualification__c cq=new Contact_Qualification__c();
                        cq.Id=aqp.Contact_Qualification__c;
                        cq.Application_Status__c=appStat.get(aqp.Application__c);
                        contQualList.add(cq);
                    }
                    if(!contQualList.isEmpty()){
                        update contQualList;
                    }
                } catch(Exception e) {
                    Nebula.Logger.error('An unexpected error occurred while trying to update App Status on Contact Qualification', e)
                                .addTag('Contact Qualification');
                }
                Nebula.Logger.saveLog();
            }
        }
    }

}