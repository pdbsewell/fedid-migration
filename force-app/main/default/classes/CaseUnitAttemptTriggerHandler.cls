/**
 * @author          Tom Gangemi
 * @revision        2022-09-21 - Tom Gangemi - Initial version
 * @description    	Handler for Case_Unit_Attempt__c object
 */

public with sharing class CaseUnitAttemptTriggerHandler {

    /**
     * If SpecCon CUA has it's Status changed, reset the Emails_Sent__c and Moodle/Callista_Integration_Status__c fields
     * This is to re-enable the Update Moodle/Callista and Send Email buttons.
     * SA-2640 - If status is changed to 'Declined' then clear Assessment_Due_Date_New__c
     */
    public class SpecConOnStatusChange extends TriggerAbstract {

            final Case_Unit_Attempt__c[] declinedCuas = new Case_Unit_Attempt__c[0];

            public override void process(SObject rec, SObject oldRec) {
                Case_Unit_Attempt__c cua = (Case_Unit_Attempt__c)rec;
                Case_Unit_Attempt__c oldCua = (Case_Unit_Attempt__c)oldRec;
                if((cua.RecordTypeId == SpecConServices.CUA_EXAM_RT_ID || cua.RecordTypeId == SpecConServices.CUA_RT_ID) &&
                    cua.Status__c != oldCua.Status__c)
                {
                    if(String.isNotBlank(oldCua.Status__c)) {
                        records.add(rec);
                    }
                    if(cua.Status__c == 'Declined') {
                        declinedCuas.add(cua);
                    }
                }
            }

            public override void execute() {
                for(Case_Unit_Attempt__c cua :(Case_Unit_Attempt__c[])records) {
                    cua.Emails_Sent__c = null;
                    if(cua.RecordTypeId == SpecConServices.CUA_EXAM_RT_ID) {
                        cua.Callista_Integration_Status__c = null;
                    }
                    if(cua.RecordTypeId == SpecConServices.CUA_RT_ID) {
                        cua.Moodle_Integration_Status__c = null;
                    }
                }
                for(Case_Unit_Attempt__c cua :declinedCuas) {
                    cua.Assessment_Due_Date_New__c = null;
                }
            }
    }

    /**
     * Copy Case_Unit_Attempt__c.Status__c to Case.Case_Outcome__c.
     * If Case_Unit_Attempt__c.Status__c is "Eligible" then clear Case.Case_Outcome__c
     */
    public class SpecConUpdateCaseOutcome extends TriggerAbstract {

        public override void process(SObject rec, SObject oldRec) {
            Case_Unit_Attempt__c cua = (Case_Unit_Attempt__c)rec;
            Case_Unit_Attempt__c oldCua = (Case_Unit_Attempt__c)oldRec;
            if((cua.RecordTypeId == SpecConServices.CUA_RT_ID || cua.RecordTypeId == SpecConServices.CUA_EXAM_RT_ID)
                && cua.Status__c != oldCua.Status__c)
            {
                records.add(rec);
            }
        }

        public override void execute() {
            if (records.isEmpty()) {
                return;
            }
            Map<Id,String> caseOutcomesByCaseId = new Map<Id,String>();
            for(Case_Unit_Attempt__c cua : (Case_Unit_Attempt__c[])records) {
                caseOutcomesByCaseId.put(cua.Enquiry__c, cua.Status__c == 'Eligible' ? null : cua.Status__c);
            }
            Case[] cases = [
                SELECT Id FROM Case
                WHERE Id IN :caseOutcomesByCaseId.keySet() AND RecordType.DeveloperName = 'Special_Consideration' AND
                    Origin IN ('Web - Monash Forms', 'SEBS') AND
                    Enquiry_Type__c IN ('Special Consideration', 'Special Consideration - Exams')
            ];
            for(Case c :cases) {
                c.Case_Outcome__c = caseOutcomesByCaseId.get(c.Id);
            }
            update cases;
        }
    }

    /**
     * Mark any existing Spec Con requests for a given Moodle Assessment Id as "withdrawn"
     * SA-2252
     */
    public class SpecConUpdateExistingCUAs extends TriggerAbstract {

            public override void process(SObject rec) {
                Case_Unit_Attempt__c cua = (Case_Unit_Attempt__c)rec;
                if(cua.RecordTypeId == SpecConServices.CUA_RT_ID && String.isNotBlank(cua.Moodle_Assessment_ID__c)) {
                    records.add(rec);
                }
            }

            public override void execute() {
                if(records.isEmpty()) {
                    return;
                }

                Case_Unit_Attempt__c[] newCuas = (Case_Unit_Attempt__c[]) records;

                Set<String> moodleIds = new Set<String>();
                Map<Id, Set<String>> moodleIdsByContactId = new Map<Id, Set<String>>();
                for(Case_Unit_Attempt__c cua :newCuas) {
                    moodleIds.add(cua.Moodle_Assessment_ID__c);
                    if(String.isNotBlank(cua.Contact_ID__c)) {
                        Set<String> pMoodleIds = moodleIdsByContactId.get(cua.Contact_ID__c);
                        if(pMoodleIds == null) {
                            moodleIdsByContactId.put(cua.Contact_ID__c, new Set<String>{cua.Moodle_Assessment_ID__c});
                        } else {
                            pMoodleIds.add(cua.Moodle_Assessment_ID__c);
                        }
                    }
                }
                Case_Unit_Attempt__c[] relatedCuas = [
                    SELECT Id, Enquiry__c, Enquiry__r.ContactId, Moodle_Assessment_ID__c FROM Case_Unit_Attempt__c
                    WHERE RecordTypeId = :SpecConServices.CUA_RT_ID AND Enquiry__r.ContactId IN :moodleIdsByContactId.keySet() AND
                    (Status__c = NULL OR Status__c = 'Eligible') AND Enquiry__r.Enquiry_Type__c = 'Special Consideration'
                ];
                Map<Id,Case> enquiries = new Map<Id,Case>();
                Case_Unit_Attempt__c[] cuasToUpdate = new Case_Unit_Attempt__c[0];
                for(Case_Unit_Attempt__c cua :relatedCuas) {
                    Set<String> pMoodleIds = moodleIdsByContactId.get(cua.Enquiry__r.ContactId);
                    if(pMoodleIds != null && pMoodleIds.contains(cua.Moodle_Assessment_ID__c)) {
                        cua.Status__c = 'Withdrawn';
                        Case enquiry = new Case(Id=cua.Enquiry__c, Status='Solved', Case_Outcome__c='Withdrawn');
                        enquiries.put(enquiry.Id, enquiry);
                        cuasToUpdate.add(cua);
                    }
                }
                Triggers.bypass('SpecConUpdateCaseOutcome');
                update cuasToUpdate;
                Triggers.clearBypass('SpecConUpdateCaseOutcome');
                update enquiries.values();
            }

    }

    /**
     * Send auto approval SpecCon emails
     */
    public class SendSpecConAutoApprovalEmail extends TriggerAbstract {

        public override void process(SObject rec, SObject oldRec) {
            Case_Unit_Attempt__c cua = (Case_Unit_Attempt__c)rec;
            Case_Unit_Attempt__c oldCua = (Case_Unit_Attempt__c)oldRec;

            if(cua.RecordTypeId == SpecConServices.CUA_RT_ID && !oldCua.Is_Closed_On_Create__c && cua.Is_Closed_On_Create__c) {
                if(cua.Status__c != null && cua.Status__c.startsWithIgnoreCase('Approved')) {
                    // auto approved CUA has marked as is closed on create
                    records.add(cua);
                }
            }
        }

        public override void execute() {
            Case_Unit_Attempt__c[] cuas = (Case_Unit_Attempt__c[])records;
            if(!records.isEmpty()) {
                SpecConServices.sendApprovalEmails(cuas, null, false);
                for(Case_Unit_Attempt__c cua :cuas) {
                    SpecConServices.setEmailSent(cua, SpecConServices.EMAIL_TYPE_APPROVED);
                }
            }
        }
    }

}