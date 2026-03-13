/**
 * @author          Ajitabh
 * @description     Batch Class for creating PDF and SendEmail for guest user.
 * @revision
 * Date         Author              Modification
 * 18/07/2022   Chaldrin Cruz       Replaced rt with rtv2
*/
global class PDFSendEmailReviewTranBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts {
	public String query;
	List<PORTAL_UCIN_Email_Template__mdt> mdtList;
	List<EmailTemplate> templateList;

	global PDFSendEmailReviewTranBatch(){
	 	mdtList = [Select DeveloperName, EmailTemplateId__c, OrgWideEmailAddressId__c, OrgWideEmailAddress__c
                  From PORTAL_UCIN_Email_Template__mdt Where DeveloperName ='PORTAL_UCIN_Donation_Gift_Receipt'];
   	    templateList = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName =: mdtList[0].DeveloperName];

        // query all reviewTransaction record created by Guest User

     	query   = 'SELECT Id FROM ucinn_ascendv2__Review_Transaction_v2__c WHERE ucinn_ascendv2__Transaction_Type__c= \'Gift\' and createdby.name=  \'ascendportal Site Guest User\'';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('=========='+Database.getQueryLocator(query));
        return Database.getQueryLocator(query);
    }

	global void execute(Database.BatchableContext BC, List<ucinn_ascendv2__Review_Transaction_v2__c> scope) {
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        Map<id,id> conversionRevTranMap = new Map<id,id>();
        List<ContentVersion> conVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> conDocLink = new List<ContentDocumentLink>();
        List<ucinn_ascendv2__Review_Transaction_v2__c> reviewTranWithoutAtt = new List<ucinn_ascendv2__Review_Transaction_v2__c>();

        // get all the reviewTransation without attachment

        for (ucinn_ascendv2__Review_Transaction_v2__c reTran : [SELECT Id,ucinn_ascendv2__Transaction_Type__c,
                                                            ucinn_ascendv2__Contact__c,
                                                            ucinn_ascendv2__Contact__r.FirstName,
                                                            ucinn_ascendv2__Contact__r.LastName,
                                                            ucinn_ascendv2__Interim__c,
                                                            ucinn_ascendv2__Interim__r.ucinn_ascendv2__Email_1__c,
                                                            ucinn_ascendv2__Interim__r.ucinn_ascendv2__First_Name__c,
                                                            ucinn_ascendv2__Interim__r.ucinn_ascendv2__Last_Name__c,
                                                            (SELECT Id FROM ContentDocumentLinks LIMIT 1)
                                                            FROM ucinn_ascendv2__Review_Transaction_v2__c WHERE Id IN : scope]){

        if(reTran.ContentDocumentLinks.size() < 1){
                reviewTranWithoutAtt.add(reTran);
             }
         }

    system.debug('see'+reviewTranWithoutAtt);

    //for every reviewTransaction
    for(ucinn_ascendv2__Review_Transaction_v2__c reTran : reviewTranWithoutAtt){
    	// generatePDFForBatchService.attachPdfToRecord(reTran.id, this.sessionId);
    	PageReference pdfPage = new PageReference('/apex/PORTAL_UCIN_ReceiptPage?reviewTransactionId='+reTran.id);

          // keep content version ready for every reviewTransaction

        	ContentVersion cont = new ContentVersion();
            cont.Title = 'Gift Receipt';
            cont.PathOnClient = 'file.pdf';

        	if(test.isRunningTest()){
           	 cont.VersionData = Blob.valueOf('test');
       		 }
        	else{
                Blob pdf = pdfPage.getContentAsPdf();
        		cont.VersionData = pdf;
       	    }
            cont.Origin = 'H';
        	//conVersionList.add(cont);
        	insert cont;
        	ContentVersion cont2 = [SELECT id, ContentDocumentId FROM ContentVersion WHERE ID =: cont.ID];
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cont2.ContentDocumentId;
            cdl.LinkedEntityId = reTran.id;
            cdl.ShareType = 'V';
        	insert cdl;
        
        	 if (!templateList.isEmpty()) {
                EmailTemplate emailTemplate = templateList[0];
                String firstName;
                String orgId = UserInfo.getOrganizationId();
                String domainName;
             	String emailid;

                if (reTran.ucinn_ascendv2__Contact__c != null) {
                    firstName = reTran.ucinn_ascendv2__Contact__r.FirstName;
                } else if (reTran.ucinn_ascendv2__Interim__c != null) {
                    firstName = reTran.ucinn_ascendv2__Interim__r.ucinn_ascendv2__First_Name__c;
                    emailid	= reTran.ucinn_ascendv2__Interim__r.ucinn_ascendv2__Email_1__c;
                }
				system.debug('nn'+emailid);
                PORTAL_UCIN_Domain_Name__c mhc = PORTAL_UCIN_Domain_Name__c.getInstance();
                domainName = mhc.Domain_Name__c;


                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                List<OrgWideEmailAddress> owa = [select Id, Address, DisplayName from OrgWideEmailAddress WHERE Address = :mdtList[0].OrgWideEmailAddress__c limit 1];
                if (!owa.isEmpty()) {
                    mail.setOrgWideEmailAddressId(owa[0].Id);
                }
                // process the merge fields manually. We need to do this b/c community guest users don't have a proper user record, so merge fields don't work.
                String subject = emailTemplate.Subject;
                if (subject != null) {
                    subject = subject.replace('{!Receiving_User.FirstName}', firstName);
                }

                String htmlBody = emailTemplate.HtmlValue;
                if (htmlBody != null) {
                    htmlBody = htmlBody.replace('{!$Setup.PORTAL_UCIN_Domain_Name__c.Domain_Name__c}', domainName);
                    htmlBody = htmlBody.replace('{!$Organization.Id}', orgId);
                    htmlBody = htmlBody.replace('{!Receiving_User.FirstName}', firstName);
                }

                String plainBody = emailTemplate.Body;
                if (plainBody != null) {
                    plainBody = plainBody.replace('{!Receiving_User.FirstName}', firstName);
                }

                mail.setSubject(subject);
                mail.setHtmlBody(htmlBody);
                mail.setPlainTextBody(plainBody);
                if(!test.isRunningTest())
                mail.setToAddresses(new String[]{reTran.ucinn_ascendv2__Interim__r.ucinn_ascendv2__Email_1__c});
                else
                mail.setToAddresses(new String[]{'test@test.com'}); 
                if (reTran.ucinn_ascendv2__Transaction_Type__c == 'Gift') {
                    mail.setEntityAttachments(new String[]{String.valueOf(cont2.id)});
                }
                mail.saveAsActivity = false;
                mailList.add(mail);
                system.debug(mailList);


    				}
				}
                Messaging.sendEmail(mailList);
    }
	
	global void finish(Database.BatchableContext BC){
   	 }
}