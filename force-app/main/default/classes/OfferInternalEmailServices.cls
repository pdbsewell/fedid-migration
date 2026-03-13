/**
 * @author      Kristian Vegerano
 * @description Service class for offer send email component
 * @group       Service
 * @revision    25/05/2020 - Kristian Vegerano - Created
 */
public with sharing class OfferInternalEmailServices {
    /**
     * @author      Kristian Vegerano
     * @description Retrieves all the opportunity details required to send email
     * @param       String opportunityId
     * @return      Object
     * @revision    25/05/2020 - Kristian Vegerano - Created
     */
	 @TestVisible
    static String gcoOfferEmaiSendStatus = null;
    @AuraEnabled(cacheable=true)
    public static Object retrieveOpportunityDetails(Id opportunityId) {
        Opportunity opportunityItem = [SELECT Id, Agent_Account__c, Agent_Account__r.Email__c,
                                              PrimaryContact__c, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Email, PrimaryContact__r.Person_ID__c                                               
                                       FROM Opportunity 
                                       WHERE Id = :opportunityId 
                                       LIMIT 1];
        return opportunityItem;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the email template used for sending out offer ammendment email templates
     * @return      Object
     * @revision    25/05/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> retrieveOfferEmailTemplate(Id opportunityId){
        Map<String, Object> resultMap = new  Map<String, Object>();
        try{
            //Add opportunity details
            Opportunity opportunityItem = [SELECT Id, Admission_office_location__c, Agent_Account__c, Agent_Account__r.Email__c, Agent_Name__c, Calculated_Expiry_Date__c, SBQQ__PrimaryQuote__c,
                                                  PrimaryContact__c, PrimaryContact__r.Name, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Person_ID__c, 
                                                  PrimaryContact__r.MailingStreet, PrimaryContact__r.MailingCity, PrimaryContact__r.MailingState, PrimaryContact__r.MailingPostalCode, 
                                                  PrimaryContact__r.MailingCountry, CloseDate, Offer_Grant_Extension_Date_for_Letter__c 
                                           FROM Opportunity 
                                           WHERE Id = :opportunityId 
                                           LIMIT 1];

            String admissionLoc = opportunityItem.Admission_office_location__c;
            
            String orgWAddress = 'mu.documents%';
            // default email folder for AU offers
            String emailFolderName = 'Offer Mgmt - User';
            if(String.isNotBlank(admissionLoc) && admissionLoc == 'Malaysia')
            {
                emailFolderName = 'MUM Admissions - Offer Management';
                orgWAddress = 'mum.admissions%';
            }

            //Retrieve org-wide address
            List<OrgWideEmailAddress> orgWideAddressList = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address like :orgWAddress LIMIT 1];
     
            //Query items
            List<EmailTemplate> templatesList = new List<EmailTemplate>();
            Map<String, EmailTemplate> offerAmendmentTemplateMap = new Map<String, EmailTemplate>();
            for(EmailTemplate loopTemplate : [SELECT Id, Name, DeveloperName, HtmlValue, Subject,EmailTemplate.Folder.Name 
                                              FROM EmailTemplate 
                                              WHERE EmailTemplate.Folder.Name = :emailFolderName
                                              ORDER BY Name DESC]){
                templatesList.add(loopTemplate);
                offerAmendmentTemplateMap.put(loopTemplate.DeveloperName, loopTemplate);
            }
            
            SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c();
            for(SBQQ__QuoteLine__c quoteLine : [SELECT Id, SBQQ__ProductFamily__c, Application_Course_Preference__c, 
                                                        Application_Course_Preference__r.Commencement_Period__c, Application_Course_Preference__r.Course_Title__c
                                                FROM SBQQ__QuoteLine__c
                                                WHERE SBQQ__Quote__c = :opportunityItem.SBQQ__PrimaryQuote__c
                                                    AND SBQQ__ProductFamily__c IN ('Course','English Course') 
                                                ORDER BY SBQQ__Number__c ASC
                                                LIMIT 1]){
                quoteLineItem = quoteLine;
            }
            //substitute proper values for the placeholders     
            for(EmailTemplate loopTemplate : offerAmendmentTemplateMap.values()){
                loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<DateToday/>', DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('d MMMM yyyy'));
                if(opportunityItem.PrimaryContact__r.Person_ID__c != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<StudentNumber/>', opportunityItem.PrimaryContact__r.Person_ID__c);
                }
                if(opportunityItem.CloseDate != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<OfferResponseDate/>', DateTime.newInstance(opportunityItem.CloseDate.year(), opportunityItem.CloseDate.month(), opportunityItem.CloseDate.day()).format('d MMMM yyyy'));
                }
                if(opportunityItem.PrimaryContact__r.FirstName != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<GivenName/>', opportunityItem.PrimaryContact__r.FirstName);
                }                
                if(opportunityItem.PrimaryContact__r.Name != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<FullName/>', opportunityItem.PrimaryContact__r.Name);
                }
                if(opportunityItem.PrimaryContact__r.MailingStreet != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AddressStreet/>', opportunityItem.PrimaryContact__r.MailingStreet);
                }
                if(opportunityItem.PrimaryContact__r.MailingCity != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AddressCity/>', opportunityItem.PrimaryContact__r.MailingCity);
                }
                if(opportunityItem.PrimaryContact__r.MailingState != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AddressState/>', opportunityItem.PrimaryContact__r.MailingState);
                }                
                if(opportunityItem.PrimaryContact__r.MailingPostalCode != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AddressPostal/>', opportunityItem.PrimaryContact__r.MailingPostalCode);
                }
                if(opportunityItem.PrimaryContact__r.MailingCountry != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AddressCountry/>', opportunityItem.PrimaryContact__r.MailingCountry);
                }
                if(opportunityItem.Calculated_Expiry_Date__c != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<OfferLapseDate/>', DateTime.newInstance(opportunityItem.Calculated_Expiry_Date__c.year(), opportunityItem.Calculated_Expiry_Date__c.month(), opportunityItem.Calculated_Expiry_Date__c.day()).format('d MMMM yyyy'));
                }
                if(opportunityItem.Agent_Name__c != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<AssignedAgency/>', '<br>' + opportunityItem.Agent_Name__c);
                }
                if(quoteLineItem.Application_Course_Preference__r.Commencement_Period__c != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<PrimaryOfferedSemesterYear/>', quoteLineItem.Application_Course_Preference__r.Commencement_Period__c);
                }
                if(quoteLineItem.Application_Course_Preference__r.Course_Title__c != null){
                    loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<PrimaryOfferedCourseName/>', quoteLineItem.Application_Course_Preference__r.Course_Title__c);
                }
                if (opportunityItem.Offer_Grant_Extension_Date_for_Letter__c != null) {
                    loopTemplate.HTMLValue = loopTemplate.HtmlValue.replace('<OfferGrantExtensionDateForLetter/>',DateTime.newInstance(opportunityItem.Offer_Grant_Extension_Date_for_Letter__c.year(), opportunityItem.Offer_Grant_Extension_Date_for_Letter__c.month(), opportunityItem.Offer_Grant_Extension_Date_for_Letter__c.day()).format('d MMMM yyyy'));
                }
                loopTemplate.HtmlValue = loopTemplate.HtmlValue.replace('<UserName/>', UserInfo.getName());
                
            }

            //Retrieve document items
            String headerImage;
            for(StaticResource loopResource : [SELECT Id, Name, SystemModStamp
                                               FROM StaticResource
                                               WHERE Name IN ('OfferEmailTemplateMonashLogo')
                                               LIMIT 1]){
                if(loopResource.Name == 'OfferEmailTemplateMonashLogo'){
                    headerImage = '<img style="margin-top: 30px; margin-bottom: 20px; width: 170px;height: 50px;" src="/resource/' + String.valueOf(((DateTime)loopResource.get('SystemModStamp')).getTime()) + '/' + loopResource.get('Name') + '"/>';
                }
            }

            List<ContentDocumentLink> linksList = new List<ContentDocumentLink>();
            for(ContentDocumentLink loopLink : [SELECT Id, ContentDocumentId, ContentDocument.Title, LinkedEntityId 
                                                FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId 
                                                ORDER BY SystemModstamp DESC]){
                linksList.add(loopLink);
            }

            resultMap.put('TemplatesList', templatesList);
            resultMap.put('OfferTemplateTemplates', offerAmendmentTemplateMap);

            resultMap.put('HeaderImage', headerImage);
            resultMap.put('Files', linksList);
            resultMap.put('TemplateFolder',emailFolderName);
            if(orgWideAddressList.size()>0)
                resultMap.put('FromAddress',orgWideAddressList[0].Address);
        } catch(Exception e){
            ExLog.add('OfferInternalEmailServices', 'Offer Amendment Email Template', 'retrieveOfferEmailTemplate', e);
            resultMap.put('Error', e.getMessage());
        }
      
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @description Sends an email message and creates an admissions enquiry to receive the reply
     * @param       String opportunityId
     *              String emailContent
     *              String ccAddresses
     *              String emailSubject
     *              String fromEmail
     *              String emailTextContent
     *              String selectedFiles
     * @return      Map<String, Object>
     * @revision    25/05/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Map<String, Object> submitOfferTemplateEmail(String opportunityId, String emailContent, String ccAddresses, String emailSubject, String fromEmail, String emailTextContent, String selectedFiles){
        Map<String, Object> resultMap = new Map<String, Object>();
        try{
            emailContent = '<div style="font-family: Arial, Helvetica, sans-serif; font-size: 14px;">' + emailContent + '</div>';

            Opportunity opportunityItem = [SELECT Id, Agent_Account__c, Agent_Account__r.Email__c, Admission_office_location__c,
                                                  PrimaryContact__c, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Email 
                                           FROM Opportunity 
                                           WHERE Id = :opportunityId 
                                           LIMIT 1];

            Group muDocsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SRA_IA_MU_Docs' LIMIT 1];
            String admissionLoc = opportunityItem.Admission_office_location__c;
            // default OWD for AU offers
            String orgWAddress = 'mu.documents%';
            if(String.isNotBlank(admissionLoc) && admissionLoc == 'Malaysia')
            {
                orgWAddress = 'mum.admissions%';
            }
            //Retrieve org-wide address
            OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address like :orgWAddress LIMIT 1];
            
            //Retrive community login url to access image static resource outside salesforce
            Network communityNetwork = [SELECT Id, Name FROM Network WHERE Name = 'my.application' LIMIT 1];
            String communityUrl = Network.getLoginUrl(communityNetwork.Id);
            communityUrl = communityUrl.replace('/admissions/s/login', '');

            //Replace image url to use community to access static resource
            emailContent = emailContent.replace('/resource', communityUrl + '/admissions/resource');

            //Build email message
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setPlainTextBody(emailTextContent.stripHtmlTags());
            message.setHtmlBody(emailContent);
            message.setSubject(emailSubject);
            message.setReplyTo(fromEmail);
            message.setOrgWideEmailAddressId(orgWideAddress.Id);
            message.setToAddresses(new List<String>{ opportunityItem.PrimaryContact__r.Email });
            message.setWhatId(opportunityItem.Id);
            message.setTargetObjectId(opportunityItem.PrimaryContact__c);

            //Build ccaddresses
            List<String> ccAddressesList = new List<String>();
            if(ccAddresses != '' && ccAddresses != null){
                for(String loopCcEmailAddress : ccAddresses.split(',')){
                    ccAddressesList.add(loopCcEmailAddress);
                }
            }
            //Add agent email
            if(opportunityItem.Agent_Account__c != null){
                if(opportunityItem.Agent_Account__r.Email__c != null){
                    ccAddressesList.add(opportunityItem.Agent_Account__r.Email__c);
                }
            }
            if(!ccAddressesList.isEmpty()){
                message.setCcAddresses(ccAddressesList);
            }            

            if(selectedFiles != null){
                List<Id> selectedFileIds = selectedFiles.split(',');
                List<Attachment> attachmentList = new List<Attachment>();

                for(ContentDocument loopContentDocument : [SELECT Id, FileExtension, LatestPublishedVersionId, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData
                                                            FROM ContentDocument
                                                            WHERE Id IN :selectedFileIds]){
                    attachmentList.add(new Attachment(Body = loopContentDocument.LatestPublishedVersion.VersionData,
                                                      Name = loopContentDocument.LatestPublishedVersion.Title + '.' + loopContentDocument.FileExtension,
                                                      ParentId = opportunityItem.Id));
                }
                if(!attachmentList.isEmpty()){
                    insert attachmentList;
                    List<Id> attachmentIds = new List<Id>();
                    for(Attachment loopAttachment : attachmentList){
                        attachmentIds.add(loopAttachment.Id);
                    }

                    message.setEntityAttachments(attachmentIds);
                }
            }

            //Send email message
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                    //debugging here
                } else {
                    //debugging here
                }
            }

            resultMap.put('Status', 'Success');
        } catch(Exception e){
            ExLog.add('OfferInternalEmailServices', 'Offer Amendment Email Template', 'submitOfferTemplateEmail', e);
            resultMap.put('Status', 'Error');
        }

        return resultMap;
    }

    /**
     * @author          Kristian Vegerano
     * @description     Checks if the current user has permission to access the send offer email
     * @revision        25/05/2020 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Boolean checkSendOfferEmailPermission() {
        return FeatureManagement.checkPermission('SendOfferEmail');
    }

    /**
     * @author          Shalini Mendu
     * @description     Sends Email notification for GCO offers automatically on Quote status update
     * @revision        4/11/2024 - Created
     */
    @InvocableMethod(label='Auto email send' description='Auto email send' category='Offer')
    public static void sendGCOOfferEmail(List<String> quoteIds )
    {
        //OrgWideAddress
        String orgWAddress = 'mu.documents%';

        //Retrieve QuoteId
        Id quoteId = quoteIds.get(0);

        //Retrieve Quote details
        SBQQ__Quote__c quote = [select SBQQ__Opportunity2__r.Id, Name from SBQQ__Quote__c where Id=:quoteId];
        
        //Retrieve OppId 
        Id oppId = quote.SBQQ__Opportunity2__r.Id;
      
        try{
                //Retrieve OrgWideEmailAddress
                List<OrgWideEmailAddress> orgWideAddressList = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address like :orgWAddress LIMIT 1];
                
                //Retrieve Opportunity details from the class method
                Opportunity opp = (Opportunity) retrieveOpportunityDetails(oppId);
                
                //Retrieve Offer Email details into a map
                Map<String, Object>  offerEmailMap = retrieveOfferEmailTemplate(oppId);

                //Retrieve all Offer related EmailTemplate  into a map
                Map<String, EmailTemplate> emailTemplateMap = (Map<String, EmailTemplate>)offerEmailMap.get('OfferTemplateTemplates'); 
               
                //Retrieve Offer_Email email template from the map            
                EmailTemplate template = (EmailTemplate) emailTemplateMap.get('GCO_Offer_Email');

                //Retrieve HTMLValue without header of the  email template           
                String emailContent = template.HtmlValue;
                
                //Retrieve HeaderImage of the  email template           
                String headerImage = (String) offerEmailMap.get('HeaderImage');

                //Construct emailContentHTMLValue of the  email template           
                String emailContentHTMLValue =  headerImage + emailContent;

                //Retrieve ContentDocument Id that is linked to this Opportunity          
                ContentDocumentLink cd = [SELECT Id, LinkedEntityId, ContentDocumentId
                                        FROM ContentDocumentLink 
                                        where LinkedEntityId= :quoteId];

                //Construct Email subject for the email        
                String emailSubject = opp.PrimaryContact__r.FirstName + ' ' + opp.PrimaryContact__r.LastName + ' ' + (opp.PrimaryContact__r.Person_ID__c!=null ? '(' + opp.PrimaryContact__r.Person_ID__c + ')' : '') + ' - ' + 'Monash has made you an offer!'; 
                
                //call the email sending method          
                Map<String, Object> resultMap = (Map<String, Object>)submitOfferTemplateEmail(oppId, emailContentHTMLValue, null , emailSubject ,
                                                                                              orgWideAddressList[0].Address, emailContent,
                                        	                                                      cd.ContentDocumentId);
                gcoOfferEmaiSendStatus = ((String)resultMap.get('Status'));
            
            }catch(Exception ex)
            {
                Nebula.logger.exception('Failed sending email notification with GCO offer for Quote:'+ quote.Name+ ex.getMessage(), ex);
                Nebula.logger.error(ex.getMessage(), quote.Name);

            }finally{
                Nebula.logger.saveLog();
            }

    }
}