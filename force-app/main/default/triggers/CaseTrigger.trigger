/*
 * @description Trigger for Case Object
 * @revision
 *  DEC.04.2017     Nick Guia       - code refactor to fix too many SOQL error
 *  MAY.28.2019     Angelo Rivera   - Added after update and after insert events
 *  JUN.11.2019     Angelo Rivera   - Added LogUtilityException
 *  SEP.03.2019     Kevin Evasco (GrowthOps)   - Added PredictPropensityToTransfer to After Insert and After Update
 *  OCT.28.2019     Nick Guia       - Added ManageRelatedLead
 *  NOV.07.2019     Kevin Evasco (GrowthOps)   - Added PredictPropensityToTransfer to After Insert and After Update AFTER CODE RESTORE
 *  FEB.13.2020     APRivera        - Disabled unused logic
 *  24/02/2020      Cartick Sub     - Commented out Enquiry Age History operations which are under separate Change Data Capture framework
 *  18-05-2021      APRivera        - SA-438, Added logic for Case Skill-based routing.
 *  27-07-2021      Inderpal Dhanoa - Sync the Approver/Rejecter with Enquiry (ENGAGEIE-995)
 *  30-05-2022      Rajesh Punjabi  - Update owner id for merged cases (SS-71)
 *  05-07-2023      Nick Guia       - Added Trigger muting (v2 - interim)
 *  08-09-2023      Rajesh Punjabi  - Update Account Id for Enquiries if Contact RT=Student (AfterUpdate)
 *  11-09-2023      Rajesh Punjabi  - Remove merge case parent-child functionality for MRO RT
 *  27-09-2023      Vinothraja      - Added AssociateAgencyToAPNGEnquiries to Before Insert
 *  03-10-2023      Vinothraja      - Added CreateSummaryFileForAPNGEnquiries to After Insert
 *  14-06-2024      Mac Domingo     - Added logic for Before Delete (Before Archive)
 *  11-06-2024      Inderpal Dhanoa - Added OCR creation Logic MCT-404 <br/>
 */
trigger CaseTrigger on Case (before insert, before update, after insert, after update, before delete) {

    /**
     * trigger muting interim solution - use Casev2 instead of Case if you want
     * to consciously mute Case trigger in your context.
     * 
     * A few classes were trying to mute Case trigger while this was not implemented.
     * Adding it blindly now might have inadvertent effects and requires extensive regression testing.
     */
    if(TriggerCommon.doNotRunTrigger('Casev2')) { return; }

    new Triggers()
            //Before Insert Events
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.GenerateUuidIfMissing())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.SetEnquiryOriginCategory())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.PrepopulateCategory())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.MapCourseCode())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.MaintainLastQueueOwner())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.CheckForAndLinkToContacts())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.SetRecordTypeIdUsingCaseType())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.SetDefaultsOnNewCases())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.AssociateContactToPostApplicationEnquiries())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.AssociateAgencyToAPNGEnquiries())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.AssociateContactToMonashCollegeEnquiries())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.DefaultMonashCollegeEnquiryType())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.UpdateCaseBusinessWaitingTime())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.WebtoCaseOwnerAssignment())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.LinkCourseWhenContactLinks())
            .bindExtended(Triggers.Evnt.beforeinsert, new CaseTriggerHandlerV2.ManageRelatedLead())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapCategoryLevelsForPostApplicationCases())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapOriginToOtherValuesForPostApplicationCases())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapOriginToEnquiryTypeForMonashCollege())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.SetPriorityForInsuranceCases())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapOriginToOtherValuesForStandardCases())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapSubjectForManualUnitEnrolment())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapOriginToOtherValuesForHRCases())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.MapCourseLinkingFieldsForMonashForms())
            .bindExtended(Triggers.Evnt.beforeInsert, new CaseTriggerHandlerV2.SetDefaultsForAcademicProgressAssessment())

            //Before Update Events
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.SetEnquiryOriginCategory())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.MaintainLastQueueOwner())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.ClearAccountFieldOnContactChange())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.TransferEnquiryOwnership())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.UpdateCaseBusinessWaitingTime())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.ValidateFutureCourseEnquiriesBeforeClosing())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.LinkCourseWhenContactLinks())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.ManageRelatedLead())
            .bindExtended(Triggers.Evnt.beforeUpdate, new CaseTriggerHandlerV2.MapCategoryLevelsForPostApplicationCases())
            .bindExtended(Triggers.Evnt.beforeUpdate, new CaseTriggerHandlerV2.GenerateStudentRecruitmentTrackingDates())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.SyncApproverRejecter())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.SetLatestTransferredDate())
            .bindExtended(Triggers.Evnt.beforeupdate, new CaseTriggerHandlerV2.UpdateAccountForMROEnquiries())// Update Account Id for Enquries with ContactRT = Student

            //.bindExtended(Triggers.Evnt.beforeUpdate, new DlrsDelegateTriggerHandler(Case.SObjectType))
        
            //After Insert Events
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.CreateLinkEntitlementToCase())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.AddCourseInterests())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.syncEnquiryOrganisationAndEnquiry())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.MgeDefaultValuesIncludeAttachmentOnEmailToFaculty())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.CaseRoutingEngine())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.DoiRetainFirstOwner())
            .bindExtended(Triggers.Evnt.afterinsert, new CaseTriggerHandlerV2.CreateSummaryFileForAPNGEnquiries())

            //After Update Events
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.AutoCompleteCaseMilestone())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.syncEnquiryOrganisationAndEnquiry())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.CloneEmailAttachmentToContactDocumentUsingCases())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.CaseRoutingEngineOnUpdate())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.LinkOCRToMCEnquiry())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.CaseOwnershipUpdate())
            .bindExtended(Triggers.Evnt.afterupdate, new CaseTriggerHandlerV2.DoiRetainFirstOwner())

            // Delete
            .bindExtended(Triggers.Evnt.beforeDelete, new CaseTriggerHandlerV2.CreateArchiveAudit())

            // Undelete
            //.bindExtended(Triggers.Evnt.afterUndelete, new DlrsDelegateTriggerHandler(Case.SObjectType))

        .execute();

    LogUtilityException.getLimits();
}