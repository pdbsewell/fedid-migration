/**
 * purpose is a controller extension to enable aggregation and emailing of case
 * info to 'off-system' faculty user, for subsequent assessment, action and closure.
 *
 * @author APRivera
 *
 */
public with sharing class Console_OffSystemEmail_CEv2 {

    @auraEnabled
    public static ThisWrapperClass init(Id recordId){
        ThisWrapperClass thisWrapper = new ThisWrapperClass();
        thisWrapper.lstFacultyOptionsWrapper = new List<FacultyOptionsWrapper>(getFacultyOptions());
        refreshCaseInfo(thisWrapper, recordId);
        getAttachments(thisWrapper);
        return thisWrapper;
    }

    /**
    * faculty options that are stored in custom metadata,
    * so user doesnt have to lookup faculty specific email addresses
    */
    public static List<FacultyOptionsWrapper> getFacultyOptions(){
        List<FacultyOptionsWrapper> lstFacultyOptions = new List<FacultyOptionsWrapper>();
        string prefix = (CommonServices.isSandbox) ? 'test.' : '';
        string labelPrefix = (CommonServices.isSandbox) ? 'Test:' : '';

        for(Off_System_Email_Address__mdt addr : [SELECT label, Email_Address__c from Off_System_Email_Address__mdt Order by label ASC limit 200]){
            FacultyOptionsWrapper fow = new FacultyOptionsWrapper();
            fow.strEmailAddress = prefix + addr.Email_Address__c;
            fow.strLabel = labelPrefix + addr.label;
            lstFacultyOptions.add(fow);
        }
        return lstFacultyOptions;
    }

    /**
    * refreshes key information that will ultimately be embedded
    * into the off system email as html markup
    */
    public static void refreshCaseInfo(ThisWrapperClass thisWrapper, Id recordId){
        thisWrapper.caseRecord = new Case();

        thisWrapper.caseRecord = [select Id, ContactId, caseNumber,
                                    (select id, name from Attachments order by CreatedDate DESC),
                                    (select id,ActivityDate, LastModifiedDate, status,  Description, subject
                                        from Tasks ORDER BY ActivityDate DESC NULLS LAST, LastModifiedDate DESC limit 100),
                                    (select id, HtmlBody, TextBody, MessageDate, FromAddress, ToAddress, FromName
                                        from EmailMessages Order by CreatedDate ASC)
                                    from Case where id =:recordId limit 1];
    }


    public static void getAttachments(ThisWrapperClass thisWrapper){
        thisWrapper.lstAttachments = new List<Attachment>();
        thisWrapper.lstContentDocuments = new List<ContentDocument>();
        Set<Id> setAttachmentParentIds = new Set<Id>();
        Set<Id> setConDocIds = new Set<Id>();

        setAttachmentParentIds.add(thisWrapper.caseRecord.Id);
        // build list of attachments that relates to case, including direct attachments + those appended to email messages
        if(!thisWrapper.caseRecord.EmailMessages.isEmpty()) for(EmailMessage em : thisWrapper.caseRecord.EmailMessages) setAttachmentParentIds.add(em.id);

        //Get attachment records
        for(Attachment cd : [select Id, Name, ContentType from Attachment where ParentId in: setAttachmentParentIds]){
            if(cd.Name.indexOf('__copy') == -1 ) thisWrapper.lstAttachments.add(cd);
        }
        
        //Get files
        for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in: setAttachmentParentIds] ){
            setConDocIds.add(cdLink.ContentDocumentId);
        }
        if(!setConDocIds.isEmpty()){
            for(ContentDocument cd : [select Id, Title, FileExtension from ContentDocument where Id in: setConDocIds]){
                if(cd.Title.indexOf('__copy') == -1 ) thisWrapper.lstContentDocuments.add(cd);
            }
        }
    }


    @auraEnabled
    public static ThisWrapperClass initiateSendingEmail(Id RecordId, String ToEmailAddress, List<Id> lstAttIds, String previewMode, String emailMessageBody){
        System.debug('lstAttIds: ' + lstAttIds);
        ThisWrapperClass thisWrapper = init(RecordId);

        String toAddress= '';
        if(previewMode == 'True'){
            toAddress = UserInfo.getUserEmail();
            thisWrapper.strFeedbackMessage = 'Preview sent to '+ toAddress;
        } else{
            toAddress = ToEmailAddress;
        }
        sendEmail(thisWrapper, toAddress, emailMessageBody, lstAttIds, previewMode);
        return thisWrapper;
    }


    public static void sendEmail(ThisWrapperClass thisWrapper, String ToEmailAddress, String emailMessageBody, List<Id> lstAttIds, String previewMode){
        if(thisWrapper.caseRecord.ContactId == null){
            thisWrapper.strFeedbackMessage = 'You need to link the enquiry to a contact first.';
        } else{
            String htmlBody = generateEmailBody(emailMessageBody, thisWrapper);
            prepareAndSendEmailMessage(thisWrapper, htmlBody, ToEmailAddress, lstAttIds, previewMode, emailMessageBody);
        }

    }

    public static void prepareAndSendEmailMessage(ThisWrapperClass thisWrapper, string htmlBody, String ToEmailAddress, List<Id> lstAttIds, String previewMode, String emailMessageBody){
        Id caseId =  thisWrapper.caseRecord.Id;
        String sub = 'Enquiry referral from Monash Connect: Reference ' + thisWrapper.caseRecord.CaseNumber;
        String plainTxt = 'Please review the html version of this email';

        Messaging.SingleEmailMessage semail = createSingleEmailMessage(sub, plainTxt, ToEmailAddress, htmlBody, caseId);
        EmailMessage emailMsg = createEmailMsg(sub, plainTxt, ToEmailAddress, htmlBody, caseId);

        appendAttachments(semail, lstAttIds, thisWrapper);
        actualSend(semail, emailMsg, previewMode, thisWrapper, emailMessageBody);
    }

    public static Messaging.SingleEmailMessage createSingleEmailMessage(String sub, String plainTxt, String ToEmailAddress, string htmlBody, Id caseId){
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        semail.setToAddresses(new String[]{ ToEmailAddress });
        semail.setSubject(sub);
        semail.setPlainTextBody(plainTxt);
        semail.setHtmlBody(htmlBody);
        semail.setWhatId(caseId);
        semail.setOrgWideEmailAddressId(CommonServices.orgWideAddressId(CommonServices.ORGWIDE_ADDRESS_MONASH));
        return semail;
    }

    public static EmailMessage createEmailMsg(String sub, String plainTxt, String ToEmailAddress, string htmlBody, Id caseId){
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.ParentID = caseId;
        emailMsg.HtmlBody = htmlBody;
        emailMsg.MessageDate = datetime.now();
        emailMsg.Subject = sub;
        emailMsg.TextBody = plainTxt;
        emailMsg.ToAddress = ToEmailAddress;
        return emailMsg;
    }

    public static void appendAttachments(Messaging.SingleEmailMessage semail, List<Id> lstAttIds, ThisWrapperClass thisWrapper){
        if(!lstAttIds.isEmpty()){
            Set<Id> setAttsId = new Set<Id>();
            for(Id attId : lstAttIds){
                setAttsId.add(attId);
            }
            thisWrapper.setAttachmentNames = new Set<String>();
            Messaging.EmailFileAttachment[] files = new Messaging.EmailFileAttachment[]{};
        	
        	//Append attachments
            for(attachment a : [select id,body,name,contenttype from attachment where id in:setAttsId]){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setBody(a.body);
                efa.setContentType(a.contenttype);
                efa.setFileName(a.name);
                
                files.add(efa);
                thisWrapper.setAttachmentNames.add(a.name); //APR - 6/11/18 - Fix to include attachments in Task Description
            }
            
            //Append contentversions
            for(ContentVersion cv : [SELECT VersionData, FileType, Title, PathOnClient
                                        FROM ContentVersion
                                            WHERE ContentDocumentId in: setAttsId AND IsLatest = true]){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                blob WOCFbody = cv.VersionData;
                efa.setBody(WOCFbody);
                efa.setFileName(cv.Title+'.'+cv.FileType);
                files.add(efa);
                thisWrapper.setAttachmentNames.add(cv.Title);
            }
            
            if(!files.isEmpty()) semail.setFileAttachments(files);
        }
    }

    public static void actualSend(Messaging.SingleEmailMessage semail, EmailMessage emailMsg, String previewMode, ThisWrapperClass thisWrapper, String emailMessageBody){
        try{
            if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ semail });

            // if is sent (versus preview) add a task to record send
            if(previewMode  == 'False'){
                //insert emailMsg;
                thisWrapper.strFeedbackMessage = 'Successfully sent email to recipient.';


                Task tskToInsert = new Task();
                tskToInsert.Subject = 'Email: ' + semail.getSubject();
                tskToInsert.Type = 'Internal Email';
                tskToInsert.WhatId = semail.getWhatId();
                tskToInsert.Status = 'Completed';
                tskToInsert.ActivityDate = system.today();
                tskToInsert.Description = 'Sent To: ' + semail.toAddresses + '\n\n';
                tskToInsert.Description += 'Date/Time Sent: ' + getLocalTime(System.now()) + '\n\n';
                tskToInsert.Description += 'Message: ' + '\n' + emailMessageBody + '\n\n';
                tskToInsert.Description += 'Attachments: ' + thisWrapper.setAttachmentNames;
                insert tskToInsert;

            }
        } catch (exception ex){
            thisWrapper.strFeedbackMessage = 'Email not sent due to an error. ' + ex.getMessage();
            system.debug('Error = '+ex.getMessage());
            Exlog.add('Class','console_OffSystemEmail','prepareAndSendEmail',ex);
        }
    }


    public static DateTime getLocalTime(DateTime timeToConvert){
        DateTime localTime;
        if(timeToConvert != null){
            TimeZone tz = UserInfo.getTimeZone();
            localTime = timeToConvert.AddSeconds(tz.getOffset(timeToConvert)/1000);
        }
        return localTime;
    }

    /** pulls all the email sections together as a string of html markup to be placed in email body */
    public static String generateEmailBody(String emailMessageBody, ThisWrapperClass thisWrapper){
        String content = '<html><body>';
        content += emailHeader(emailMessageBody);

        content += '<br/><br/>';
        content += sectionHeader('Enquiry Details');
        content += emailCaseDetails(thisWrapper.caseRecord.Id);

        if(thisWrapper.caseRecord.contactId != null){
            content += '<br/><br/>';
            content += sectionHeader('Contact Details');
            content += emailContactDetails(thisWrapper.caseRecord.Id);
        }

        content += '<br/><br/>';
        content += sectionHeader('Activity History');
        content += activityDetails(thisWrapper.caseRecord);


        content += '<br/><br/>';
        content += sectionHeader('Email History');
        content += emailHistory(thisWrapper.caseRecord);
        content += '<br/>';
        //Add case thread id
        content += '<b>System reference: ' + getThreadId(thisWrapper.caseRecord.Id) + '. Please do not delete.</b>';

        //End Content
        content += '</body></html>';

        return content;
    }

    /** adds header text markup to email */
    public static String emailHeader(String msg){
        if(msg > '') msg = EncodingUtil.urlDecode(msg,'UTF-8');
        msg = msg.replaceAll('\n','<br />');
        return '<p>' + msg + '</p>';
    }

    /**
    * adds a section header markup to email body
	* @param sectionTitle the text that is to be marked up as a title in the email body
	*/
    public static String sectionheader(String sectionTitle){
        String hdr = '<table style="width:100%;"><tr style="height:35px;"><td style="padding-left:5px;width:640px;background:lightgrey;color:white;">' + sectionTitle + '</td></tr></table>';
        return hdr;
    }


    /** build out all fields that are in field set used by template */
    public static String emailContactDetails(Id caseId){
        string details = '';
        Id contId = [select id, contactid from case where id =:caseId limit 1].contactId; // in case has been linked without a page refresh
        if(contId != null){
            details = '<table>';
            Contact contactDetails = retrieveContactFields(contId);
            for(Schema.FieldSetMember fld :SObjectType.Contact.FieldSets.MC_off_system_referral.getFields()) {
                Schema.DisplayType typ = fld.getType();
                details +='<tr><td style="width:200px;">' + fld.getLabel() + '</td><td>';
                object val = (contactDetails.get(fld.getFieldPath()) == null) ? '' : contactDetails.get(fld.getFieldPath());
                if(typ == Schema.DisplayType.Datetime) val = strDate((Datetime)val);
                details += (String)val;
                details += '</td></tr>';
            }
            details += '</table>';
        }
        return details;
    }


    /** build out all fields that are in field set used by template */
    public static String emailCaseDetails(Id caseId){
        string details = '<table>';
        Case caseDetails = retrieveCaseFields(caseId);
        for(Schema.FieldSetMember fld :SObjectType.Case.FieldSets.MC_off_system_referral.getFields()) {
            Schema.DisplayType typ = fld.getType();
            details +='<tr><td style="width:200px;">' + fld.getLabel() + '</td><td>';
            object val= (caseDetails.get(fld.getFieldPath()) == null) ? '' : caseDetails.get(fld.getFieldPath());
            if(typ == Schema.DisplayType.Datetime) val = strDate((Datetime)val);
            //Replace string new line to html new line since the content will be shown on a html email
            String fieldContent = (String)val;
            if(typ == Schema.DisplayType.Textarea){
                fieldContent = fieldContent.replace('\n','<br/>');
            }

            details += fieldContent;
            details += '</td></tr>';
        }
        details += '</table>';
        return details;
    }

    /** adds activity hx markup to email */
    public static String activityDetails(Case caseRecord){
        String hx = '<table>';
        hx += '<th style="text-align:left;">Activity Date</th><th style="text-align:left;">Subject</th><th style="text-align:left;">Description</th>';
        for(Task act : caseRecord.Tasks){
            if(act.Subject == null) act.Subject = '';
            string activityDate = (act.ActivityDate == null) ? '' : strDate(act.ActivityDate).substringBefore(' ');
            hx += '<tr><td>' + activityDate + '</td>';
            hx += '<td>' + act.Subject + '</td>';
            string descriptx = (act.Subject.startsWith('Email:')) ? '' : act.Description;
            hx += '<td>' + descriptx + '</td>';
            hx += '</tr>';
        }
        hx += '</table>';
        return hx;
    }

    /* adds email history markup to email */

    public static String emailHistory(Case caseRecord){
        String hx = '<table>';
        for(EmailMessage em : caseRecord.EmailMessages){
            // use html version preferably, or revert to plain text if html not available

            // apply a header per email
            hx += '<tr><td style="vertical-align:top;"><hr/><i><b>' + strDate(em.MessageDate) + '<br/>';
            hx += 'From: ' + em.FromName + '(' + em.FromAddress +')' + '<br/>';
            hx += 'To: '+em.ToAddress + '<br/>';
            hx += '</b></i><hr/></td>';

            // embed email content
            hx += '<td style="vertical-align:top;"><hr/>';
            if(em.HtmlBody > ''){
                hx += em.HtmlBody;
            } else
                    if(em.TextBody > ''){
                        //Replace string new line to html new line since the content will be shown on a html email
                        String emailContent = em.TextBody;
                        emailContent = emailContent.replace('\n','<br/>');
                        hx += emailContent;
                    }
            hx += '</td></tr>';
        }
        hx += '</table>';
        return hx;
    }

    public static String strDate(datetime dt){
        try{
            string localdt = dt.format('dd/MM/YY hh:mm aa'); // reconstruct in local dd/mm/yy format
            return localdt;
        } catch (exception e) {
            return '';
        }

    }

    /**
        * retrieve all case fields that are in field set used by template
        * from the case fieldset dedicated to this process - MC Off System Referral
        * @param contactId the id of the contact that is linked to the current enquiry
        */
    public static Case retrieveCaseFields(id caseId){
        String queryString = 'select ';
        for(Schema.FieldSetMember fld :SObjectType.Case.FieldSets.MC_off_system_referral.getFields()) {
            queryString += fld.getFieldPath()+',';
        }
        queryString += ' id from Case where id =\''+ caseId+'\' limit 1';
        return Database.query(queryString);
    }

    /**
     * retrieve all contact fields that are in field set used by template
     * from the contact fieldset dedicated to this purpose - MC Off System Referral
	 * @param contactId the id of the contact that is linked to the current enquiry
	 */
    public static Contact retrieveContactFields(id contactId){
        String queryString = 'select ';
        for(Schema.FieldSetMember fld :SObjectType.Contact.FieldSets.MC_off_system_referral.getFields()) {
            queryString += fld.getFieldPath()+',';
        }
        queryString += ' id from Contact where id =\'' + contactId+ '\' limit 1';
        return Database.query(queryString);
    }

    public static String getThreadId(String caseId){
        return '[ ref:_'
                + UserInfo.getOrganizationId().left(5)
                + UserInfo.getOrganizationId().mid(10,5) + '._'
                + caseId.left(5)
                + caseId.mid(9,6) + ':ref ]';
    }

    public class ThisWrapperClass{
        @AuraEnabled public List<FacultyOptionsWrapper> lstFacultyOptionsWrapper {get; set;}
        @AuraEnabled public Case caseRecord {get; set;}
        @AuraEnabled public List<Attachment> lstAttachments {get; set;}
        @AuraEnabled public List<ContentDocument> lstContentDocuments {get; set;}
        @AuraEnabled public String strFeedbackMessage {get; set;}
        @AuraEnabled public Set<String> setAttachmentNames {get; set;}

    }

    public class FacultyOptionsWrapper{
        @AuraEnabled public String strEmailAddress {get; set;}
        @AuraEnabled public String strLabel {get; set;}
    }
}