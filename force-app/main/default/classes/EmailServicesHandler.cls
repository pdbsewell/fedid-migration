/*
 * @author			Ayush Agrawal (ayush.agrawal@monash.edu)
 * @group			Student Admin - Academic Progress
 * @description		SA-791 Apex Email Service handler to link incoming emails as EmailMessage records
 * 					tied to a Case.
 * @revision		SA-839 Capture refParentId, refToAddress, and refToId references instead of just ref. Also,
                    generate appropriate EmailMessageRelation record.
 * @revision		SA-1760 Use htmlBody if plainTextBody is unavailable.
 * @revision		SA-1762 Map EmailMessage.MessageIdentifier from InboundEmail.messageId to make the enquiry re-open rule system work.
 */

// This is an evolving experiment.
global class EmailServicesHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        String searchIn = email.plainTextBody.replaceAll('\r\n|\r|\n', '');
        if(String.isBlank(searchIn)) {
            searchIn = email.htmlBody.replaceAll('\r\n|\r|\n', '');
        }

        Matcher mParentId = Pattern.compile('.*refParentId:(.+):refParentId.*').matcher(searchIn);
        
        // We are obtaining refToAddress from the email instead of querying Salesforce because this class works on a
        // non-bulkifiable interface and we want to avoid any locking contention by issuing database queries.
        // Further, we need the ToAddress in these emails, as without this, we found that the standard email composer
        // utility in Salesforce does not generate the To address automatically once these emails are received. This is
        // because that component looks at the most recent EmailMessage for determining the ToAddress. Since, it ends up
        // being blank, the agent has to manual type it in. This is to prevent that.
        Matcher mToAddress = Pattern.compile('.*refToAddress:(.+):refToAddress.*').matcher(searchIn);
        Matcher mToId = Pattern.compile('.*refToId:(.+):refToId.*').matcher(searchIn);
        
        if(mParentId.matches() && mToAddress.matches() && mToId.matches()) {
            String caseId = mParentId.group(1);
            String contactId = mToId.group(1);
            
            if(caseId instanceOf Id && contactId instanceof Id) {
                EmailMessage em = new EmailMessage();
                em.HtmlBody = email.htmlBody;
                em.MessageIdentifier = email.messageId;
                em.ParentId = caseId;
                em.Subject = email.subject;
                em.TextBody = email.plainTextBody;
                em.Incoming = true;
                
                if(email.headers != null){
                    List<String> headerList = new List<String>();
                    for(Integer i = 0; i < email.headers.size(); i++) {
                        headerList.add(email.headers[i].name + ':' + email.headers[i].value);
                    }
                    em.Headers = String.join(headerList, '\n');
                }
                
                insert em;
                
                EmailMessageRelation emr = new EmailMessageRelation();
                emr.EmailMessageId = em.Id;
                emr.RelationAddress = mToAddress.group(1);
                emr.RelationId = contactId;
                emr.RelationType = 'ToAddress';
                
                insert emr;
            }
        }
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        return result;
    }
}