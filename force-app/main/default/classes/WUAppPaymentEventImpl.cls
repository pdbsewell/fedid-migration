/*
 * @author          Shalini Mendu
 * @description     Handler for WesternUnion payment gateway
 * @history         13/11/2018 - Initial version
 * @revision        02/01/2019 - Changed the severity levels on the Integration logs
 *                  21/07/2025 - Used the nebula logger framework for exception and debug logs. 
 */
 @SuppressWarnings('PMD.StdCyclomaticComplexity')
public with sharing class WUAppPaymentEventImpl extends AppPaymentEventInterface {
    static final string LOG_TAG = 'WUAppPaymentEventImpl';
        //Payment gateway method to process the event
        @SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity')
        public override void processIncomingEvents(InboundAppPayment__e ch) {
            List<Contact> cntList = new List<Contact>();
            List<Application__c> appList = new List<Application__c>();
            List<Id> ctIdList = new List<Id>();
            List<Id> appIdList = new List<Id>();
            List<Application__c> ctAppList = new List<Application__c>();
            List<Application__c> appAppList = new List<Application__c>();
            Map<String, Contact> idConMap = new Map<String, Contact>();
            AppPaymentRefLog appRefLog = new AppPaymentRefLog();
            @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult ')
            String contactPrefix = Contact.sobjecttype.getDescribe().getKeyPrefix();
            @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult ')
            String applicationPrefix = Application__c.sobjecttype.getDescribe().getKeyPrefix();

            Nebula.Logger.info('INSERT ' + String.valueOf(InboundAppPayment__e.class) + 'Received InboundAppPayment__e for Reference data: ' + ch.CRM_Reference__c +' ' + JSON.serializePretty(ch));
            
            if (String.isBlank(ch.CRM_Reference__c)) {
                Nebula.Logger.warn('INSERT' + ' ' + String.valueOf(InboundAppPayment__e.class) + 
                        'CRM Reference data not populated in the event. ' + 
                        JSON.serializePretty(ch)).addTag(LOG_TAG);               
            } else {
                if (ch.CRM_Reference__c.startsWith(contactPrefix)) {
                    //add all the ContactID's
                    ctIdList.add(ch.CRM_Reference__c);
                } else if (ch.CRM_Reference__c.startsWith(applicationPrefix)) {
                    //add all the ApplicationID's
                    appIdList.add(ch.CRM_Reference__c);
                } else {
                    Nebula.Logger.warn('INSERT' + ' ' + String.valueOf(InboundAppPayment__e.class) + 
                        'CRM Reference from the event is not a valid Application ID or Contact ID. ' + 
                        JSON.serializePretty(ch)).addTag(LOG_TAG);                    
                }
            }

            Nebula.Logger.debug('ctIdList==' + ctIdList+'appIdList=='+appIdList);
            //Payment gateway method to process the event
            try {
                //If the ContactId's list is populated
                if (ctIdList.size() > 0) {

                    cntList = [
                            SELECT ID, (
                                    SELECT ID,From_Portal__c,Status__c,
                                            Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                                            Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                                            Transaction_Amount__c
                                    FROM Applications__r
                                    WHERE From_Portal__c = true AND Status__c = 'Submitted'
                                    AND Fee_Amount__c = :ch.Settlement_Amount__c
                                    AND Fee_Waiver_Redeemed__c = null AND Fee_Payment__c = false
                                    order by CreatedDate limit 1
                            )
                            FROM CONTACT
                            WHERE ID = :ctIdList
                    ];

                    for (Contact con : cntList) {
                        idConMap.put((con.Id + '').substring(0, 15), con);
                    }
                    Nebula.Logger.debug('idConMap=' + idConMap + '&&&&' + idConMap.containsKey((ch.CRM_Reference__c).substring(0, 15)) + '::' + ch.CRM_Reference__c);
                    Map<String, Boolean> appFoundForRef = new Map<String, Boolean>();
                    String digit15Id = ch.CRM_Reference__c.substring(0, 15);
                    if (String.isNotBlank(ch.CRM_Reference__c)) {
                        if (idConMap.containsKey(digit15Id)) {
                            Contact con = idConMap.get(digit15Id);
                            
                            Nebula.Logger.debug('con.Applications__r=='+con);
                            //Populate the other fields on Application
                            for (Application__c app : con.Applications__r) {
                                app.Fee_Payment__c = true;
                                app.Transaction_Source__c = ch.Transaction_Source__c;
                                app.Transaction_Reference__c = ch.Transaction_Id__c;
                                app.Transaction_Date__c = convertStr2Dt(ch.Event_Reference__c);
                                app.Transaction_Amount__c = ch.Settlement_Amount__c;

                                appRefLog.logAppPaymentReference(con.Id, app.Id, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                        ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                        ch.Settlement_Amount__c, 'Processed', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                        ch.Transaction_Type__c);
                                appFoundForRef.put(ch.CRM_Reference__c, true);
                                ctAppList.add(app);
                                break;
                            }
                            Nebula.Logger.debug('Contact appFoundForRef==' + appFoundForRef);
                            if (!appFoundForRef.containsKey(ch.CRM_Reference__c)) {

                                appRefLog.logAppPaymentReference(con.Id, null, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                        ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                        ch.Settlement_Amount__c, 'No application found', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                        ch.Transaction_Type__c);
                            }
                        } else {
                                Nebula.Logger.warn('INSERT' + ' ' + String.valueOf(InboundAppPayment__e.class) + 
                                                    'No contact found for CRM Reference data. ' + 
                                                    JSON.serializePretty(ch)).addTag(LOG_TAG);                                
             }
                    }
                    update ctAppList;
                    //If the ApplicationId's list is populated
                } else if (appIdList.size() > 0) {
                    appList = [
                            SELECT ID,From_Portal__c,Status__c,
                                    Transaction_Source__c,Fee_Waiver_Redeemed__c,Fee_Payment__c,
                                    Transaction_Reference__c,Fee_Amount__c,Transaction_Date__c,
                                    Transaction_Amount__c,Applicant__r.Id
                            FROM Application__c
                            WHERE ID = :appIdList
                            AND From_Portal__c = true AND Status__c = 'Submitted'
                            AND Fee_Amount__c = :ch.Settlement_Amount__c
                            AND Fee_Waiver_Redeemed__c = null AND Fee_Payment__c = false
                            order by CreatedDate limit 1
                    ];
                    Nebula.Logger.debug('appList=='+appList);
                    Map<String, Boolean> appFoundForRef = new Map<String, Boolean>();
                    if (appList.size() > 0) {
                        //Populate the other fields on Application
                        for (Application__c app : appList) {
                            app.Fee_Payment__c = true;
                            app.Transaction_Source__c = ch.Transaction_Source__c;
                            app.Transaction_Reference__c = ch.Transaction_Id__c;
                            app.Transaction_Date__c = convertStr2Dt(ch.Event_Reference__c);
                            app.Transaction_Amount__c = ch.Settlement_Amount__c;
                            appAppList.add(app);
                            appFoundForRef.put(ch.CRM_Reference__c, true);
                            appRefLog.logAppPaymentReference(app.Applicant__r.Id, app.Id, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                    ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                    ch.Settlement_Amount__c, 'Processed', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                    ch.Transaction_Type__c);
                        }

                    }
                    Nebula.Logger.debug('App appFoundForRef=='+appFoundForRef);
                    if (!appFoundForRef.containsKey(ch.CRM_Reference__c)) {

                        appRefLog.logAppPaymentReference(null, null, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                ch.Settlement_Amount__c, 'No application found', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                ch.Transaction_Type__c);
                        Nebula.Logger.warn('INSERT' + ' ' + String.valueOf(InboundAppPayment__e.class) + 
                                                    'No application found for CRM Reference data. ' + 
                                                    JSON.serializePretty(ch)).addTag(LOG_TAG);                        
                    }

                    update appAppList;
                }
        }catch(Exception ex)
        {
            Nebula.logger.error(ex.getMessage()+'::'+ex.getLineNumber()+'::'+ex.getCause() +ex.getStackTraceString() + ' ' + 
                JSON.serializePretty(ch)).addTag(LOG_TAG);               
        }finally{
                Nebula.logger.saveLog();
                appRefLog.log_insert();
        }
    }
}