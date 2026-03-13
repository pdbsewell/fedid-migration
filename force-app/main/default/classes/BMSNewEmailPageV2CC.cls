/**
* @author           Nick Guia
* @date             07/08/2017
* @description      - Apex Controller for BMSNewEmailPageV2 page
* @revision	
* 25/07/2022	RANAND		Removed reference of searchRecord method which is not being referenced in Page
**/
global with sharing class BMSNewEmailPageV2CC {

    public static Blob contentFile {get;set;}
    public static String fileName {get;set;}
    public static Map<String, Document> csvTemplateMap {get;set;}

    public String filterFieldOptionWrapper {
        get { return JSON.serialize(BMSUtils.getFilterFieldOptionWrapper()); }
    }

    public String getAllStaffOptionWrapper {
        get { return JSON.serialize(BMSUtils.getAllStaffOptionWrapper()); }
    }

    public String uOfferingFieldOptionWrapper {
        get { return JSON.serialize(BMSUtils.getUOfferingOptionWrapper()); }
    }

    public List<SelectOption> cohortOptions {
        get { return BMSUtils.getCohortOptions(); }
    }

    public List<SelectOption> emailTemplates {
        get { 
            return BMSUtils.getEmailOptions(); }
    }

    public Boolean isAdmin {
        get { return BMSUtils.checkIfAdmin(UserInfo.getProfileId()); }
    }

    private final transient Id knownToMonashRecTypeId = Schema.SObjectType.Contact
                                                            .getRecordTypeInfosByName()
                                                            .get('Known to Monash systems')
                                                            .getRecordTypeId();

    /**
    * @description class contructor
    **/
    public BMSNewEmailPageV2CC() {
        csvTemplateMap = new Map<String, Document>();
        for (Document csvDocuments : [SELECT Id, Name 
                                        FROM Document 
                                        WHERE Folder.Name = 'BMSLogos' 
                                        AND (Name = 'PersonId_CSV' OR Name = 'NameAndEmail_CSV') 
                                        LIMIT 2]) 
        {
            csvTemplateMap.put(csvDocuments.Name, csvDocuments);
        }
    }

    /**
    * @author       Nick Guia
    * @date         02/08/2017
    * @description  - Remote Action method for fetching picklist values of a field
    **/
    @RemoteAction
    global static List<String> getPickListValues(String sObjectName, String fieldName) {
        return BMSUtils.getPickListValues(Schema.getGlobalDescribe().get(sObjectName), fieldName);
    }

    /**
    * @author       Nick Guia
    * @date         15/08/2017
    * @description  remote action method for building html of preview path
    * @param        payload from page. structure is based on BMSUtils.BuildPreviewEmailWrapper
    * @return       String value of html for preview
    **/
    @RemoteAction
    global static String buildPreview(String sJSON) {
        BMSUtils.BuildPreviewEmailWrapper bpew = 
            (BMSUtils.BuildPreviewEmailWrapper) JSON.deserializeStrict(sJSON, BMSUtils.BuildPreviewEmailWrapper.class);
        String htmlBody = constructHTMLBody(bpew);
        return htmlBody;
    }

    /**
    * @author       Nick Guia
    * @date         15/08/2017
    * @description  remote action method to sync campaign record details from the page
    * @param        payload : payload from page. structure is based on BMSUtils.NewEmailSaveWrapper
    *               isEdit : Boolean to check if this is for updating campaign
    * @return       dummy return value for our page to know if transaction is successful
    **/
    @RemoteAction
    global static Boolean saveCampaign(String sJSON, Boolean isEdit) {
        Boolean returnVal = true;
        try {
            BMSUtils.NewEmailSaveWrapper nesw = (BMSUtils.NewEmailSaveWrapper) JSON.deserializeStrict(sJSON, BMSUtils.NewEmailSaveWrapper.class);
            Campaign massEmailRecord = nesw.massEmailRecord;

            //assign initial campaign details
            massEmailRecord.Type = 'Email';
            massEmailRecord.RecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('BMS').getRecordTypeId();
            massEmailRecord.IsActive = true;
            massEmailRecord.From__c = UserInfo.getUserEmail();
            massEmailRecord.HTML_Email__c = customiseMessage(massEmailRecord.Custom_Message__c, 
                                                                massEmailRecord.Add_CRICOS__c, 
                                                                massEmailRecord.Add_Base_Signature__c);

            if (massEmailRecord.Notify__c != null && massEmailRecord.Notify__c != '') {
                massEmailRecord.Notify__c = formatAdditionalEmails(massEmailRecord.Notify__c);
            }
            if(!isEdit) massEmailRecord.Status = 'On Hold'; //only assign status on insert

            upsert massEmailRecord;

            //Only process audience on insert
            if(!isEdit) {
                //execute batch jobs
                if (nesw.audienceType == 'search') {
                    BMSInsertCampaignMemberQueueable campaignMemberJob = 
                        new BMSInsertCampaignMemberQueueable(nesw.finalQueryString, massEmailRecord.Id, null);
                    System.enqueueJob(campaignMemberJob);
                } else if(nesw.audienceType == 'upload') {
                    //PROCESS ATTACHMENT
                    if(nesw.fileUpload != null) {
                        Attachment attachmentRec = new Attachment();
                        attachmentRec.Body = nesw.fileUpload;
                        attachmentRec.Name = nesw.fileName;
                        attachmentRec.ParentId = massEmailRecord.Id;
                        insert attachmentRec;

                        Boolean isPersonId = (nesw.attachmentContent == 'Person IDs') ? true : false;
                        BMSInsertCampaignMemberCSVQueueable campaignMemberJob = 
                            new BMSInsertCampaignMemberCSVQueueable(attachmentRec.Id, massEmailRecord.Id, isPersonId);
                        System.enqueueJob(campaignMemberJob);
                    }
                }
            }
        } catch(Exception e) {
            returnVal = false;
        }
        return returnVal;
    }

	/*******************************************************************************
	* @author       Angelo Rivera
	* @date         26/03/2018         
	* @description  Batch Execute
	* @revision     26/03/2018 - APRIVERA - BMS 1.5 Hot fix - Added addition of user as campaign members
	*******************************************************************************/
    public static Boolean addUserAsCampaignMember(Id campaignId){
        Boolean returnVal = true;
        List<CampaignMember> campaignMemberToInsertList = new List<CampaignMember>();
		//add owner contact to the members list
		String contactUserIdStr = '';
		//If the current user is a BMS user, include the contact to the campaign member list
		//if not, look for the contact with the same email address
		Set<String> bmsProfileIds = new Set<String>();
		for (Profile profileRec: [SELECT Id FROM Profile WHERE Name = 'BMS Admin' OR Name = 'BMS User']) {
		    bmsProfileIds.add(profileRec.Id);
		}
		 
		if (bmsProfileIds.contains(userInfo.getProfileId())) {
		    for (User userOwner: [SELECT Id, ContactId FROM User WHERE Id =: userInfo.getUserId() LIMIT 1]) {
    			contactUserIdStr = userOwner.ContactId;
    		}
		} else {
		    for (Contact contactRecord: [SELECT Id FROM Contact WHERE Email =: userInfo.getUserEmail() OR Monash_Email_Address__c =: userInfo.getUserEmail() LIMIT 1]) {
		        contactUserIdStr = contactRecord.Id;
		    }
		}
		
		if (contactUserIdStr != '' && contactUserIdStr != null) {
			CampaignMember ownerCampaignMember = new CampaignMember();
			ownerCampaignMember.ContactId = contactUserIdStr;
			ownerCampaignMember.CampaignId = campaignId;
			ownerCampaignMember.Status = 'Pending Approval';
			campaignMemberToInsertList.add(ownerCampaignMember);
		}
        
        try {
        	insert campaignMemberToInsertList;
        }catch(Exception e) {
            returnVal = false;
        }
        return returnVal;
    }
    
    /**
    * @author       Nick Guia
    * @date         28/08/2017
    * @description  remote action method for retrieving campaign details and prepopulating
    *               fields for edit
    **/
    @RemoteAction
    global static String retrieveCampaignDetails(String recId) {
        Campaign cmp = [SELECT 
                            Id, Email_Template__c, Name, Message_Header__c, Custom_Message__c,
                            Reply_To__c, Add_CRICOS__c, Add_Base_Signature__c,
                            Notify__c, HTML_Email__c
                        FROM Campaign
                        WHERE Id = :recId
                        LIMIT 1];
        return JSON.serialize(cmp);
    }
    
    /** REUSE ORIGINAL CODES **/

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         19.Jan.2017         
    * @description  Method to populate the html string with styles
    * @revision     ACUSTODIO, 6.Feb.2017 - added styles to <li> tags
    *******************************************************************************/
    private static String addCSSStyles(String strEmailBody) {
        String updatedString = strEmailBody;
        updatedString = updatedString.replace('<h1>', '<h1 style=\"font: Bold 16pt Arial; color: rgb(0,108,171); margin: 5pt 0pt 11pt 0pt;\">');
        updatedString = updatedString.replace('<h2>', '<h2 style=\"font: Bold 14pt Arial; margin: 5pt 0pt 11pt 0pt;\">');
        updatedString = updatedString.replace('<h3>', '<h3 style=\"font: Bold 12pt Arial; margin: 5pt 0pt 11pt 0pt;\">');
        updatedString = updatedString.replace('<p>', '<p style=\"font: 11pt Arial; margin: 5pt 0pt 11pt 0pt;\">');
        updatedString = updatedString.replace('<li>', '<li style=\"padding-bottom: 4pt; font: 11pt Arial;\">');

        //remove existing style before adding the same style
        updatedString = updatedString.replace('<td style=\"vertical-align: top; padding: 8px; border: 1pt solid black\"', '<td ');
        updatedString = updatedString.replace('<td ', '<td style=\"vertical-align: top; padding: 8px; border: 1pt solid black\"');
        return updatedString;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         08.Dec.2016         
    * @description  method to split additionalemails and format it
    * @revision     
    *******************************************************************************/
    private static String formatAdditionalEmails (String additionalEmailsStr) {
        String trimmedEmailStr = additionalEmailsStr.trim();
        String additionalEmailList = '';
        List<String> splitValuesList = new List<String>();
    
        //check first if user entered a list of emails
        if (trimmedEmailStr.contains(';')){
            //remove spaces before splitting
            trimmedEmailStr = trimmedEmailStr.replaceAll('(\\s+)', '');
            //split the values to get the list of emails
            splitValuesList = trimmedEmailStr.split(';');
            //add to email list
            additionalEmailList = retrieveAdditionalEmailList(splitValuesList);

        } else if (trimmedEmailStr.contains(' ') || trimmedEmailStr.contains('\n')){
            //split the values to get the list of emails
            splitValuesList = (trimmedEmailStr.contains('\n'))? trimmedEmailStr.split('\n'): trimmedEmailStr.split(' ');
            List<String> trimmedStringList = new List<String>();
            //add to email list
            for (String trimmedString: splitValuesList) {
                trimmedStringList.add(trimmedString.replaceAll('(\\s+)', ''));
            }
            additionalEmailList = retrieveAdditionalEmailList(trimmedStringList);
        } else { 
            if (validateEmail(trimmedEmailStr)) {
                //add the email address
                additionalEmailList = trimmedEmailStr;
            }
            //TO DO: ADD ERROR CATCHER
        }
        return additionalEmailList;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         08.Dec.2016         
    * @description  method to validate email address
    *               TODO - can possibly be moved to a 'Services' Class
    * @revision     
    *******************************************************************************/
    private static Boolean validateEmail(String email) {
        Boolean isEmailValid = true;
        
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        Matcher emailMatcher = emailPattern.matcher(email);

        //returns false if email is invalid
        if (!emailMatcher.matches()) {
            isEmailValid = false;
        }

        return isEmailValid;
    }

    /*******************************************************************************
    * @author       Ryan Wilson
    * @date         08.Dec.2016         
    * @description  method to put the string of emails to a list
    *               TODO - can possibly be moved to a 'Services' Class
    * @revision     
    *******************************************************************************/
    private static String retrieveAdditionalEmailList(List<String> splitValuesList) {
        
        String additionalEmailList = '';
        for(Integer i=0; i<splitValuesList.size(); i++) {
            //validate if the emails are correct
            if (validateEmail(splitValuesList[i])) {
                additionalEmailList += splitValuesList[i];
                if (i != splitValuesList.size()-1) {
                    additionalEmailList += ';';
                }
            }
        }
        return additionalEmailList;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         02.Mar.2017         
    * @description  constructs the HTML email body
    * @revision     
    *   24.08.2017  Nick Guia   modified method to parse BMSUtils.BuildPreviewEmailWrapper instead
    *                           so that we don't need to insert Campaign record during preview.
    *******************************************************************************/
    private static String constructHTMLBody (BMSUtils.BuildPreviewEmailWrapper bpew) {
        String emailHTMLBody ='';
        String strEmailBody = '';
        EmailTemplate emailTemplateRecord = retrieveEmailTemplateRecord(bpew.emailTemplate);
        emailHTMLBody = emailTemplateRecord.HtmlValue;

        if (bpew.name != null) {
            emailHTMLBody = emailHTMLBody.replace('[SUBJECT]', bpew.name);
        }

        if (bpew.messageHeader != null) {
            emailHTMLBody = emailHTMLBody.replace('[MESSAGE_HEADER]', bpew.messageHeader);
        }

        //CUSTOMISE MESSAGE
        strEmailBody = customiseMessage(bpew.customMessage, bpew.isAddCricos, bpew.isAddBaseSignature);
        emailHTMLBody = emailHTMLBody.replace('[CAMPAIGN_MESSAGE]', strEmailBody);

        if(emailTemplateRecord.Name.contains('Student')){
            emailHTMLBody = emailHTMLBody.replace('[CONTACT_NAME]', 'Student');
        } else if (emailTemplateRecord.Name.contains('Staff')) {
            emailHTMLBody = emailHTMLBody.replace('[CONTACT_NAME]', 'Colleague');
        }

        return emailHTMLBody;
    }

    /**
    * @author   Nick Guia
    * @date     24.08.2017
    * @description  method for customising email body to add css styles as required by the business.
    **/
    private static String customiseMessage(String customMessage, Boolean isAddCricos, Boolean isAddBaseSignature) {
        String strEmailBody = '';
        if(customMessage != null) {
            strEmailBody = customMessage;
            ///if CRICOS is ticked, add it at the bottom of the page
            if (isAddCricos) {
                strEmailBody += '<br/><p style="font: 11pt Arial; margin: 0;">' + System.Label.BMS_CRICOS + '</p>';
            }
            if (isAddBaseSignature) {
                strEmailBody += '<br/><p style="font: Italic 11pt Arial; margin: 0;">' + System.Label.BMS_Base_Signature + '</p>';
            }
            //add CSS styles to the email
            strEmailBody = addCSSStyles(strEmailBody);
        }
        return strEmailBody;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         02.Mar.2017         
    * @description  retrieves the campaign record
    * @revision     
    *******************************************************************************/
    private static EmailTemplate retrieveEmailTemplateRecord (String emailTemplateId) {
        EmailTemplate emailTemplateRecord = new EmailTemplate();
        List<EmailTemplate> templateRetrieved = new List<EmailTemplate>();
        if (emailTemplateId != null) {
            templateRetrieved = [   SELECT  Id, HtmlValue, Name 
                                    FROM    EmailTemplate 
                                    WHERE   ID =: emailTemplateId];
        }
        if (!templateRetrieved.isEmpty()) {
            emailTemplateRecord = templateRetrieved[0];
        }
        return emailTemplateRecord;
    }
}