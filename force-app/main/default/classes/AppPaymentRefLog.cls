/*
 * @author          Shalini Mendu
 * @description     Class for logging AppPaymentReference__c
 * @history         13/11/2018 - Initial version
 */
public with sharing class AppPaymentRefLog {
    public List<AppPaymentReference__c> log_list;

    public AppPaymentRefLog() {
        log_list = new List<AppPaymentReference__c>();
    }
    //Method to populate and log  AppPaymentReference__c
    public  void logAppPaymentReference(Id conId, Id appId, String CRMRef, String email,String evRef, String fName,
            String lName,String payerName,String phone, Decimal serviceAmt, Decimal settleAmt,
            String status, String transId, String transSrc, String transType
    )
    {
        AppPaymentReference__c ref = new AppPaymentReference__c();
        ref.Application__c = appId;
        ref.Contact__c = conId;
        ref.CRM_Reference__c = CRMRef;
        ref.Email__c = email;
        ref.Event_Reference__c = evRef;
        ref.First_Name__c = fName;
        ref.Last_Name__c = lName;
        ref.Payer_Name__c = payerName;
        ref.Phone__c = phone;
        ref.Service_Amount__c = serviceAmt;
        ref.Settlement_Amount__c = settleAmt;
        ref.Status__c =  status;
        ref.Transaction_Id__c = transId;
        ref.Transaction_Source__c =  transSrc;
        ref.Transaction_Type__c = transType;
        log_list.add(ref);
    }
    //insert the list of logs
    public void log_insert() {
        if(log_list.size() > 0) {
            try {
                insert log_list;
            } catch (Exception e) {
             throw e;
            }
        }

        log_list = new List<AppPaymentReference__c>();
    }
}