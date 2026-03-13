/**
 * @author          inderpal.dhanoa@monash.edu
 * @description		MCT-414 - Handle autoclosure of "JRG" case records
 * @date            Jul.2024
 * @group			MC
 * Revision
 * 1.1   11.07.2024   Idhanoa     Enhancement to auto-close JRG Campaign's cases and OCR's (MCT-414)
 * 1.2   11.08.2024   Idhanoa     Enhancement to remove Case Outcome (MCT-456)
*/
public without sharing class AutoCloseJRGCampaignRecords implements Database.Batchable<Campaign>, Schedulable, Database.Stateful{
    Boolean hasEnqError = false;
    public static final String SCHEDULE = '0 0 4 * * ?'; 
    public static final String SOLVED = 'Solved'; 

    /**
    * @description Implement start method (from interface) to run the retrieve records
    * @param bc DataBase Batchable context 
    * @return Iterable list of Campaigns
    */
    public Iterable<Campaign> start(Database.BatchableContext bc) {
        Id advisoryId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Advisory').getRecordTypeId(); 
        Date yesterdayDate;
        Date todayDate = Date.today();
        yesterdayDate = todayDate.addDays(-1);
        List<Campaign> jrgCampaigns = [SELECT Id,Name,EndDate,Owner.Email FROM CAMPAIGN WHERE EndDate = :yesterdayDate AND RecordTypeId = :advisoryId AND Type ='JRG'];
        return jrgCampaigns;
    }

    /**
    * @description Implement execute method (from interface) to run the business logic
    * @param bc DataBase Batchable context 
    * @param closedCampaigns List of campaigns to be closed
    */
    public void execute(Database.BatchableContext bc, List<Campaign> closedCampaigns) {
        String errorCsv;
        String[] emailCsvRows;
        String clientQuestion;
        Set<Id> campIds = new Set<Id>();
        for(Campaign camp : closedCampaigns){
            campIds.add(camp.Id);
        }
        // Retrieve linked Enquiries BUT do not retrieve Enquires linked to Outbound Call Records
        List<Case> closeEnqs = new List<Case>();
        Map<Id, Case> openEnqs = new Map<Id, Case>([SELECT Id, CaseNumber, Status, Bypass_Case_Assignment__c, Description 
                                                     FROM Case 
                                                     WHERE Campaign__c IN :campIds AND 
                                                     Status != :SOLVED AND
                                                     ID NOT IN (SELECT Case__c FROM Outbound_Call_Result__c WHERE Campaign__c IN :campIds)]);
        for(Case openEnq : openEnqs.values()){
            clientQuestion = String.isBlank(openEnq.Description) ? Label.Auto_Close_JRG_Enquiries : openEnq.Description + '\n\n' + Label.Auto_Close_JRG_Enquiries;
            closeEnqs.add(new Case(Id = openEnq.Id, Status = SOLVED, Description = clientQuestion, Bypass_Case_Assignment__c=true));
        }
        
        //Close the Enquiries
        if(!closeEnqs.isEmpty()){
            Database.SaveResult[] results = Database.update(closeEnqs, false);
            Case cse;            
            Case opnCse;
            emailCsvRows = new String[0];
            emailCsvRows.add('Enquiry number, Error text ');
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                cse = closeEnqs[i];
                // collect all record's errors
                opnCse = openEnqs.get(cse.Id);
                for (Database.Error err : result.getErrors()) {
                    emailCsvRows.add(opnCse.CaseNumber + ',' + err.getStatusCode() + ' : ' + err.getMessage());
                }
                if (!result.isSuccess()) {
                    this.hasEnqError = true;
                }
                errorCsv = String.join(emailCsvRows, '\n');// join record's errors into single string
            }
        }
        // Send out the Email 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String successLabel;
        Date endDate = Date.valueOf(closedCampaigns[0].EndDate);
        String messageBody = 'The auto-closure of Enquiries for the campaign "' + closedCampaigns[0].Name + '" that ended on "' + endDate.day() + '-' + endDate.month() + '-' + endDate.year() + '" has been completed. Errors, if any, would be listed in the CSV attached to this email. No CSV will be attached if all the Enquiries were successfully closed.';
        if (!hasEnqError) { 
            successLabel = 'Success';
        } else {
            successLabel = 'Errors';
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            csvAttachment.setFileName('Campaign Closure Results.csv');
            csvAttachment.setContentType('text/csv');
            csvAttachment.setBody(Blob.valueOf(errorCsv));
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{
                csvAttachment
            });
        }

        String subject = successLabel + ' - Enquiry auto-closure '; 

        System.debug('#! Campaign Closure \nSubject: ' + subject + '\nBody: ' + messageBody + '\n---CSV---\n' + errorCsv);

        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :String.valueOf(Label.AI_Digest_Email_Address)];

        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea[0].Id);
        mail.setSubject(subject);
        mail.setToAddresses(new String[]{closedCampaigns[0].Owner.Email});
        mail.setPlainTextBody(messageBody);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }

    /**
     * @description Batch Class finish method
     * @param info Database.BatchableContext info
     */
    public void finish(Database.BatchableContext info) {}

    /**
    * @description Implement execute method (from interface) to schedule processing.
    * @param sc SchedulableContext sc
    */
    public void execute(SchedulableContext sc) {
        AutoCloseJRGCampaignRecords batchObj = new AutoCloseJRGCampaignRecords(); 
        Database.executeBatch(batchObj,1); 
    }

    /**
     * @description Method to schedule the AutoCloseJRGCampaignRecords with a default cron timing (at 4:00 am)
     * @return String of the Schedule
     */
    public String schedule() {
        String schedule = SCHEDULE;
        return this.schedule(schedule);
    }

    /**
    * @description Method to schedule the AutoCloseJRGCampaignRecords with a set cron timing
    * @param schedule The schedule as cron String
    * @return String of the Schedule
    */
    public String schedule(String schedule) {
        AutoCloseJRGCampaignRecords myBatch = new AutoCloseJRGCampaignRecords();
        String scheduleName = String.valueOf(AutoCloseJRGCampaignRecords.class);
        // assign unique name when running in test context as it cannot have the same name of an already scheduled one
        if (Test.isRunningTest()) {
            scheduleName += System.currentTimeMillis();
        }
        String jobId = System.schedule(scheduleName, schedule, myBatch);
        return jobId;
    }
}