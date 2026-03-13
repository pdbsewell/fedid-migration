/**
 * @author      Tom Gangemi
 * @date        2023-06-09
 * @testclass   EmailDigestUtilities_Test
 * @group       Utilities
 * @description Common utilities for creating and managing digest emails
 **/
public with sharing class EmailDigestUtilities {

    // Mailer interface so that email sending can be mocked/validated in unit tests
    public interface Mailer {
        List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> emailMessages);
    }

    public class LiveMailer implements Mailer {
        public List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> emailMessages) {
            return Messaging.sendEmail(emailMessages);
        }
    }

    public class MockMailer implements Mailer {
        public List<Messaging.SingleEmailMessage> sentEmails = new List<Messaging.SingleEmailMessage>();
        public Integer invokeCounter = 0;
        public List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> emailMessages) {
            invokeCounter++;
            sentEmails.addAll(emailMessages);
            return Messaging.sendEmail(emailMessages);
        }
    }

    /**
     * Data class containing info for creating a single digest email
     */
    public class Digest {
        public Id userId; // The Id of the user receiving the email
        public User user; // The user receiving the email
        public Map<Id, Case> casesById; // The enquiries in the email
        public Map<Id, Datetime> previouslySentTimeById; // The last time each enquiry was sent in a digest email
        public Digest(User user, List<Case> cases) {
            this(user.Id, cases);
            this.user = user;
        }
        public Digest(Id userId, List<Case> cases) {
            this.userId = userId;
            this.casesById = new Map<Id, Case>(cases);
            this.previouslySentTimeById = new Map<Id, Datetime>();
        }
    }

    /**
     * Returns a shortened (12 character) Id that is only unique to the local sobject
     */
    private static String getLocalId(Id original) {
        return String.valueOf(original).substring(6);
    }

    /**
     * Creates a unique key to be used for Apex_Job_Tracking__c.Name
     *
     * Custom Settings Name fields are limited to 38 chars - use shortened ids and prefix no longer than 13 charts
     */
    public static String createTrackingKey(String keyPrefix, Id userId, Id caseId) {
        return keyPrefix + '.' + getLocalId(userId) + '.' + getLocalId(caseId);
    }

    /**
     * Log cases that have been sent in a digest email (logging is per recipient)
     */
    public static void markAsSent(String keyPrefix, List<Digest> digests) {
        Apex_Job_Tracking__c[] tracking = new Apex_Job_Tracking__c[0];
        for(Digest di :digests) {
            for(Case c : di.casesById.values()) {
                Apex_Job_Tracking__c ajt = new Apex_Job_Tracking__c();
                // Use local ids to fit the unique name into the 38 character limit
                ajt.Name = createTrackingKey(keyPrefix, di.userId, c.Id);
                ajt.Value_1__c = di.userId;
                ajt.Value_2__c = c.Id;
                tracking.add(ajt);
            }
        }
        insert tracking;
    }

    /**
     * Check if cases have been sent in a digest email
     */
    public static void filterPreviouslySent(String keyPrefix, Map<Id, Digest> digestsByUserId, Boolean removePreviouslySent) {
        for(Apex_Job_Tracking__c ajt :Apex_Job_Tracking__c.getAll().values()) {
            if(ajt.Name.startsWith(keyPrefix + '.') && ajt.Value_1__c != null && ajt.Value_2__c != null) {
                // Entry is a relevant tracking entry
                Id userId = Id.valueOf(ajt.Value_1__c);
                Id caseId = Id.valueOf(ajt.Value_2__c);
                Digest di = digestsByUserId.get(userId);
                if(di != null) {
                    if(removePreviouslySent) {
                        di.casesById.remove(caseId);
                        if(di.casesById.isEmpty()) {
                            // Remove digests that no longer have any cases
                            digestsByUserId.remove(userId);
                        }
                    } else {
                        // Instead of removing from digest, keep track of the last time each case was sent in a digest email
                        di.previouslySentTimeById.put(caseId, ajt.CreatedDate);
                    }
                }
            }
        }
    }

    /**
     * Delete old digest tracking entries
     * @param keyPrefix The prefix of the tracking keys to delete
     * @param ageInDays The number of days old the entries must be to be deleted
     */
    public static void removeOldDigestTracking(String keyPrefix, Integer ageInDays) {
        Datetime cutoff = Datetime.now().addDays(-ageInDays);
        delete [
            SELECT Id FROM Apex_Job_Tracking__c
            WHERE CreatedDate < :cutoff AND Name LIKE :keyPrefix + '.%'
        ];
    }

    /**
     * @param sourceType Exception_Log__c.Source_Type__c - Highest level of categorisation for exception records
     * @param functionName Exception_Log__c.Function_Name__c - The name of the function that threw the exception
     * @param shortLog Exception_Log__c.Input__c - A short version of the log
     * @param longLog This will be saved as a text file and linked to the exception record
     */
    public static void insertLog(String sourceType, String functionName, String shortLog, String longLog) {
        Exception_Log__c exLog = new Exception_Log__c();
        exLog.Source_Type__c = sourceType;
        exLog.Function_Name__c = functionName;
        exLog.Input__c = shortLog;
        exLog.CurrentUser__c = UserInfo.getUserId();
        insert exLog;

        if(longLog != null) {
            String fileName = sourceType + ' ' + Datetime.now().format('yyyy-MM-dd HH:mm') + '.txt';
            insertLogFile(exLog.Id, fileName, longLog);
        }
    }

    private static void insertLogFile(Id logRecordId, String fileName, String body) {
        // Create the file
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = Blob.valueOf(body);
        insert cv;

        // Retrieve the ContentDocumentId
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Link to the Log Record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = logRecordId; // Link to the record
        cdl.ShareType = 'I'; // Inferred permission - Access leve is determined by related record
        cdl.Visibility = 'InternalUsers';
        insert cdl;
    }
}