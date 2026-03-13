/*
 * @author          Shalini Mendu
 * @description     Implementation for Convera payment gateway interface
 * @date  14/01/2025
 */
public with sharing class ConveraPaymentEventImpl extends ConveraPaymentEventInterface {
    //Declare private logging variables
    private static final String REFTAG   = 'Convera Payment Implementation';
    private static final String SCENARIO = 'ConveraPaymentEventImpl';
    Nebula.LogMessage logMsg;

    // Different log message formats    
    private static String msgfmt2 = '{0}\r\r{1}';
    private static String msgfmt3 = '{0} - {1}\r\r{2}';
    AppPaymentRefLog appRefLog = new AppPaymentRefLog();
    Map<String, Boolean> appFoundForRef = new Map<String, Boolean>();

    //Payment gateway method to process the event
    public override void processIncomingEvents(IbdConveraPayment__e ch) {
        List<Application__c> appList = new List<Application__c>();
        List<Id> ctIdList = new List<Id>();
        List<Id> appIdList = new List<Id>();
        List<Application__c> appAppList = new List<Application__c>();
        // Set logging to ConveraPaymentEventImpl, which controls the default logging level etc.
        // See the Logger Scenario
        Nebula.Logger.setScenario(SCENARIO);  
        // Log immediately
        logMsg = new Nebula.LogMessage(msgfmt3, 'INSERT/' + 'CRM Reference data not populated in the event.', String.valueOf(IbdConveraPayment__e.class)  , JSON.serializePretty(ch));
        Nebula.logger.info(logMsg);

        if (String.isBlank(ch.CRM_Reference__c)) {
                // Log immediately if the payload does not have CRM_Reference__c
                logMsg = new Nebula.LogMessage(msgfmt3, 'INSERT/'+'CRM Reference data not populated in the event.' , String.valueOf(IbdConveraPayment__e.class),  JSON.serializePretty(ch));
                Nebula.logger.warn(logMsg).addTag(REFTAG);
        } else {
            if (ch.CRM_Reference__c.startsWith(Schema.SObjectType.Contact.getKeyPrefix())) {
                //add all the ContactID's
                ctIdList.add(ch.CRM_Reference__c);
            } else if (ch.CRM_Reference__c.startsWith(Schema.SObjectType.Application__c.getKeyPrefix())) {
                //add all the ApplicationID's
                appIdList.add(ch.CRM_Reference__c);
            } else {
               // Log immediately
               logMsg = new Nebula.LogMessage(msgfmt3, 'INSERT/'+ 'CRM Reference from the event is not a valid Application ID or Contact ID.' ,String.valueOf(IbdConveraPayment__e.class), JSON.serializePretty(ch));
               Nebula.logger.warn(logMsg).addTag(REFTAG);
            }
        }

        //Payment gateway method to process the event
        try {
            //If the ContactId's list is populated
            if (ctIdList.size() > 0) {
                updateApplicationByContactId(ctIdList, ch);     
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
                //If the Platform event contains reference to the CRM Reference(ContactId)
                if (!appFoundForRef.containsKey(ch.CRM_Reference__c)) {
                    appRefLog.logAppPaymentReference(null, null, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                            ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                            ch.Settlement_Amount__c, 'No application found', ch.Transaction_Id__c, ch.Transaction_Source__c,
                            ch.Transaction_Type__c);
                    
                    logMsg = new Nebula.logMessage(msgfmt2, 'INSERT/' + 'No application found for CRM Reference data.', JSON.serializePretty(ch));
                    Nebula.logger.warn(logMsg).addTag(REFTAG);
                }
                update appAppList;
            }
        }catch(Exception ex)
        {       logMsg = new Nebula.logMessage(msgfmt2, 'INSERT',
                'Unhandled exception:'+ex.getMessage()+'::'+ex.getLineNumber()+'::'+ex.getCause() +ex.getStackTraceString()+
                JSON.serializePretty(ch));
                Nebula.logger.error(logMsg, ex);
        }finally{
            Nebula.logger.saveLog();
            appRefLog.log_insert();
        }
    }
 
  /*
  * @description Update Application field value searching by ContactId
  * @param  ctIdList - ContactId List
  * @param  ch - IbdConveraPayment__e 
  * @date  14/01/2025
  */
    public void updateApplicationByContactId(List<Id> ctIdList, IbdConveraPayment__e ch)
    {
            List<Contact> cntList = new List<Contact>();
            List<Application__c> ctAppList = new List<Application__c>();
            Map<String, Contact> idConMap = new Map<String, Contact>();
            //List of Applications with Submitted status matching the Fee amount 
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

            //Populate a map with Contact Id 15 digit and the actual record
            for (Contact con : cntList) {
                idConMap.put((con.Id + '').substring(0, 15), con);
            }
            //15 digit Id
            String digit15Id = ch.CRM_Reference__c.substring(0, 15);
            //CRM_Reference__c not blank
            if (String.isNotBlank(ch.CRM_Reference__c)) {
                if (idConMap.containsKey(digit15Id)) {
                    Contact con = idConMap.get(digit15Id);
                    //Populate the other fields on Application
                    for (Application__c app : con.Applications__r) {
                        app.Fee_Payment__c = true;
                        app.Transaction_Source__c = ch.Transaction_Source__c;
                        app.Transaction_Reference__c = ch.Transaction_Id__c;
                        app.Transaction_Date__c = convertStr2Dt(ch.Event_Reference__c);
                        app.Transaction_Amount__c = ch.Settlement_Amount__c;
                        //Log AppPaymentReference__c fields
                        appRefLog.logAppPaymentReference(con.Id, app.Id, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                ch.Settlement_Amount__c, 'Processed', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                ch.Transaction_Type__c);
                        appFoundForRef.put(ch.CRM_Reference__c, true);
                        ctAppList.add(app);
                        break;
                    }
                    if (!appFoundForRef.containsKey(ch.CRM_Reference__c)) {
                            //Log AppPaymentReference__c fields when No application found
                        appRefLog.logAppPaymentReference(con.Id, null, ch.CRM_Reference__c, ch.Email__c, ch.Event_Reference__c,
                                ch.First_Name__c, ch.Last_Name__c, ch.Payer_Name__c, ch.Phone__c, ch.Service_Amount__c,
                                ch.Settlement_Amount__c, 'No application found', ch.Transaction_Id__c, ch.Transaction_Source__c,
                                ch.Transaction_Type__c);
                    }
                } else {
                        //Log immediately
                    logMsg = new Nebula.LogMessage(msgfmt3, 'INSERT/' + 'No contact found for CRM Reference data.', String.valueOf(IbdConveraPayment__e.class),  JSON.serializePretty(ch));
                    Nebula.logger.warn(logMsg).addTag(REFTAG);
                }
            }
            update ctAppList;
    }

  
}