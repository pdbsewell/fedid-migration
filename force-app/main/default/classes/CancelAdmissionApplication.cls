/***********************************************************************
** Author: Majid Reisi Dehkordi
** Created Date: 10.Jan.2019
** Description: This class is for deletion of apps, acps and other contact children
                Suman Gunaganti(2019-07-05): (SF-2781) Removed Application Document provided object reference
** Version history
** 05.07.2021 SFTG-1841 Converted Lists into Sets to avoid duplicate IDs during delete
***********************************************************************/
public with sharing class CancelAdmissionApplication {
    @InvocableMethod
    public static void cancelApplication(List<Id> applicationIds) {
        /* This part of code is commentted out as it is not used right now
         * If the deletion of cancelled application is dependant on other
         * applicant's applications, use the following piece of code
         * 
        List<Application__c> unrefinedApplications = [SELECT id, applicant__c from application__c WHERE id IN: applicationIds];
        System.debug('unrefinedApplications: ' + unrefinedApplications);
        System.debug(unrefinedApplications.size());
        
        Map<Id, Id> appToContactMap = new Map<Id, Id>();
        for(Application__c appVar : unrefinedApplications)
        {
             appToContactMap.put(appVar.id, appVar.applicant__c);
        }
        
        List<Id> unrefinedContactIds = appToContactMap.values();
        System.debug('unrefinedContactIds: ' + unrefinedContactIds);
        System.debug(unrefinedContactIds.size());
        
        List<Application__c> submittedApplicationsOfUnrefinedContacts = [select id, applicant__c from Application__c where applicant__c IN: appToContactMap.values() AND (status__c = 'Submitted' OR status__c = 'Sent for Submission' OR Submitted_Date__c != null) ORDER BY id desc];
        System.debug('notDraftApplicationsOfUnrefinedContacts: ' +  submittedApplicationsOfUnrefinedContacts);
        System.debug(submittedApplicationsOfUnrefinedContacts.size());
        
        Map<Id, Id> appToContactMap2 = new Map<Id, Id>();
        for(Application__c appVar2 : submittedApplicationsOfUnrefinedContacts)
        {
             appToContactMap2.put(appVar2.id, appVar2.applicant__c);
        }
        
        List<Id> notAimedContactIds = new List<Id>();
        for(Id idVar :appToContactMap2.values())
        {
             notAimedContactIds.add(idVar);
        }
        System.debug('notAimedContactIds: ' + notAimedContactIds);
        System.debug(notAimedContactIds.size());
        
        List<Id> aimedContactIds = new List<Id>();
        for(Id contactIdVar : unrefinedContactIds)
        {
            if(!notAimedContactIds.contains(contactIdVar))
            {
                aimedContactIds.add(contactIdVar);
            }
        }
        System.debug('aimedContactIds: ' + aimedContactIds);
        System.debug(aimedContactIds.size());
        */
        List<Application__c> cancelledApplications = [select id from application__c where status__c = 'Cancelled' AND Submitted_Date__c = null AND id IN :applicationIds ORDER BY lastModifiedDate];
        System.debug('cancelledApplications: ' + cancelledApplications);
        System.debug(cancelledApplications.size());
        
        List<Application_Course_Preference__c> cancelledAcps = [select id, status__c from Application_Course_Preference__c where Application__c IN: cancelledApplications];
        System.debug('cancelledAcps: ' + cancelledAcps);
        System.debug(cancelledAcps.size());
        
        /*List<Application_Document_Provided__c>  aDPsToBeDeleted = [select id from Application_Document_Provided__c where Application__c IN: cancelledApplications];
        System.debug('aDPsToBeDeleted: ' + aDPsToBeDeleted);
        System.debug(aDPsToBeDeleted.size());*/
        
        List<Application_Qualification_Provided__c>  aQPsToBeDeleted = [select id, Contact_Qualification__c from Application_Qualification_Provided__c where Application__c IN: cancelledApplications];
        System.debug('aQPsToBeDeleted: ' + aQPsToBeDeleted);
        System.debug(aQPsToBeDeleted.size());
        
        Set<Id> conQualToBeDeletedIDs = new Set<Id> ();
        for(Application_Qualification_Provided__c aQPVar :aQPsToBeDeleted)
        {
             conQualToBeDeletedIDs.add(aQPVar.Contact_Qualification__c);
        }
        System.debug('conQualToBeDeletedIDs: ' + conQualToBeDeletedIDs);
        System.debug(conQualToBeDeletedIDs.size());
                
        List<Application_Work_Experience_Provided__c>  aWPsToBeDeleted = [select id, Work_Experience__c from Application_Work_Experience_Provided__c where Application__c IN: cancelledApplications AND Work_Experience__r.Reference_Count__c = 1];
        System.debug('aWPsToBeDeleted: ' + aWPsToBeDeleted);
        System.debug(aWPsToBeDeleted.size());
        
        Set<Id> workExpToBeDeletedIDs = new Set<Id> ();
        for(Application_Work_Experience_Provided__c aWEVar :aWPsToBeDeleted)
        {
             workExpToBeDeletedIDs.add(aWEVar.Work_Experience__c);
        }
        System.debug('workExpToBeDeletedIDs: ' + workExpToBeDeletedIDs);
        System.debug(workExpToBeDeletedIDs.size());
        
        Set<Id> filesToBeDeletedIds = new Set<Id>();
        Set<Id> contactDocumentsToBeDeletedIds = new Set<Id>();
        List<Id> cancelledAppIds = new List<Id>(new Map<Id, Application__c> (cancelledApplications).KeySet());
        if(cancelledAppIds != null && cancelledAppIds.size() != 0)
        {
            List<ContentDocumentLink> cDLs = [select ContentDocumentId from ContentDocumentLink where LinkedEntityId IN :cancelledAppIds];
            System.debug('cDLs: ' + cDLs);
            System.debug(cDLs.size());
            
            if(cDLs != null && cDLs.size() != 0)
            {
                for(ContentDocumentLink cDLVar: cDLs)
                {
                    filesToBeDeletedIds.add(cDLVar.ContentDocumentId);
                }
                System.debug('filesToBeDeletedIds: ' + filesToBeDeletedIds);
                System.debug(filesToBeDeletedIds.size());
                
                if(filesToBeDeletedIds != null && filesToBeDeletedIds.size() != 0)
                {
                    List<ContentDocumentLink> cDLsOfAllFiles = [select id, LinkedEntityId from ContentDocumentLink where ContentDocumentId IN :filesToBeDeletedIds];
                    System.debug('cDLsOfAllFiles: ' + cDLsOfAllFiles);
                    System.debug(cDLsOfAllFiles.size());
                    
                    if(cDLsOfAllFiles != null && cDLsOfAllFiles.size() != 0)
                    {       
                        for(ContentDocumentLink cDLVar: cDLsOfAllFiles)
                        {
                            if(String.valueof(cDLVar.LinkedEntityId).startsWith('a29'))
                                contactDocumentsToBeDeletedIds.add(cDLVar.LinkedEntityId);
                        }
                        System.debug('contactDocumentsToBeDeletedIds: ' + contactDocumentsToBeDeletedIds);
                        System.debug(contactDocumentsToBeDeletedIds.size());
                    }
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try
        {
            
            if(conQualToBeDeletedIDs != null && conQualToBeDeletedIDs.size() != 0)
            {
                Database.delete(new List<Id>(conQualToBeDeletedIDs), true);
            }
            if(workExpToBeDeletedIDs != null && workExpToBeDeletedIDs.size() != 0)
            {
                Database.delete(new List<Id>(workExpToBeDeletedIDs), true);
            }
            if(filesToBeDeletedIds != null && filesToBeDeletedIds.size() != 0)
            {
                Database.delete(new List<Id>(filesToBeDeletedIds), true);
            }
            if(contactDocumentsToBeDeletedIds != null && contactDocumentsToBeDeletedIds.size() != 0)
            {
                Database.delete(new List<Id>(contactDocumentsToBeDeletedIds), true);
            }
            if(cancelledACPs != null && cancelledACPs.size() != 0)
            {
                Delete cancelledACPs;
            }
            if(cancelledApplications != null && cancelledApplications.size() != 0)
            {
                Delete cancelledApplications;
            }
            
        } catch (DmlException e) 
        {
            System.debug('---------------------------------------------------------');
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('---------------------------------------------------------');
            Database.rollback(sp);
        }
    }
}