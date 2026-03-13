/**
 * @author          Kristian Vegerano
 * @description     Apex controller class for actions required on DocumentViewer aura component
 * @group           Controllers
 * @history         24/07/2018
 * @revision
 * 24.Jul.2018 Kristian Vegerano - Created
 * 16.Apr.2024 Inderpal Dhanoa - SMSTA-57 Document Checklist for Qualification assessments
 * 04.OCT.2024 Kai-Fan Hsieh - DANO-330 Display issuer doc type and verified flag
 * 06.JAN.2025 Martin C - Moved logging to debug logging level 
 */
public with sharing class DocumentViewerService {

    @AuraEnabled
    public static Document_Checklist_Settings__c retrieveDocumentChecklistSettings() {
        Document_Checklist_Settings__c dcls = Document_Checklist_Settings__c.getInstance();
            
        Nebula.Logger.debug(json.serializePretty(dcls));
        Nebula.Logger.saveLog();
        return dcls;
    }

    @AuraEnabled
    public static Map<String, Object> retrieveContentDocumentData(String contactDocumentId) {
        //Initialize results map
        Map<String, Object> resultMap = new Map<String, Object>();

        //Retrieve contact document details
        Contact_Document__c contactDocumentRecord = [
            SELECT Id, Filename__c, Application__c, Application__r.Applicant__c,
                Opportunity__c, Opportunity__r.PrimaryContact__c,
                Document_Checklist__c, Contact_Qualification__c, Work_Experience__c
            FROM Contact_Document__c
            WHERE Id = :contactDocumentId
            LIMIT 1
        ];
        resultMap.put('ContactDocument', contactDocumentRecord);

        //Get file name without the extension
        if (contactDocumentRecord.Filename__c != null) {
            List<String> fileNameComponents = contactDocumentRecord.Filename__c.split('\\.');
            resultMap.put('DocumentName', fileNameComponents[0]);
        }

        //Retrieve document type map
        Map<String, String> documentTypeMap = new Map<String, String>();
        for (Schema.PicklistEntry loopField : Document_Checklist_Rule_Document_Type__mdt.Allowed_Document_Types__c.getDescribe().getPicklistValues()) {
            documentTypeMap.put(loopField.getValue(), loopField.getLabel());
        }

        //Retrieve non-cancelled application checklists
        Map<Id, String> checklistMap = new Map<Id, String>();
        Map<String, Map<String, String>> checklistDocumentTypeMap = new Map<String, Map<String, String>>();
        for (Document_Checklist__c loopChecklist : [
            SELECT Id, Checklist_Requirement__c, Rule_DeveloperName__c, Allowed_Document_Type__c
            FROM Document_Checklist__c
            WHERE (Application__c = :contactDocumentRecord.Application__c AND Opportunity__c = :contactDocumentRecord.Opportunity__c)
            AND Status__c != 'AutoCancelled'
            AND Status__c != 'ManualCancelled'
            ORDER BY Sort_Order__c ASC, CreatedDate ASC
            LIMIT 100
        ]) {
            checklistMap.put(loopChecklist.Id, loopChecklist.Checklist_Requirement__c);
            //Add checklist key
            if (loopChecklist.Allowed_Document_Type__c != null) {
                for (String loopDocumentType : loopChecklist.Allowed_Document_Type__c.split(';')) {
                    //add key
                    if (!checklistDocumentTypeMap.containsKey(loopChecklist.Id)) {
                        checklistDocumentTypeMap.put(loopChecklist.Id, new Map<String, String>());
                    }
                    //add value
                    if (documentTypeMap.containsKey(loopDocumentType)) {
                        if (loopChecklist.Rule_DeveloperName__c != null && loopChecklist.Rule_DeveloperName__c.containsIgnoreCase('visa_check')) {
                            checklistDocumentTypeMap.get(loopChecklist.Id).put(loopDocumentType, 'Personal: Supplementary VISA documentation');
                        } else {
                            checklistDocumentTypeMap.get(loopChecklist.Id).put(loopDocumentType, documentTypeMap.get(loopDocumentType));
                        }
                    }
                }
            }
        }
        resultMap.put('ChecklistMap', checklistMap);
        resultMap.put('ChecklistDocumentTypeMap', checklistDocumentTypeMap);

        //Retrieve link details
        ContentDocumentLink contentLinkRecord = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :contactDocumentRecord.Id];

        //Retrieve content document details
        ContentDocument contentDocumentRecord = [
            SELECT Id, FileExtension, LatestPublishedVersionId, LatestPublishedVersion.VersionData
            FROM ContentDocument
            WHERE Id = :contentLinkRecord.ContentDocumentId
            LIMIT 1
        ];

        //Set file extension
        String fileExtension = contentDocumentRecord.FileExtension;
        switch on fileExtension {
            when 'pdf' {
                resultMap.put('ContentLink', '/resource/AssessmentDocumentViewerJS/web/viewer.html');
                resultMap.put('ContentDocumentBody', EncodingUtil.base64Encode(contentDocumentRecord.LatestPublishedVersion.VersionData));
            }
            when 'jpg' {
                resultMap.put('ContentLink', '/resource/AssessmentDocumentViewerJS/web/viewer.html');
                resultMap.put('ContentDocumentBody', EncodingUtil.base64Encode(contentDocumentRecord.LatestPublishedVersion.VersionData));
            }
            when 'html' {
                resultMap.put('ContentLink', '/resource/AssessmentDocumentViewerJS/web/viewer.html');
                resultMap.put('ContentDocumentBody', EncodingUtil.base64Encode(contentDocumentRecord.LatestPublishedVersion.VersionData));
            }
            when else {
                //Retrieve content distribution
                ContentDistribution contentLink = DocumentViewerService.retrieveActiveContentDistribution(contentDocumentRecord.LatestPublishedVersionId,
                    contactDocumentRecord,
                    contentDocumentRecord);
                resultMap.put('ContentLink', contentLink.DistributionPublicUrl);
                resultMap.put('ContentDocumentBody', EncodingUtil.base64Encode(contentDocumentRecord.LatestPublishedVersion.VersionData));
            }
        }
        resultMap.put('FileExtension', fileExtension);

        //Return result map
        return resultMap;
    }

    @AuraEnabled
    public static Map<String, Object> retrieveChecklistData(String documentChecklistId, Id relatedId) {
        //Initialize results map
        Map<String, Object> resultMap = new Map<String, Object>();

        //Retrieve correct checklist if possible
        if (documentChecklistId != 'undefined') {
            //Retrieve specified document checklist
            Document_Checklist__c documentChecklistRecord = [
                SELECT Id, Application__c, Application__r.Applicant__c
                FROM Document_Checklist__c
                WHERE Id = :documentChecklistId
                LIMIT 1
            ];
            resultMap.put('DocumentChecklist', documentChecklistRecord);
        }

        //Retrieve document type map
        Map<String, String> documentTypeMap = new Map<String, String>();
        for (Schema.PicklistEntry loopField : Document_Checklist_Rule_Document_Type__mdt.Allowed_Document_Types__c.getDescribe().getPicklistValues()) {
            documentTypeMap.put(loopField.getValue(), loopField.getLabel());
        }

        //Logic when the parent record is an application
        if (relatedId.getSobjectType() == Schema.Application__c.getSObjectType()) {
            Application__c applicationRecord = [SELECT Id, Applicant__c FROM Application__c WHERE Id = :relatedId LIMIT 1];
            resultMap.put('Applicant', applicationRecord.Applicant__c);
        }
        //Logic when the parent record is a quote
        else if (relatedId.getSobjectType() == Schema.SBQQ__Quote__c.getSObjectType()) {
            SBQQ__Quote__c quoteRecord = [SELECT Id, SBQQ__PrimaryContact__c FROM SBQQ__Quote__c WHERE Id = :relatedId LIMIT 1];
            resultMap.put('Applicant', quoteRecord.SBQQ__PrimaryContact__c);
        }

        //Retrieve non-cancelled application checklists
        Map<Id, String> checklistMap = new Map<Id, String>();
        Map<String, Map<String, String>> checklistDocumentTypeMap = new Map<String, Map<String, String>>();
        for (Document_Checklist__c loopChecklist : [
            SELECT Id, Checklist_Requirement__c, Rule_DeveloperName__c, Allowed_Document_Type__c
            FROM Document_Checklist__c
            WHERE (Application__c = :relatedId OR Opportunity__c = :relatedId)
            AND Status__c != 'AutoCancelled'
            AND Status__c != 'ManualCancelled'
            ORDER BY Sort_Order__c ASC, CreatedDate ASC
            LIMIT 100
        ]) {
            checklistMap.put(loopChecklist.Id, loopChecklist.Checklist_Requirement__c);
            //Add checklist key
            if (loopChecklist.Allowed_Document_Type__c != null) {
                for (String loopDocumentType : loopChecklist.Allowed_Document_Type__c.split(';')) {
                    //add key
                    if (!checklistDocumentTypeMap.containsKey(loopChecklist.Id)) {
                        checklistDocumentTypeMap.put(loopChecklist.Id, new Map<String, String>());
                    }
                    //add value
                    if (documentTypeMap.containsKey(loopDocumentType)) {
                        if (loopChecklist.Rule_DeveloperName__c != null && loopChecklist.Rule_DeveloperName__c.containsIgnoreCase('visa_check')) {
                            checklistDocumentTypeMap.get(loopChecklist.Id).put(loopDocumentType, 'Personal: Supplementary VISA documentation');
                        } else {
                            checklistDocumentTypeMap.get(loopChecklist.Id).put(loopDocumentType, documentTypeMap.get(loopDocumentType));
                        }
                    }
                }
            }
        }

        resultMap.put('ChecklistMap', checklistMap);
        resultMap.put('ChecklistDocumentTypeMap', checklistDocumentTypeMap);

        //Return result map
        return resultMap;
    }

    /**
     * @author      Kristian Vegerano
     * @date        05/08/2019
     * @description Returns the relevant content distribution record of the content version
     */
    public static ContentDistribution retrieveActiveContentDistribution(Id contentVersionId, Contact_Document__c relatedContactDocument, ContentDocument relatedContentDocument) {
        //Retrieve content distribution
        ContentDistribution contentLink;
        for (ContentDistribution loopDistribution : [
            SELECT Id, DistributionPublicUrl, ExpiryDate, PreferencesExpires
            FROM ContentDistribution
            WHERE ContentVersionId = :contentVersionId
            AND CreatedById = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ]) {
            contentLink = loopDistribution;
        }

        //Create contentdistribution if doesnt exist
        if (contentLink == null) {
            contentLink = new ContentDistribution(Name = relatedContactDocument.Filename__c,
                ContentVersionId = relatedContentDocument.LatestPublishedVersionId,
                PreferencesAllowViewInBrowser = true,
                PreferencesLinkLatestVersion = true,
                PreferencesNotifyOnVisit = false,
                PreferencesPasswordRequired = false,
                PreferencesAllowOriginalDownload = false,
                PreferencesAllowPDFDownload = false,
                PreferencesExpires = true,
                ExpiryDate = System.NOW().addDays(1));
            insert contentLink;

            //Query url
            for (ContentDistribution loopDistribution : [
                SELECT Id, DistributionPublicUrl, ExpiryDate, PreferencesExpires
                FROM ContentDistribution
                WHERE ContentVersionId = :contentVersionId
                AND CreatedById = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]) {
                contentLink = loopDistribution;
            }
        }

        //Extend expiry if already expired
        if (contentLink.ExpiryDate < System.now()) {
            contentLink.ExpiryDate = System.now().addDays(1);
            update contentLink;
        }

        return contentLink;
    }

    /**
     * @author      Kristian Vegerano
     * @description Returns the ContentDocument records related to the checklist via ContentDocumentLink
     * @param       String checklistItemId
     * @return      Object
     * @revision    10/06/2019 - Kristian Vegerano - Created
     */
    @AuraEnabled
    public static Object retrieveChecklistDetails(String checklistItemId, String applicantId, String applicationId, String opportunityId, String selectedContactDocumentId) {
        Map<String, Object> resultMap = new Map<String, Object>();

        try {
            //Initialize Variables
            List<DocumentChecklistAssessmentServices.ChecklistNote> notesList = new List<DocumentChecklistAssessmentServices.ChecklistNote>();
            List<DocumentChecklistAssessmentServices.ChecklistDocument> checklistDocumentItemList = new List<DocumentChecklistAssessmentServices.ChecklistDocument>();
            Map<Id, Contact_Document__c> contentToContactDocumentMap = new Map<Id, Contact_Document__c>();
            Map<String, String> contextDocumentChecklist = new Map<String, String>();

            //Retrieve checklist header details
            if (checklistItemId == 'Other' || checklistItemId == 'undefined') {
                checklistItemId = null;
            }
            //Set header
            if (checklistItemId != null) {
                contextDocumentChecklist.put('ChecklistName', [SELECT Id, Checklist_Requirement__c FROM Document_Checklist__c WHERE Id = :checklistItemId].Checklist_Requirement__c);
            } else {
                contextDocumentChecklist.put('ChecklistName', 'Other');
            }

            //Retrieve application details
            if (applicationId != null) {
                Application__c contextApplication = [
                    SELECT Id, Name, Applicant__c, Applicant__r.Name
                    FROM Application__c
                    WHERE Id = :applicationId
                    LIMIT 1
                ];
                contextDocumentChecklist.put('ApplicationName', contextApplication.Name);
                contextDocumentChecklist.put('ApplicantName', contextApplication.Applicant__r.Name);
            } else if (opportunityId != null) {
                Opportunity contextOpportunity = [
                    SELECT Id, PrimaryContact__c, PrimaryContact__r.Name, Name
                    FROM Opportunity
                    WHERE Id = :opportunityId
                    LIMIT 1
                ];
                contextDocumentChecklist.put('ApplicationName', contextOpportunity.Name);
                contextDocumentChecklist.put('ApplicantName', contextOpportunity.PrimaryContact__r.Name);
            }
            resultMap.put('checklist', contextDocumentChecklist);

            //Retrieve documents
            //Collect contact document ids related to the checklist  
            if (applicationId != null) {
                for (Contact_Document__c loopContactDocument : [
                    SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c,
                        Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Opportunity__c,
                        Internal_Only__c, Comments__c, Document_Assessment_Status__c, Document_Status__c,
                        Application__c, Application__r.Applicant__c, Contact_Qualification__c, Work_Experience__c, Contact__c,
                        Issuer_Document_Type__c, Verified__c, Document_Owner_Mismatch__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                    FROM Contact_Document__c
                    WHERE Contact__c = :applicantId
                    AND Contact__c != NULL
                    AND Application__c = :applicationId
                    ORDER BY Type__c
                    LIMIT 100
                ]) {
                    //Collect document links
                    if (loopContactDocument.ContentDocumentLinks != null) {
                        for (ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks) {
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            } else if (opportunityId != null) {
                for (Contact_Document__c loopContactDocument : [
                    SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Opportunity__c,
                        Internal_Only__c, Comments__c, Document_Assessment_Status__c, Document_Status__c, Application__c, Application__r.Applicant__c, Contact_Qualification__c,
                        Work_Experience__c, Contact__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                    FROM Contact_Document__c
                    WHERE Contact__c = :applicantId
                    AND Contact__c != NULL
                    AND Opportunity__c = :opportunityId
                    ORDER BY Type__c
                    LIMIT 100
                ]) {
                    //Collect document links
                    if (loopContactDocument.ContentDocumentLinks != null) {
                        for (ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks) {
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            } else {
                //Retrieve contact documents for contact qualification records
                for (Contact_Document__c loopContactDocument : [
                    SELECT Id, Filename__c, CreatedDate, toLabel(Document_Type__c), Submitted__c, Document_Checklist__r.Rule_DeveloperName__c, Document_Checklist__r.Status__c, Opportunity__c,
                        Internal_Only__c, Application__c, Application__r.Applicant__c, Contact_Qualification__c, Work_Experience__c, Contact__c, (SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLinks)
                    FROM Contact_Document__c
                    WHERE Contact__c = :applicantId
                    AND Contact__c != NULL
                    ORDER BY Type__c
                    LIMIT 100
                ]) {
                    //Collect document links
                    if (loopContactDocument.ContentDocumentLinks != null) {
                        for (ContentDocumentLink loopLink : loopContactDocument.ContentDocumentLinks) {
                            contentToContactDocumentMap.put(loopLink.ContentDocumentId, loopContactDocument);
                        }
                    }
                }
            }

            //Check if there are document links
            if (!contentToContactDocumentMap.isEmpty()) {
                //Query content document records
                for (ContentDocument loopContentDocument : [
                    SELECT Id, Description, FileExtension, FileType, Title, LatestPublishedVersion.VersionData
                    FROM ContentDocument
                    WHERE Id IN :contentToContactDocumentMap.keySet()
                    ORDER BY CreatedDate DESC
                    LIMIT 100
                ]) {
                    checklistDocumentItemList.add(new DocumentChecklistAssessmentServices.ChecklistDocument(loopContentDocument, contentToContactDocumentMap.get(loopContentDocument.Id)));
                }
            }
            //Sort documents with the selected document first            
            List<DocumentChecklistAssessmentServices.ChecklistDocument> sortedChecklistDocumentItemList = new List<DocumentChecklistAssessmentServices.ChecklistDocument>();

            //Apply selected only
            for (DocumentChecklistAssessmentServices.ChecklistDocument checklistDocument : checklistDocumentItemList) {
                sortedChecklistDocumentItemList.add(checklistDocument);
            }
            resultMap.put('documents', sortedChecklistDocumentItemList);

            //Retrieve notes
            for (Document_Checklist_Comment__c loopComment : [
                SELECT Id, Document_Checklist__c, Content__c, CreatedDate, CreatedBy.Name, NotesSeen__c
                FROM Document_Checklist_Comment__c
                WHERE Document_Checklist__c = :checklistItemId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ]) {
                notesList.add(new DocumentChecklistAssessmentServices.ChecklistNote(loopComment));
            }

            resultMap.put('notes', notesList);

            //Determine if there is a non-cancelled gte checklist associated
            Boolean hasGTE = false;
            for (Document_Checklist__c loopDocumentChecklist : [
                SELECT Id
                FROM Document_Checklist__c
                WHERE Application__c = :applicationId
                AND Type__c = 'GTE'
                AND Status__c != :System.Label.Application_Checklist_Auto_Cancelled
                LIMIT 100
            ]) {
                hasGTE = true;
            }
            resultMap.put('hasGTE', hasGTE);

            //Determine if there is a non-cancelled course requirement checklist associated
            Boolean hasCourseRequirement = false;
            for (Document_Checklist__c loopDocumentChecklist : [
                SELECT Id
                FROM Document_Checklist__c
                WHERE Application__c = :applicationId
                AND Type__c = 'Course'
                AND Status__c != :System.Label.Application_Checklist_Auto_Cancelled
                LIMIT 100
            ]) {
                hasCourseRequirement = true;
            }
            resultMap.put('hasCourseRequirement', hasCourseRequirement);

            // Retrieve the linked Contact Qual record
            String s_contactQualifcnFieldSetName;
            List<Contact_Document__c> linkedContactQual = [
                SELECT Id, Document_Checklist__c, Document_Checklist__r.Contact_Qualification__c,
                    Document_Checklist__r.Contact_Qualification__r.Name,
                    Document_Checklist__r.Contact_Qualification__r.RecordType.DeveloperName
                FROM Contact_Document__c
                WHERE Id = :Id.valueOf(selectedContactDocumentId)
            ];
            if (!linkedContactQual.isEmpty() && String.isNotBlank(linkedContactQual[0].Document_Checklist__c)
                && String.isNotBlank(linkedContactQual[0].Document_Checklist__r.Contact_Qualification__c)) {
                s_contactQualifcnFieldSetName = linkedContactQual[0].Document_Checklist__r.Contact_Qualification__r.RecordType.DeveloperName;
            }
            // Check if there is a linked Cont Qual (cont Doc -> Doc Checklist -> Cont Qual) and retrieve the Field Set details
            // Field Set name and COntact Qual record type Developer name should match
            if (String.isNotBlank(s_contactQualifcnFieldSetName)) {
                List<DocumentChecklistAssessmentServices.ContactQualFieldSetForm> l_contactQualForm = new List<DocumentChecklistAssessmentServices.ContactQualFieldSetForm>();
                Schema.SObjectType objectType = Schema.getGlobalDescribe().get('Contact_Qualification__c');
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
                Schema.FieldSet fieldSet = fieldSetMap.get(s_contactQualifcnFieldSetName);
                if (fieldSet != null) {
                    List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
                    DocumentChecklistAssessmentServices.ContactQualFieldSetForm obj;
                    for (Schema.FieldSetMember fsm : fieldSetMembers) {
                        obj = new DocumentChecklistAssessmentServices.ContactQualFieldSetForm();
                        obj.APIName = String.ValueOf(fsm.getSObjectField());
                        obj.Label = fsm.getLabel();
                        obj.contactQualRecdId = String.isBlank(linkedContactQual[0].Document_Checklist__r.Contact_Qualification__c) ? '' : linkedContactQual[0].Document_Checklist__r.Contact_Qualification__c ;
                        l_contactQualForm.add(obj);
                    }
                    resultMap.put('linkedContactQualictn', l_contactQualForm);
                }
            }
        } catch (Exception e) {
            nebula.Logger.error(e.getMessage(), e);
            nebula.Logger.saveLog();
            resultMap.put('error', e.getMessage());
        }
        return resultMap;
    }
}