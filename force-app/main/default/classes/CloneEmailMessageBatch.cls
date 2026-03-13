/*******************************************************************************
* @author       Russell Cadapan
* @date         24/08/2022
* @description  A batch class to flush Email Message HTML/Text Content
* @revision     1.0
*               Russell Cadapan 24.AUG.2022 - Created
*******************************************************************************/

public without sharing class CloneEmailMessageBatch implements Database.Batchable<sObject> {

    String query;
    Boolean flushHtmlContent = false;
    Boolean flushTextContent = false;

    Map<Id, Id> attachmentToEmailMessageMap = new Map<Id, Id>();
    /**
     * @description Constructor class that accepts the parameters from the user to build the queru
     * @param startYear - Integer that determines the start date when the email message was created
     * @param endYear - Integer that determines the end date when the email message was created
     * @param flushHtmlBody - Boolean that instructs the job to flush the HTMLBody field
     * @param flushTextBodythat - Boolean that instructs the job to flush the HTMLBody field
     */
    public CloneEmailMessageBatch(Integer startYear, Integer endYear, Boolean flushHtmlBody, Boolean flushTextBody, String recordLimit, Boolean orderList){

        this.flushHtmlContent = flushHtmlBody;
        this.flushTextContent = flushTextBody;

        // start date will be January 1 of the given start year
        String startDateTime = DateTime.newInstance(startYear, 1, 1, 0 ,0 ,0).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

        // end date will be december 31 of the given end year
        String endDateTime = DateTime.newInstance(endYear, 12, 31, 0 ,0 ,0).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

        // get all fields of all Email Message records
        String emailMessageQuery = 'SELECT ' + CommonUtilities.getAllFields('EmailMessage');

        emailMessageQuery += ' FROM EmailMessage ';

        // that are created from Jan 1 of the given year
        emailMessageQuery += ' WHERE CreatedDate >=' + startDateTime;

        // until December 31 of the given year
        emailMessageQuery += ' AND CreatedDate <=' + endDateTime;

        // where the status is in the set (0=New,1=Read,2=Replied,3=Sent,4=Forwarded,5=Draft)
        emailMessageQuery += ' AND Status != \'5\'';

        // without any attachments
        emailMessageQuery += ' AND HasAttachment = FALSE';

        // and ParentId is not null (related to an enquiry)
        emailMessageQuery += ' AND ParentId != NULL';

        // and the html content is present
        emailMessageQuery += ' AND Is_HTML_Content_Flushed__c = FALSE';

        // ordered by created date from oldest to newest
        if(orderList){
            emailMessageQuery += ' ORDER BY CreatedDate ASC';
        }

        // limit control
        emailMessageQuery += ' LIMIT ' + recordLimit;

        // remove this field
        emailMessageQuery = emailMessageQuery.replace('ValidatedFromAddress','(SELECT Id, EmailMessageId, RelationAddress, RelationId, RelationObjectType, RelationType FROM EmailMessageRelations)');
        this.query = emailMessageQuery;
    }
    /**
     * @description start method that queries the target records to be processed
     */
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator(this.query);

    }

    /**
     * @description execute method that will process the queried records
     *              this method will aim to
     *              1) clone and flush the html/text contents
     *              3) delete the original email message
     */
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        List<EmailMessage> emailMessages = (List<EmailMessage>) scope;

        // map of original EmailMessageId, and its cleansed email message
        Map<Id, EmailMessage> cleansedEmailMessages = new Map<Id, EmailMessage>();

        Savepoint sp = Database.setSavepoint();

        // cleanse the html content from each email message record
        try{

            for(EmailMessage em: emailMessages){
                // flush the contents
                if(em.HtmlBody != null){
                    //clone the email message before flushing the contents
                    EmailMessage cleansedEmailMessage = em.clone(false, true, true, true);
                    if(this.flushHtmlContent){
                        cleansedEmailMessage.HtmlBody = null;
                        cleansedEmailMessage.Is_HTML_Content_Flushed__c = true;
                    }
                    if(this.flushTextContent) cleansedEmailMessage.TextBody = null;

                    // put the cleansed email message mapped to its original email message
                    cleansedEmailMessages.put(em.Id, cleansedEmailMessage);
                }
            }

            // upsert the newly cleansed email messages, with triggers OFF
            TriggerCommon.disableTrigger('EmailMessage');
            insert cleansedEmailMessages.values();
            TriggerCommon.enableTrigger('EmailMessage');

            // delete the original email messages
            if(!cleansedEmailMessages.isEmpty()){
                List<EmailMessage> emForDelete = [SELECT Id FROM EmailMessage WHERE Id IN: cleansedEmailMessages.keySet()];

                if(!emForDelete.isEmpty()){
                    TriggerCommon.disableTrigger('EmailMessage');
                    delete emForDelete;
                    TriggerCommon.enableTrigger('EmailMessage');
                }
            }

        }
        catch(Exception e){
            LogUtilityException.logException(e);
            Database.rollback(sp);
        }
    }

    public void finish(Database.BatchableContext BC){

    }
}