/**
@author Ryan Wilson
@date 10 November 2017
@group Professional Development
@description Class for Payment trigger processes
@revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
**/

public without sharing class PaymentServices {

    // Declare constant variable to store Magento Settings dataset name
    public static final String MAGENTO_SETTINGS_DATASET_NAME = 'PD Payment Integration';
	
    /**
    @description Method for updating payment status based on Magento status
    @param Old and new record maps from trigger
    @revision 8 April 2021 - Cartick Sub - PRODEV-476 - Migrate Magento data from custom labels to custom settings
    **/
	public static void updatePaymentStatus(List<Payment__c> payments, Map<Id, Payment__c> mapOldPayments) {

        // Get Magento custom settings
        Magento_Settings__c magentoSettings = Magento_Settings__c.getValues(MAGENTO_SETTINGS_DATASET_NAME);

        if (magentoSettings != null) { // Enter Payment update loop only if Magento Settings have a dataset
            for(Payment__c pay: payments){
                System.debug('*** new : ' + pay);
                System.debug('*** old : ' + mapOldPayments.get(pay.Id));
                if(pay.Processor_Status__c != mapOldPayments.get(pay.Id).Processor_Status__c){
                    System.debug('***Updating Payment Status...');
                    if(pay.Processor_Status__c == magentoSettings.MagentoStatus_Paid__c){
                        System.debug('***Updating Payment Status to Processed...');
                        pay.Payment_Status__c = 'Processed';
                        pay.Payment_Date__c = System.now();
                    }

                    else if(pay.Processor_Status__c == magentoSettings.MagentoStatus_Refunded__c){
                        System.debug('***Updating Payment Status to Refund Processed...');
                        pay.Payment_Status__c = 'Refund Processed';
                        pay.Payment_Amount__c = 0.00;
                    }
                }
            }
        }
	}

	/**
	 * @author: Vineeth Batreddy
	 * @description: Send email receipt to the students manually [only for Offline Registration Payments]
	 * @history: 22/09/2017 - Vineeth Batreddy - Original code 
	 *           22/10/2018 - Nadula Karunaratna - Added reading off BCC email from Custom Metadata Type [Multi Faculty Capability]
	 *           30/05/2019 - Nadula Karunaratna - Added dynamic contact details to the signature [PRODEV-369]
	 			 14/06/2019 - Nadula Karunaratna - Restructured the original code by moving from PaymentTrigger.trigger
	 			 								 - Updated contact details to be read from "Faculty Custom Data" custom metadata type
	 			 								 - Removed Chargent related exception log insertion code (was commented out)
	 */
	public static void generatePaymentReceipt(List<Payment__c> payments, Map<Id, Payment__c> mapNewPayments, Map<Id, Payment__c> mapOldPayments){

        List<String> paymentIds = new List<String>();
        for(Payment__c pay : payments) {
            paymentIds.add(pay.Id);
        }

		System.debug('*** generatePaymentReceipt.paymentIds : ' + paymentIds);
        
        // get faculties from payments and put info into a set
        Set<String> facultySet = new Set<String>();
        Payment__c pmt = new Payment__c();
        String pmtFaculty = '';
        for(String strId : paymentIds) {
            pmt = mapNewPayments.get(strId);
            pmtFaculty = pmt.Course_Faculty__c;
            if (String.isNotBlank(pmtFaculty)) {
                facultySet.add(pmtFaculty);
            }
        }

        //Read Custom Metadata Type for CC Email
        List<Faculty_Custom_Data__mdt> facultyConfigList = [SELECT Faculty_Student_Email_CC__c,Managing_Faculty__c,Faculty_Email__c,Faculty_Phone__c,Faculty_Website__c FROM Faculty_Custom_Data__mdt where Managing_Faculty__c IN :facultySet]; 

        EmailTemplate template = [Select Id, Subject, HtmlValue from EmailTemplate where DeveloperName = 'Enrolment_Payment_Receipt'];
        OrgWideEmailAddress senderEmail = [SELECT Address,DisplayName,Id FROM OrgWideEmailAddress WHERE DisplayName = 'Monash Student Global'];
        Id studentGlobalId = senderEmail.Id;

        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();

        for(Payment__c payment : [SELECT Id, Name, Payment_Date__c, Payment_Status__c, Send_Receipt__c, Online_Registration__c, Contact__c, Contact__r.Name, Company_Name__c, Street__c, Suburb__c, State__c, Postcode__c, Quantity__c, Course_Title__c, Amount_Ex_GST__c, GST_Allocation__c, Payment_Amount__c, Payment_Type__c, Course_Offering__r.Apply_GST__c, Course_Faculty__c FROM Payment__c WHERE Id IN:paymentIds]) {
            if(
                (Trigger.isUpdate && payment.Send_Receipt__c == true && 
                    mapOldPayments.get(payment.Id).Send_Receipt__c == false && 
                    payment.Online_Registration__c == false) ||
                (Trigger.isInsert && 
                    payment.Send_Receipt__c == true && 
                    payment.Online_Registration__c == false)

            ){

	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            mail.setOrgWideEmailAddressId(studentGlobalId);
	            mail.setTargetObjectId(payment.Contact__c);
                
                for (Faculty_Custom_Data__mdt facultyConfig : facultyConfigList) {
                    if (payment.Course_Faculty__c.equalsIgnoreCase(facultyConfig.Managing_Faculty__c)) {
                        
        	            /*** Construct email ***/
                        
                        // check for presence of emails
                        if((facultyConfig.Faculty_Student_Email_CC__c != '') && (facultyConfig.Faculty_Student_Email_CC__c != null)){
                            List<String> bccAddresses = new List<String>();
                            bccAddresses.add(facultyConfig.Faculty_Student_Email_CC__c);
                            mail.setBccAddresses(bccAddresses);
                        }
                        
                        mail.setSaveAsActivity(false);

                        // Merge Template fields
                        mail.setSubject(template.Subject);
                        
                        String htmlBody = template.HtmlValue;
                        htmlBody = htmlBody.replace('{!relatedTo.Name}', payment.Name);
                        
                        DateTime pDate = System.now();
                        String paymentDate = pDate.format('dd/MM/yyyy HH:mm','Australia/Melbourne');
                        if(payment.Payment_Date__c != null) {
                            paymentDate = payment.Payment_Date__c.format('dd/MM/yyyy HH:mm','Australia/Melbourne');
                        }               
                        htmlBody = htmlBody.replace('{!relatedTo.Payment_Date__c}', paymentDate);
                        
                        String name = '';
                        if(String.isNotBlank(payment.Company_Name__c)) {
                            name = payment.Company_Name__c;
                        } else {
                            name = payment.Contact__r.Name;
                        }
                        
                        // Payment amount to show on receipt
                        String paymentAmount = '';
                        String paymentAmountPrefix = '';
                        String paymentAmountOnReceipt = '';
                        if(payment.Payment_Amount__c != null) {
                            if(payment.Payment_Amount__c < 0) {
                                paymentAmountPrefix = '-';    
                            }
                            paymentAmount = String.valueOf(System.Math.abs(payment.Payment_Amount__c));
                        }
                        paymentAmountOnReceipt = paymentAmountPrefix + '$' + paymentAmount;
                        
                        
                        // Payment amount excluding GST to show on receipt
                        String amountExGst = '';
                        String amountExGstPrefix = '';
                        String amountExGstOnReceipt = '';
                        if(payment.Amount_Ex_GST__c != null) {
                            if(payment.Amount_Ex_GST__c < 0) {
                                amountExGstPrefix = '-';    
                            }
                            amountExGst = String.valueOf(System.Math.abs(payment.Amount_Ex_GST__c));
                        }
                        amountExGstOnReceipt = amountExGstPrefix + '$' + amountExGst;
                                              
                        // Payment amount GST to show on receipt
                        String gst = '';
                        String gstPrefix = '';
                        String gstOnReceipt = '';
                        if(payment.Course_Offering__r.Apply_GST__c && payment.Payment_Amount__c != null) {
                            Decimal gstAmount = payment.Payment_Amount__c;
                            gstAmount = (gstAmount - (gstAmount/1.1)).setScale(2);
                            if(gstAmount < 0) {
                                gstPrefix = '-';    
                            }   
                            gst = String.valueOf(System.Math.abs(gstAmount));
                        }  
                        else {
                            gst = '0';
                        }
                        gstOnReceipt = gstPrefix + '$' + gst;
                        
                        htmlBody = htmlBody.replace('{{contactName}}', name);
                        htmlBody = htmlBody.replace('{!relatedTo.Street__c}', payment.Street__c);
                        htmlBody = htmlBody.replace('{!relatedTo.Suburb__c}', payment.Suburb__c);
                        htmlBody = htmlBody.replace('{!relatedTo.State__c}', payment.State__c);
                        htmlBody = htmlBody.replace('{!relatedTo.Postcode__c}', payment.Postcode__c);
                        
                        htmlBody = htmlBody.replace('{!relatedTo.Quantity__c}', String.valueOf(payment.Quantity__c));
                        htmlBody = htmlBody.replace('{!relatedTo.Course_Title__c}', payment.Course_Title__c);
                        htmlBody = htmlBody.replace('{!relatedTo.Payment_Type__c}', String.valueOf(payment.Payment_Type__c));
                        
                        htmlBody = htmlBody.replace('${!relatedTo.Payment_Amount__c}', paymentAmountOnReceipt);
                        htmlBody = htmlBody.replace('${!relatedTo.Amount_Ex_GST__c}', amountExGstOnReceipt);
                        htmlBody = htmlBody.replace('${!relatedTo.GST_Allocation__c}', gstOnReceipt);

                        //Getting faculty specific contact data                      
                        htmlBody = htmlBody.replace('{TEMPLATE.FacultyName}', String.valueOf(payment.Course_Faculty__c));
                        htmlBody = htmlBody.replace('{TEMPLATE.FacultyEmail}', String.valueOf(facultyConfig.Faculty_Email__c));
                        htmlBody = htmlBody.replace('{TEMPLATE.FacultyPhone}', String.valueOf(facultyConfig.Faculty_Phone__c));
                        htmlBody = htmlBody.replace('{TEMPLATE.FacultyWebsite}', String.valueOf(facultyConfig.Faculty_Website__c));
                        
                        mail.setHtmlBody(htmlBody);
                        allmsg.add(mail);
                    }
                }
            }   
        }

        if(allmsg.size() >0){
			Messaging.sendEmail(allmsg);
        }
	}
}