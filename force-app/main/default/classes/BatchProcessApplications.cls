global class BatchProcessApplications implements Database.Batchable<sObject> {
    
    global final String query;

    global BatchProcessApplications(String q) {
        query=q;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC,List<sObject> scope) {
        
        List<Application__c> applicationsToProcess = new list<Application__c>();

        List<Application__c> applications = (List<Application__c>)scope;
        List<String> legacyApplicationIds = new List<String>();
        List<String> legacyEnquiryIds = new List<String>();
        List<String> legacyCourseOfferingIds = new List<String>();

        // Prepare record ids of ACPs and Enquirires to fetch
        for(Application__c application : applications) {
            if(application.Legacy_Application_ID__c != null)
                legacyApplicationIds.add(application.Legacy_Application_ID__c);
            if(application.Legacy_Enquiry_ID__c != null)
                legacyEnquiryIds.add(application.Legacy_Enquiry_ID__c);
            if(application.Legacy_Course_Offering_ID__c != null)
                legacyCourseOfferingIds.add(application.Legacy_Course_Offering_ID__c);
        }

        System.debug('!@#$% legacyApplicationIds : ' + legacyApplicationIds);
        System.debug('!@#$% legacyEnquiryIds : ' + legacyEnquiryIds);

        // Fetch Enquiries required to associate
        List<Case> enquiries = [SELECT Id, Legacy_Enquiry_ID__c, Legacy_Contact_ID__c, Legacy_Course_ID__c, Course__c, Contact.Id FROM Case WHERE Legacy_Enquiry_ID__c IN :legacyEnquiryIds];
        Map<String, Case> enquiryIds = new Map<String, Case>();
        for(Case enq : enquiries) {
            enquiryIds.put(enq.Legacy_Enquiry_ID__c, enq);
        }
        System.debug('!@#$% enquiryIds : ' + enquiryIds);

        // Fetch ACPs required to associate
        List<Application_Course_Preference__c> acps = [SELECT Id, Legacy_Application_ID__c, Application__c, Applicant__c, Course__c, Course_Offering__c, Status__c, Cancelled__c, Certification_Completed__c, Certification_Completed_Without_Points__c, Attendance_Certificate__c, Result__c FROM Application_Course_Preference__c WHERE Legacy_Application_ID__c IN :legacyApplicationIds];

        // Fetch Payments required to associate
        List<Payment__c> payments = [SELECT Id, Legacy_Application_ID__c, Legacy_Payment_ID__c, Legacy_Credit_Card_Expiry__c, Date_receipt_sent__c FROM Payment__c WHERE Legacy_Application_ID__c IN :legacyApplicationIds];

        // Fetch Course Offerings required to associate
        List<Course_Offering__c> cos = [SELECT Id, Legacy_Course_Offering_ID__c FROM Course_Offering__c WHERE Legacy_Course_Offering_ID__c IN :legacyCourseOfferingIds];
        Map<String, Course_Offering__c> cosMap = new Map<String, Course_Offering__c>();
        for(Course_Offering__c co : cos) {
            cosMap.put(co.Legacy_Course_Offering_ID__c,co);
        }

        // Process Applications
        Map<String, Application__c> applicationMap = new Map<String, Application__c>();
        Map<String, Case> enquiryMap = new Map<String, Case>();
        for(Application__c application : applications) {
            Case enq = enquiryIds.get(application.Legacy_Enquiry_ID__c);
            if(enq != null) {
                application.Enquiry_Number__c = enq.Id;
                if(enq.Contact != null) {
                    application.Applicant__c = enq.Contact.Id;    
                }
            }
                
            String lSubmittedDate = application.Legacy_Submitted_Date__c;
            
            if(lSubmittedDate != null && lSubmittedDate != '') {
                Integer day;
                Integer month;
                Integer year;
                List<String> splitter = lSubmittedDate.split('/');
                if(splitter.size()>0) {
                    if(splitter.get(0) != null)
                        day = Integer.valueOf(splitter.get(0));
                    if(splitter.get(1) != null)
                        month = Integer.valueOf(splitter.get(1));
                    if(splitter.get(2) != null)
                        year = Integer.valueOf(splitter.get(2));
                }
                
                if(day != null && month != null && year != null) {
                    Date submittedDate = Date.newInstance(2000+year, month, day);
                    //application.Submitted_Date__c = submittedDate;  
                }   
            }
            
            System.debug('!@#$% Updated Application : ' + application);
            applicationsToProcess.add(application);

            // Prepare Application Map
            applicationMap.put(application.Legacy_Application_ID__c, application);
            enquiryMap.put(application.Legacy_Application_ID__c, enquiryIds.get(application.Legacy_Enquiry_ID__c));
        }
        update applicationsToProcess;


        // Process ACPs
        for(Application_Course_Preference__c acp : acps) {
            
            Application__c appl = applicationMap.get(acp.Legacy_Application_ID__c);

            acp.Application__c = appl.Id;
            acp.Applicant__c = appl.Applicant__c; 
            Case enq = enquiryMap.get(acp.Legacy_Application_ID__c);
            if(enq != null && enq.Course__c != null)
                acp.Course__c = enq.Course__c;
            
            String coId = appl.Legacy_Course_Offering_ID__c;
            if(coId != null && coId != '') {
                Course_Offering__c courseOffering = cosMap.get(coId);
                if(courseOffering != null) {
                    acp.Course_Offering__c = courseOffering.Id;    
                }
            }

            if(acp.Cancelled__c) {
                acp.Status__c = 'Cancelled';
            }

            acp.Course_Result__c = acp.Result__c;
            if(acp.Result__c != null && acp.Result__c != '') {
                if(acp.Result__c.equalsIgnoreCase('Fail') || acp.Result__c.equalsIgnoreCase('Incomplete')) {
                    acp.Course_Result__c = acp.Result__c;
                } else {
                    if(acp.Certification_Completed__c)
                        acp.Course_Result__c = 'Pass with credit points';
                    if(acp.Certification_Completed_Without_Points__c)
                        acp.Course_Result__c = 'Pass';
                    if(acp.Attendance_Certificate__c)
                        acp.Course_Result__c = 'Attended';    
                }
                

            }
        }
        update acps;

        // Months Map
        Map<String, String> monthMap = new Map<String, String>();
        monthMap.put('January','January');
        monthMap.put('February','February');
        monthMap.put('March','March');
        monthMap.put('April','April');
        monthMap.put('May','May');
        monthMap.put('June','June');
        monthMap.put('July','July');
        monthMap.put('August','August');
        monthMap.put('September','September');
        monthMap.put('October','October');
        monthMap.put('November','November');
        monthMap.put('December','December');

        for(Payment__c payment : payments) {

            Application__c appl = applicationMap.get(payment.Legacy_Application_ID__c);

            payment.Application__c = appl.Id;
            payment.Contact__c = appl.Applicant__c;
            payment.Payment_Status__c = 'Processed';
            if(payment.Date_receipt_sent__c != null)
                payment.Notes__c = 'Receipt Sent Date : ' + payment.Date_receipt_sent__c;

            if(appl.Applicant__r.Company__c != null && appl.Applicant__r.Company__c != '') {
                payment.Street__c = appl.Applicant__r.OtherStreet;
                payment.Suburb__c = appl.Applicant__r.OtherCity;
                payment.State__c = appl.Applicant__r.OtherState;
                if(appl.Applicant__r.OtherPostalCode != null && appl.Applicant__r.OtherPostalCode.length() < 5)
                    payment.Postcode__c = appl.Applicant__r.OtherPostalCode;    
            } else {
                payment.Street__c = appl.Applicant__r.MailingStreet;
                payment.Suburb__c = appl.Applicant__r.MailingCity;
                payment.State__c = appl.Applicant__r.MailingState;
                if(appl.Applicant__r.MailingPostalCode != null && appl.Applicant__r.MailingPostalCode.length() < 5)
                    payment.Postcode__c = appl.Applicant__r.MailingPostalCode;   
            }

            String coId = appl.Legacy_Course_Offering_ID__c;
            if(coId != null && coId != '') {
                Course_Offering__c courseOffering = cosMap.get(coId);
                if(courseOffering != null) {
                    payment.Course_Offering__c = courseOffering.Id;    
                }
            }

            System.debug('!@#$% Legacy Payment ID : ' + payment.Legacy_Payment_ID__c);
            if(payment.Legacy_Payment_ID__c != null) {
                String lPaymentId = payment.Legacy_Payment_ID__c;
                lPaymentId = lPaymentId.trim();
                
                if(lPaymentId == '1') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = 'Visa';
                } 
                else if(lPaymentId == '2') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = 'Mastercard';
                } 
                else if(lPaymentId == '3') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '4') {
                    payment.Payment_Type__c = 'Purchase_Order';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '5') {
                    payment.Payment_Type__c = 'Cheque';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '6') {
                    payment.Payment_Type__c = 'Cheque';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '7') {
                    payment.Payment_Type__c = 'Money_Order';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '8') {
                    payment.Payment_Type__c = 'Cash';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '9') {
                    payment.Payment_Type__c = '';
                    payment.Credit_Card_Type__c = '';
                }
                else if(lPaymentId == '10') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = 'American Express';
                }
                else if(lPaymentId == '11') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = 'Diners Club';
                }
                else if(lPaymentId == '13') {
                    payment.Payment_Type__c = 'Credit_Card';
                    payment.Credit_Card_Type__c = '';
                }

            }

            String ccExpiry = '';
            String ccExpiryMonth = '';
            String ccExpiryYear = '';

            ccExpiry = payment.Legacy_Credit_Card_Expiry__c;
            if(ccExpiry != null && ccExpiry != '') {
                List<String> splitter = new List<String>();
                splitter = ccExpiry.split('-');

                if(splitter.size()>0)
                    ccExpiryMonth = splitter.get(0);
                ccExpiryMonth = ccExpiryMonth.trim();   
                ccExpiryMonth = ccExpiryMonth.toLowerCase(); 

                if(splitter.size()>1)
                    ccExpiryYear = splitter.get(1);
                ccExpiryYear = ccExpiryYear.trim();
                ccExpiryYear = ccExpiryYear.toLowerCase();

            }

            if(ccExpiryMonth != null && ccExpiryMonth != '') {
                if(ccExpiryMonth.startsWith('jan')) {
                    ccExpiryMonth = 'January';
                }
                else if(ccExpiryMonth.startsWith('feb')) {
                    ccExpiryMonth = 'February';
                }
                else if(ccExpiryMonth.startsWith('mar')) {
                    ccExpiryMonth = 'March';
                }
                else if(ccExpiryMonth.startsWith('apr')) {
                    ccExpiryMonth = 'April';
                }
                else if(ccExpiryMonth.startsWith('may')) {
                    ccExpiryMonth = 'May';
                }
                else if(ccExpiryMonth.startsWith('jun')) {
                    ccExpiryMonth = 'June';
                }
                else if(ccExpiryMonth.startsWith('jul')) {
                    ccExpiryMonth = 'July';
                }
                else if(ccExpiryMonth.startsWith('aug')) {
                    ccExpiryMonth = 'August';
                }
                else if(ccExpiryMonth.startsWith('sep')) {
                    ccExpiryMonth = 'September';
                }
                else if(ccExpiryMonth.startsWith('oct')) {
                    ccExpiryMonth = 'October';
                }
                else if(ccExpiryMonth.startsWith('nov')) {
                    ccExpiryMonth = 'November';
                }
                else if(ccExpiryMonth.startsWith('dec')) {
                    ccExpiryMonth = 'December';
                }    

                if(monthMap.containsKey(ccExpiryMonth))
                    payment.Credit_Card_Expiry_Month__c = ccExpiryMonth;
            }
            

            if(ccExpiryYear != null && ccExpiryYear != '') { 
                if(ccExpiryYear.length() == 2) {
                    ccExpiryYear = '20'+ccExpiryYear;
                }

                Integer num;
                Exception excep;
                try{
                    num = Integer.valueOf(ccExpiryYear);
                } catch(Exception e){
                    excep = e;
                }

                if(excep == null || excep.getMessage() == null)
                    payment.Credit_Card_Expiry_Year__c = ccExpiryYear;
            }   

        }
        update payments;
        
    }

    global void finish(Database.BatchableContext BC) {
    }
    
}