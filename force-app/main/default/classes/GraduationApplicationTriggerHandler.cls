/**
 * @description Trigger handler for Graduation_Application__c
 * @group       Grads
 * @revision    2024-09-06 - Tom Gangemi - Initial version
 * @revision    2025-08-18 - Tom Gangemi - Set Unique Key when un-cancelling applications
 */
public with sharing class GraduationApplicationTriggerHandler {

    /**
     * Update Unique Key when application status goes to or from cancelled
     */
    public class HandleStatusChange extends TriggerAbstract {

        public override void process(SObject rec, SObject oldRec) {
            Graduation_Application__c app = (Graduation_Application__c) rec;
            Graduation_Application__c oldApp = (Graduation_Application__c) oldRec;

            if(app.Status__c != oldApp.Status__c && (oldApp.Status__c == 'Cancelled' || app.Status__c == 'Cancelled')) {
                // Status changed to or from cancelled
                records.add(app);
            }
        }

        public override void execute() {
            if(this.records.size() > 0) {
                Graduation_Application__c[] apps = this.records;

                Set<Id> calendarIds = new Set<Id>();

                for(Graduation_Application__c app : apps) {
                    if(app.Status__c == 'Cancelled') {
                        // Clear Unique Key when application is cancelled
                        app.Unique_Key__c = null;
                    } else {
                        // Collect calendars for setting Unique Key
                        calendarIds.add(app.Graduation_Calendar__c);
                    }
                }
                if(!calendarIds.isEmpty()) {
                    Map<Id,Calendar__c> calendars = new Map<Id,Calendar__c>([
                        SELECT Calendar_Code__c FROM Calendar__c WHERE Id IN :calendarIds
                    ]);
                    for(Graduation_Application__c app : apps) {
                        if(app.Status__c != 'Cancelled') {
                            // Set Unique Key if application is no longer cancelled
                            Calendar__c cal = calendars.get(app.Graduation_Calendar__c);
                            if(cal != null) {
                                // Set Unique Key to Calendar Code + Application ID
                                app.Unique_Key__c = GradsUtils.createApplicationUniqueKey(
                                    cal.Calendar_Code__c, app.Student_Person_Id__c
                                );
                            }
                        }
                    }
                }
            }
        }

    }

    /**
     * Set Student Testamur Name to Contact Legal Name when change is rejected
     */
    public class HandleNameChange extends TriggerAbstract {
        public override void process(SObject rec, SObject oldRec) {
            Graduation_Application__c app = (Graduation_Application__c) rec;
            Graduation_Application__c oldApp = (Graduation_Application__c) oldRec;

            if(app.Student_Testamur_Name_Change_Status__c != oldApp.Student_Testamur_Name_Change_Status__c &&
                app.Student_Testamur_Name_Change_Status__c == 'Rejected')
            {
                records.add(app);
            }
        }
        public override void execute() {
            if(this.records.size() > 0) {
                Graduation_Application__c[] apps = this.records;
                Id[] contactIds = new Id[0];
                for(Graduation_Application__c app : apps) {
                    contactIds.add(app.Student__c);
                }
                Map<Id,Contact> contacts = new Map<Id,Contact>([
                    SELECT First_Name__c, Last_Name__c FROM Contact WHERE Id IN :contactIds
                ]);
                for(Graduation_Application__c app : apps) {
                    Contact contact = contacts.get(app.Student__c);
                    app.Student_Testamur_Name__c = contact.First_Name__c + ' ' + contact.Last_Name__c;
                }
            }
        }
    }

    /**
     * Detect if a monitored field has changed and set Callista_Writeback_Requested_Time__c
     */
    public class DetectWriteBackRequired extends TriggerAbstract {

        final Set<SObjectField> monitoredFields = new Set<SObjectField> {
            Graduation_Application__c.Additional_Reqs_Graduand__c,
            Graduation_Application__c.Additional_Reqs_Description_Graduand__c,
            Graduation_Application__c.Additional_Reqs_Guest__c,
            Graduation_Application__c.Additional_Reqs_Description_Guest__c,
            Graduation_Application__c.Student_Testamur_Name__c,
            Graduation_Application__c.Student_Testamur_Name_Change_Status__c,
            Graduation_Application__c.Student_Personal_Email__c,
            Graduation_Application__c.Status__c,
            Graduation_Application__c.Document_Writeback_Pending__c,
            Graduation_Application__c.Graduation_Calendar__c,
            Graduation_Application__c.Staff_Comments__c
        };

        public override void process(SObject rec) {
            process(rec, null);
        }

        public override void process(SObject rec, SObject oldRec) {
            Graduation_Application__c app = (Graduation_Application__c) rec;
            Graduation_Application__c oldApp = (Graduation_Application__c) oldRec;

            if(GradsUtils.getSyncConfig().triggerEnabled != true) {
                return;
            }

            if(app.Status__c != 'Applied' && app.Status__c != 'Cancelled') {
                return;
            }

            // Detect if record is new or any monitored fields have changed
            if(oldApp == null) {
                records.add(app);
                return;
            } else {
                for(SObjectField field : monitoredFields) {
                    if(app.get(field) != oldApp.get(field)) {
                        if(field == Graduation_Application__c.Student_Testamur_Name_Change_Status__c) {
                            // Name Change Status only considered if approved or rejected
                            String ncStatus = app.Student_Testamur_Name_Change_Status__c;
                            if(ncStatus != 'Approved' && ncStatus != 'Rejected') {
                                continue;
                            }
                        }
                        if(field == Graduation_Application__c.Document_Writeback_Pending__c) {
                            // Document Writeback Pending only considered if true
                            if(!app.Document_Writeback_Pending__c) {
                                continue;
                            }
                        }

                        records.add(app);

                        return;
                    }
                }
            }
        }

        public Boolean awardIsCancelled(Graduation_Award__c award) {
            return award.Cancellation_Date__c != null && award.Cancellation_Succeeded__c;
        }

        public override void execute() {
            if(this.records.size() > 0) {
                Graduation_Application__c[] apps = this.records;

                Graduation_Award__c[] childAwards = [
                    SELECT Cancellation_Date__c, Cancellation_Succeeded__c FROM Graduation_Award__c
                    WHERE Graduation_Application__c IN :apps AND Bypass_Writeback_Trigger__c = FALSE AND
                        (Cancellation_Date__c = NULL OR Cancellation_Succeeded__c = FALSE) // Don't writeback of already cancelled awards
                ];

                for(Graduation_Award__c award : childAwards) {
                    if(!awardIsCancelled(award)) {
                        award.Callista_Writeback_Requested_Time__c = Datetime.now();
                    }
                }
                update childAwards;
            }
            Nebula.Logger.saveLog(); // Save any debug logs
        }
    }
}