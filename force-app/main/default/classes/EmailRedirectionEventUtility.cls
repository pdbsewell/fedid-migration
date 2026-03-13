/**
 * @description Utility Class for Email Redirection events
 *
 *
 * @author Matthew Maramot
 * @date 25/03/2024
 **/
public class EmailRedirectionEventUtility {    
        /***
    * Method name	: processEmailRedirectionEvent
    * Description	: Process EmailRedirection events 
    * Author        : Matthew Maramot
    * Return Type	: void
    * Parameter     : List of Email Redirection events
    */
    public static void processEmailRedirectionEvent(List<Email_Redirection_Event__e> EmailRedirectionEvents){
        //Initialize Variables
        List<Email_Redirection_Event__e> cloneAttachmentList = new List<Email_Redirection_Event__e>();
        
        //Check action and perform setup
        for(Email_Redirection_Event__e loopEvent : EmailRedirectionEvents){
            if(loopEvent.Action__c == 'cloneAttachment'){
                cloneAttachmentList.add(loopEvent);
            }
        }

        try{
            List<Attachment> attachmentsInsert = EmailRedirectionEventUtility.cloneAttachments(cloneAttachmentList);
            
            if(!attachmentsInsert.isEmpty()){
                insert attachmentsInsert;
            }
        }
        catch(Exception error){
            Nebula.Logger.error(error.getMessage(), error);
        }
        Nebula.Logger.saveLog();
    }
    
    /***
    * Method name	: cloneAttachments
    * Description	: Clones attachments for EmailRedirection events 
    * Author        : Matthew Maramot
    * Return Type	: List<Attachment>
    * Parameter     : List of Email Redirection events
    */
    public static List<Attachment> cloneAttachments(List<Email_Redirection_Event__e> emailRedirectionEventList){
        //Initialize variables
        Map<String, Id> inputMap = new Map<String, Id>();
        Map<Id, String> idToMessageIdMap = new Map<Id, String>();
        List<String> likeExpressionsA = new List<String>();
        List<String> likeExpressionsB = new List<String>();
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        List<Attachment> attachmentsInsert = new List<Attachment>();

        //Retrieve parameter input
        for(Email_Redirection_Event__e loopEvent : emailRedirectionEventList){
            inputMap.putAll((Map<String, Id>) JSON.deserialize(loopEvent.Parameter__c, Map<String, Id>.class));
        }
        
        //Parse input for Message Identifier & EmailRoutingAddresss
        Integer counter = 0;
        for(String str : inputMap.keySet()){
            List<String> inputs = str.split('@@@@');

            //Split queries to account for potential char limits
            if(counter < 100){
                likeExpressionsA.add('(MessageIdentifier LIKE \'%' + inputs[0] + '\' AND EmailRoutingAddressId = \'' + inputs[1] + '\')');
            }
            else{
                likeExpressionsB.add('(MessageIdentifier LIKE \'%' + inputs[0] + '\' AND EmailRoutingAddressId = \'' + inputs[1] + '\')');
            }
            counter++;
        }

        if(!likeExpressionsA.isEmpty()){
            String queryA = 'SELECT Id, MessageIdentifier, EmailRoutingAddressId FROM EmailMessage WHERE HasAttachment = TRUE AND (' + String.join(likeExpressionsA, ' OR ') + ')';
            emailMessages = Database.query(queryA);

        }
        if(!likeExpressionsB.isEmpty()){
            String queryB = 'SELECT Id, MessageIdentifier, EmailRoutingAddressId FROM EmailMessage WHERE HasAttachment = TRUE AND (' + String.join(likeExpressionsB, ' OR ') + ')';
            List<EmailMessage> emailMessagesB = Database.query(queryB);
            
            //Combine query results
            emailMessages.addAll(emailMessagesB);
        }
        
        //Create Id to MessageIdentifier lookup
        for(EmailMessage loopEmailMessage : emailMessages){
            idToMessageIdMap.put(loopEmailMessage.Id, EmailMessageUtility.getRedirectionId(loopEmailMessage) + '@@@@' + loopEmailMessage.EmailRoutingAddressId);
        }

        //Query for Attachments
        if(!idToMessageIdMap.isEmpty()){
            List<Attachment> attachments = [SELECT Id, ParentId, Name, Body, ContentType, IsPrivate FROM Attachment WHERE ParentId IN :idToMessageIdMap.keySet()];

            //For each attachment
            for(Attachment loopAttachment : attachments){
                //Clone and assign to cloned email
                String messageId = idtoMessageIdMap.get(loopAttachment.ParentId);

                Attachment clonedAttachment = new Attachment(
                        ParentId = inputMap.get(messageId),
                        Name = loopAttachment.Name,
                        Body = loopAttachment.Body,
                        ContentType = loopAttachment.ContentType,
                        IsPrivate = loopAttachment.IsPrivate
                    );
                    attachmentsInsert.add(clonedAttachment);
                }
            }
        return attachmentsInsert;
    }
}