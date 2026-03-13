/**
 * purpose is a controller extension to enable aggregation and emailing of case
 * info to 'off-system' faculty user, for subsequent assessment, action and closure.
 * 
 * @author PwC
 * 
 */ 

public with sharing class Console_OffSystemEmail_CE {
    
    public final Case c {get; private set;}
    public Case cse {get; private set;}
    private id caseId;
    public String feedbackMsg {get{ if (feedbackMsg == null) feedbackMsg = ''; return feedbackMsg;} private set;}
    public String ToEmailAddress {get;set;}
    private String TASK_SUBJECT_EMAILREFSENT  ='Email:off-system email referral sent';
    private Case caseDetails {get; private set;}
    private Contact contactDetails {get; private set;}
    private String msg;
    private String mode;
    private set<id> attachmentParentIds; // used to aggregate attachments on case AND related email messages
    public list<attachment> attachments { get; private set;} // aggregate of attachments relating to case
    public list<ContentDocument> documents { get; private set;} // aggregate of attachments relating to case
    public boolean previewMode {get; private set;}
    public Set<String> setAttachmentName;
    private Map<string,string> params {
        get{
            params = ApexPages.currentPage().getParameters();
            return params;
        }
        set;
    }
    
    private String strDate(datetime dt){
        try{
            string localdt = dt.format('dd/MM/YY hh:mm aa'); // reconstruct in local dd/mm/yy format
        	return localdt;
        } catch (exception e) {
            return '';
        }
        
    }
    
    /**
     * faculty options that are stored in custom metadata, 
     * so user doesnt have to lookup faculty specific email addresses 
    */
    
    public list<selectOption> facultyOptions {
        get{
            list<selectOption> options = new list<selectOption>();
            options.add(new SelectOption('','- Not Selected -')); 
            string prefix = (CommonServices.isSandbox) ? 'test.' : '';
            string labelPrefix = (CommonServices.isSandbox) ? 'Test:' : '';
            for(Off_System_Email_Address__mdt addr : [select label,
                                                      Email_Address__c 
                                                      from Off_System_Email_Address__mdt Order by label ASC limit 200]){
            	options.add(new SelectOption(prefix + addr.Email_Address__c, labelPrefix + addr.label));                                           
            }
            return options;
            
        }
    }
    
    public pageReference dummyAction() { return null; }

	/**
	 * refreshes key information that will ultimately be embedded
	 * into the off system email as html markup
	 */    
    private void refreshCaseInfo(){
        id cId = params.get('id'); // cast to an id so no xss issue here
        cse = [select id,
               		  contactId,
               		  caseNumber,
              		  (select id,
                      		  name from Attachments order by CreatedDate DESC),
               		  (select id,
                       		  ActivityDate,
                       		  LastModifiedDate,
                       		  status,
                        	  Description,
                      		  subject
                      		  from Tasks ORDER BY ActivityDate DESC NULLS LAST, LastModifiedDate DESC limit 100),
               		  (select id,
                       		  HtmlBody,
                       	  	  TextBody,
                       		  MessageDate,
                       		  FromAddress,
                       		  ToAddress,
                       		  FromName
                        	  from EmailMessages Order by CreatedDate ASC)
               from Case where id =:caseId limit 1];
    	
        // build list of attachments that relates to case, including direct attachments + those appended to email messages
        
        for(EmailMessage em : cse.EmailMessages) attachmentParentIds.add(em.id); 
        for(attachment a : [select id, name from Attachment where ParentId in:attachmentParentIds Order by Name ASC limit 100]) {
            if(a.name.indexOf('__copy') == -1 ) attachments.add(a);
        }
        
        //Get files
        Set<Id> setConDocIds = new Set<Id>();
        for(ContentDocumentLink cdLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId in: attachmentParentIds] ){
            setConDocIds.add(cdLink.ContentDocumentId);
        }
        if(!setConDocIds.isEmpty()){
            for(ContentDocument cd : [select Id, Title, FileExtension from ContentDocument where Id in: setConDocIds]){
                if(cd.Title.indexOf('__copy') == -1 ) documents.add(cd);
            }
        }
    }
    
    /** controller extension instantiation */
    
    public console_OffSystemEmail_CE(ApexPages.StandardController controller){
        attachmentParentIds = new Set<id>();
        attachments = new List<attachment>();
        documents = new List<ContentDocument>();
        caseId = controller.getId();
        previewMode = false;
        attachmentParentIds.add(caseId);
        refreshCaseInfo();
    }
    
    /** 
     * method to finalise email
     * @param htmlBody the html markup that is to be injected into the email body
     */
    
    private string prepareAndSendEmail(string htmlBody){
        
        String ids = params.get('attIds');
        String sub = 'Enquiry referral from Monash Connect: Reference ' + cse.CaseNumber;
        String plainTxt = 'Please review the html version of this email';
        
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        semail.setToAddresses(new String[]{ ToEmailAddress });
        semail.setSubject(sub);
        semail.setPlainTextBody(plainTxt);
        semail.setHtmlBody(htmlBody);
        semail.setWhatId(caseId);
        semail.setOrgWideEmailAddressId(CommonServices.orgWideAddressId(CommonServices.ORGWIDE_ADDRESS_MONASH));
        
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.ParentID = cse.id;
        emailMsg.HtmlBody = htmlBody;
        emailMsg.MessageDate = datetime.now();
        emailMsg.Subject = sub;
        emailMsg.TextBody = plainTxt;
        emailMsg.ToAddress = ToEmailAddress;
        
        
        
        // append attachments
        Set<id> attSet = new Set<id>();
        if(ids > ''){
            Messaging.EmailFileAttachment[] files = new Messaging.EmailFileAttachment[]{};
        	setAttachmentName = new Set<String>();
            for(String aid : ids.split(';')) attSet.add(aid);
            for(attachment a : [select id,body,name,contenttype from attachment where id in:attSet]){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setBody(a.body);
                efa.setContentType(a.contenttype);
                efa.setFileName(a.name);
                
                files.add(efa);
				setAttachmentName.add(a.name); //APR - 6/11/18 - Fix to include Attachment names on Task Description
            }
            
            //Append contentversions
            for(ContentVersion cv : [SELECT VersionData, FileType, Title, PathOnClient
                                        FROM ContentVersion
                                            WHERE ContentDocumentId in: attSet AND IsLatest = true]){
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                blob WOCFbody = cv.VersionData;
                efa.setBody(WOCFbody);
                efa.setContentType(AttachmentServices.getMIMEType(cv.PathOnClient, cv.FileType));
                efa.setFileName(cv.Title);
                files.add(efa);
				setAttachmentName.add(cv.Title); //APR - 6/11/18 - Fix to include Attachment names on Task Description
            }
            
            if(!files.isEmpty()) semail.setFileAttachments(files);
        }
        
        try{
            if(!Test.isRunningTest()) Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ semail });
            // if is sent (versus preview) add a task to record send
            if(!previewMode){
                //APR - 6/11/2018 - replaced email message insertion to Task Insertion
                Task tskToInsert = new Task();
                tskToInsert.Subject = 'Email: ' + semail.getSubject();
                tskToInsert.Type = 'Internal Email';
                tskToInsert.WhatId = semail.getWhatId();
                tskToInsert.Status = 'Completed';
                tskToInsert.ActivityDate = system.today();
                tskToInsert.Description = 'Sent To: ' + semail.toAddresses + '\n\n';
                tskToInsert.Description += 'Date/Time Sent: ' + getLocalTime(System.now()) + '\n\n';
                tskToInsert.Description += 'Message: ' + '\n' + msg + '\n\n';
                tskToInsert.Description += 'Attachments: ' + setAttachmentName;
                insert tskToInsert;

                /*
            	insert emailMsg;
                list<attachment> clonedAttachments = new List<attachment>(); 
                for(attachment a : [select id,body,name,contenttype from attachment where id in:attSet]){
                 	attachment att = a.clone(false,true,true,true);
                     att.ParentId = emailMsg.id;
                    att.Name = att.Name + '__copy';
                     clonedAttachments.add(att);
                }
                insert clonedAttachments;
                */
        	}	
            return feedbackMsg;
        } catch (exception ex){
            system.debug('Error = '+ex.getMessage());
            Exlog.add('Class','console_OffSystemEmail','prepareAndSendEmail',ex);
            return 'An error occured. Please try again or notify administrator.'+ex.getMessage();        
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
	
    /** page reference used to initiate the off system email send */ 
    
    public pageReference sendEmail(){
        
        msg = params.get('msg');
        if(!feedbackMsg.startsWith('Preview sent to')) { feedbackMsg = 'Sent';ToEmailAddress = params.get('toemail'); }
        
        // confirm there has been a contact linked to the case before proceeding - cant assume UI reflects state right now
        
        Boolean contactLinked = false;
        try{ 
        	contactLinked = ([select count() from case where id =:caseId and contactId != null limit 1] == 0) ? false : true;
        } 
        catch (exception ex){
            // will assume that error means integrity issue so dont proceed.    
        }
        // build a single email instance and send
        if(!contactLinked){
            feedbackMsg = 'You need to link the enquiry to a contact first.';
            
        } else
        
        if(ToEmailAddress == '' || ToEmailAddress == null){
            feedbackMsg = 'Error. Need to provide an email address to send to.';
        } else {
        	feedbackMsg = prepareAndSendEmail(emailBody()); // returns a message of ok or error
        }
        previewMode = false; // reset, so only set to true via the 'send preview' action
        return null;
        
    }
    
    /** sets the target email address to that of the context user */
    
    public pageReference sendPreviewEmail(){
        previewMode = true;
        ToEmailAddress = UserInfo.getUserEmail();
        feedbackMsg = 'Preview sent to '+ ToEmailAddress;
        sendEmail();
        ToEmailAddress = '';
        return null;
        
    }
    
    /** 
     * retrieve all contact fields that are in field set used by template 
     * from the contact fieldset dedicated to this purpose - MC Off System Referral
	 * @param contactId the id of the contact that is linked to the current enquiry
	 */
     
    private Contact retrieveContactFields(id contactId){
        String queryString = 'select ';
        for(Schema.FieldSetMember fld :SObjectType.Contact.FieldSets.MC_off_system_referral.getFields()) {
         queryString += fld.getFieldPath()+',';
        }
        queryString += ' id from Contact where id =\'' + contactId+ '\' limit 1';
        return Database.query(queryString);
    }
    
    /** 
     * retrieve all case fields that are in field set used by template
     * from the case fieldset dedicated to this process - MC Off System Referral 
	 * @param contactId the id of the contact that is linked to the current enquiry
	 */ 
    private Case retrieveCaseFields(id caseId){
        String queryString = 'select ';
        for(Schema.FieldSetMember fld :SObjectType.Case.FieldSets.MC_off_system_referral.getFields()) {
         queryString += fld.getFieldPath()+',';
        }
        queryString += ' id from Case where id =\''+ caseId+'\' limit 1';
        return Database.query(queryString);
    }
    
    /** adds header text markup to email */ 
     
    private String emailHeader(){
        string msg = params.get('msg');
        if(msg > '') msg = EncodingUtil.urlDecode(msg,'UTF-8');
        msg = msg.replaceAll('\n','<br />');
        return '<p>' + msg + '</p>';
    }
    
    /** build out all fields that are in field set used by template */
    
    private String emailCaseDetails(){
        string details = '<table>';
        caseDetails = retrieveCaseFields(cse.id);
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
    
    /** build out all fields that are in field set used by template */
     
    private String emailContactDetails(){
        string details = '';
        id contId = [select id, contactid from case where id =:cse.id limit 1].contactId; // in case has been linked without a page refresh
        if(contId != null){
            details = '<table>';
            contactDetails = retrieveContactFields(cse.contactid);
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
    
    /** 
    * adds a section header markup to email body 
	* @param sectionTitle the text that is to be marked up as a title in the email body
	*/
     
    private String sectionheader(String sectionTitle){
        String hdr = '<table style="width:100%;"><tr style="height:35px;"><td style="padding-left:5px;width:640px;background:lightgrey;color:white;">' + sectionTitle + '</td></tr></table>';
    	return hdr;
    }
    
    /* adds email history markup to email */
     
    private String emailHistory(){
        String hx = '<table>';
        for(EmailMessage em : cse.EmailMessages){
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
    
    /** adds activity hx markup to email */
     
    private String activityDetails(){
        String hx = '<table>';
        hx += '<th style="text-align:left;">Activity Date</th><th style="text-align:left;">Subject</th><th style="text-align:left;">Description</th>';
        for(Task act : cse.Tasks){
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
    
    /** pulls all the email sections together as a string of html markup to be placed in email body */
    
    private String emailBody (){
        refreshCaseInfo();
        
        String content = '<html><body>';
        
        content += emailHeader();
        
        content += '<br/><br/>';
        content += sectionHeader('Enquiry Details');
        content += emailCaseDetails();
        
        if(cse.contactid != null){
            content += '<br/><br/>';
            content += sectionHeader('Contact Details');
            content += emailContactDetails();
        }
        
        content += '<br/><br/>';
        content += sectionHeader('Activity History');
        content += activityDetails();
        
        content += '<br/><br/>';
        content += sectionHeader('Email History');
        content += emailHistory();
        
        //Add case thread id
        content += '<b>System reference: ' + EmailMessages.getFormattedThreadingToken(caseId) + '. Please do not delete.</b>';
        
        //End Content
        content += '</body></html>';
        
        return content;
    }
    
    public static String getThreadId(String caseId){
        return '[ ref:_'
                + UserInfo.getOrganizationId().left(5)
                + UserInfo.getOrganizationId().mid(10,5) + '._'
                + caseId.left(5)
                + caseId.mid(9,6) + ':ref ]';
    }
}