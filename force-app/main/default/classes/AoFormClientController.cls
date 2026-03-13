/**
 * /**
 * @author : [Babyshark]
 * @description : 
 *  - Client-side controller for dynamic AoForm
 *  - For a given form definition (AO_Form__c and it's child sobjects), return objects for LWC to render
 *  - Handles submission and saving of responses
 *  - Handles loading and prefilling of responses
 *  - Handles Admin Update of Student response
 *  - Manages loading of forms based upon Form Deadline Date from Program and Form Submissions
 * @group : Abroad Outbound
 * @date : 16/05/2024
 */
public with sharing class AoFormClientController {

    public class InputDefinition {
        @AuraEnabled public Object defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String type; // text, textarea, number, date, time, datetime, checkbox, picklist, radio, file upload, checkbox group
        @AuraEnabled public String validation; //TODO: implement
        @AuraEnabled public String[] options;
        @AuraEnabled public String helpText;
    }

    public class OutputDefinition {
        @AuraEnabled public String type; // rich
        @AuraEnabled public String value;
    }

    public class SectionDefinition {
        @AuraEnabled public Integer numColumns;
        @AuraEnabled public List<FormElement> childElements;
    }

    public class VisibilityCondition {
        @AuraEnabled public String elementId;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
    }

    public class FormElement {
        @AuraEnabled public String id; // system reference for saved forms / restoring state
        @AuraEnabled public String name; // human reference for submission
        @AuraEnabled public String label;
        @AuraEnabled public VisibilityCondition visibilityCondition;
        @AuraEnabled public Boolean initiallyHidden;
        @AuraEnabled public String type; // input, output, section, spacer
        @AuraEnabled public Integer size; // width (in columns) of element

        // for elementType = 'section'
        @AuraEnabled public SectionDefinition sectionDefinition;
        // for elementType = 'input'
        @AuraEnabled public InputDefinition inputDefinition;
        // for elementType = 'output'
        @AuraEnabled public OutputDefinition outputDefinition;
    }

    public class Form {
        @AuraEnabled public String formId;
        @AuraEnabled public String formName;
        @AuraEnabled public Integer numColumns;
        @AuraEnabled public List<FormElement> childElements;
        @AuraEnabled public Id savedSubmissionId; // null if new submission
        @AuraEnabled public Boolean canSave;
        @AuraEnabled public Map<String,Object> prefilledValues; // elementId => value
        @AuraEnabled public String completionUrl;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String formDescription;
        @AuraEnabled public String message;

    }

    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_ASSIGNED = 'Assigned';
    public static final String PROGRAM_OUTSIDE_RANGE_MESSAGE = 'Selected Program has not either been Started or has been ended';
    public static final Set<String> DRAFT_STATUSES = new Set<String>{STATUS_DRAFT, STATUS_ASSIGNED};
    public static final String SEQUENCE_PRIMARY = 'Primary';
    public static final String SEQUENCE_SUBSEQUENT = 'Subsequent';
    public static final String MULTI_SUBMIT_FORM = 'Multi Submit Form';

    

    /**
     * @description - Return a form including it's prefill and any saved submission data for current user.
     * Only one of formName, formId, or programMapId should be provided.
     */
    @AuraEnabled
    public static Form getForm(String formName, Id formId, String formProgramId, String submissionId) {
        String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
        AO_Program_Form_Map__c aFormMapObj = new AO_Program_Form_Map__c();
        Id applicantId;
        Boolean adminUpdate = false;
        Integer paramCount = 0;
        if (String.isNotBlank(formName)) {paramCount++;}
        if (formId != null) {paramCount++;}
        if (formProgramId != null) {
            formProgramId = AOEncryptionUtil.decrypt256(key, EncodingUtil.urlDecode(formProgramId,'UTF-8'));
            paramCount++;
        }
        if(String.isNotBlank(submissionId) && submissionId.length()>18){
            submissionId = AOEncryptionUtil.decrypt256(key, EncodingUtil.urlDecode(submissionId,'UTF-8'));
        }
        if(paramCount > 1) {
            throw new AuraHandledException('Only one of formName, formId, or programMapId should be provided');
        }
        if(String.isNotBlank(submissionId) && String.isBlank(formId) && String.isBlank(formProgramId)){
            AO_Form_Submission__c formSub = [SELECT Id, AO_Program_Form_Map__c, AO_Program_Applicant__c FROM AO_Form_Submission__c WHERE Id=:submissionId WITH SYSTEM_MODE LIMIT 1];
            formProgramId = formSub.AO_Program_Form_Map__c;
            applicantId = formSub.AO_Program_Applicant__c;
            adminUpdate =  true;
        }
        if(formProgramId != null) {
            aFormMapObj = [SELECT AO_Form__c, AO_Program__r.AO_Form_Deadline_Date__c,AO_Program__r.End_Date__c, AO_Program__r.Start_Date__c,AO_Program__c, AO_Sequence__c FROM AO_Program_Form_Map__c WHERE Id = :formProgramId WITH SYSTEM_MODE LIMIT 1];
            formId = aFormMapObj.AO_Form__c;
        }
        if(String.isBlank(applicantId)){
            User us = [SELECT Id, ContactId FROM User WHERE Id= :UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];
            AO_Program_Applicant__c[] applicant = [SELECT Id FROM AO_Program_Applicant__c WHERE AO_Program__c = :aFormMapObj.AO_Program__c AND AO_Contact__c = :us.ContactId WITH SYSTEM_MODE];
            applicantId = applicant.isEmpty() ? null : applicant[0].Id;
        }
        AO_Form__c[] formResult = [
            SELECT
                Name, Completion_URL__c, AO_Form_Display_Name__c, AO_Form_Description__c, 
                /*(
                    SELECT Name, Parent_Element__c, Label__c, Required__c, Read_Only__c,AO_Type__c,
                        Visibility_Rule_Operator__c, Visibility_Rule_Form_Element__c, Visibility_Rule_Value__c,
                        Element_Column_Width__c, Section_Columns__c, Admin_Only__c,
                        ed.Name, ed.AO_Default_Value__c, ed.AO_Help_Text__c, ed.Display_Text_Value__c,
                        ed.AO_Maps_to_Field__c, ed.AO_Maps_To_Object__c, ed.AO_Picklist_Values__c, ed.AO_Type__c,
                        ed.AO_Prefill_Value_Field__c, ed.AO_Prefill_Value_Object__c, ed.AO_Question__c
                    FROM Form_Elements__r fe, fe.Element_Definition__r ed
                    ORDER BY Element_Sequence__c ASC
                ),*/
                (
                    SELECT AO_Response_Json__c, AO_Status__c, AO_Program_Form_Map__c, AO_Deadline_Date__c 
                    FROM Form_Submissions__r
                    WHERE AO_Program_Applicant__c = :applicantId 
                    ORDER BY CreatedDate DESC
                )
            FROM AO_Form__c WHERE Name = :formName OR Id = :formId WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        if (formResult.isEmpty()) {
            return null;
        }
        AO_Form__c form = formResult[0];

        Form formDef = new Form();
        formDef.formId = form.Id;
        formDef.formName = form.AO_Form_Display_Name__c;
        formDef.childElements = new List<FormElement>();
        formDef.numColumns = 1;
        formDef.completionUrl = form.Completion_URL__c;
        formDef.formDescription = form.AO_Form_Description__c;
        formDef.message = '';
        Map<Id, FormElement> elemsById = new Map<Id, FormElement>();
        if(form.Form_Submissions__r.isEmpty() && aFormMapObj.AO_Sequence__c == SEQUENCE_PRIMARY && (aFormMapObj.AO_Program__r.AO_Form_Deadline_Date__c != null && aFormMapObj.AO_Program__r.AO_Form_Deadline_Date__c < Date.today())){
            formDef.message = PROGRAM_OUTSIDE_RANGE_MESSAGE;
            return formDef;
        }
        List<AO_Form_Element__c> formElementonForm = [SELECT Name, Parent_Element__c, Label__c, Required__c, Read_Only__c,AO_Type__c,
        Visibility_Rule_Operator__c, Visibility_Rule_Form_Element__c, Visibility_Rule_Value__c,
        Element_Column_Width__c, Section_Columns__c, Admin_Only__c,
        ed.Name, ed.AO_Default_Value__c, ed.AO_Help_Text__c, ed.Display_Text_Value__c,
        ed.AO_Maps_to_Field__c, ed.AO_Maps_To_Object__c, ed.AO_Picklist_Values__c, ed.AO_Type__c,
        ed.AO_Prefill_Value_Field__c, ed.AO_Prefill_Value_Object__c, ed.AO_Question__c
        FROM AO_Form_Element__c fe, fe.Element_Definition__r ed WHERE Form__c = :form.Id 
        ORDER BY Element_Sequence__c ASC];
        for (AO_Form_Element__c feSObj : formElementonForm) 
        {
            FormElement fe = new FormElement();
            elemsById.put(feSObj.Id, fe);
            fe.id = feSObj.Id;
            fe.name = feSObj.Name;
            fe.label = feSObj.Label__c;
            fe.size = feSObj.Element_Column_Width__c > 0 ? Integer.valueOf(feSObj.Element_Column_Width__c) : 1;

            if(feSObj.Visibility_Rule_Form_Element__c != null) {
                // element has conditional visible
                fe.visibilityCondition = new VisibilityCondition();
                fe.visibilityCondition.elementId = feSObj.Visibility_Rule_Form_Element__c;
                fe.visibilityCondition.operator = feSObj.Visibility_Rule_Operator__c;
                fe.visibilityCondition.value = feSObj.Visibility_Rule_Value__c;
                fe.initiallyHidden = true;
            }

            if(feSObj.AO_Type__c == 'Section') {
                fe.type = 'section';
                fe.sectionDefinition = new SectionDefinition();
                fe.sectionDefinition.numColumns = feSObj.Section_Columns__c > 0 ? Integer.valueOf(feSObj.Section_Columns__c) : 1;
                fe.sectionDefinition.childElements = new List<FormElement>();
                if(feSObj.Admin_Only__c && !adminUpdate) {
                    // always hidden from front-end but will populate an empty value in the response
                    fe.initiallyHidden = true;
                }
            } else if(feSObj.Element_Definition__c == null) {
                // missing definition,
                continue;
            }

            if (feSObj.Parent_Element__c == null) {
                // if element is top-level, add it to the form
                formDef.childElements.add(fe);
            }

            if(feSObj.AO_Type__c != 'Data') {
                // nothing else to do for sections/spacers
                continue;
            }

            AO_Question_Library__c edSObj = feSObj.Element_Definition__r;

            // display text is the only type of output currently supported
            fe.type = edSObj.AO_Type__c == 'Display Text' ? 'output' : 'input';

            if(fe.type == 'input') {
                //-- Element is an Input --//
                InputDefinition inputDef = new InputDefinition();
                // Form_Element__c Label__c works as an override for the Question_Library__c label
                fe.label = String.isNotBlank(fe.label) ? fe.label : edSObj.AO_Question__c;
                fe.name = edSObj.Name;
                inputDef.helpText = edSObj.AO_Help_Text__c;
                inputDef.defaultValue = edSObj.AO_Default_Value__c;
                inputDef.type = edSObj.AO_Type__c.toLowerCase();
                inputDef.required = feSObj.Required__c;
                inputDef.readOnly = feSObj.Read_Only__c;

                if(feSObj.Admin_Only__c && !adminUpdate) {
                    // always hidden from front-end but will populate an empty value in the response
                    inputDef.readOnly = true;
                    fe.initiallyHidden = true;
                }

                if(String.isNotBlank(edSObj.AO_Picklist_Values__c)) {
                    inputDef.options = new String[0];
                    for(String opt :edSObj.AO_Picklist_Values__c.split('\n')) {
                        inputDef.options.add(opt.trim());
                    }
                }
                fe.inputDefinition = inputDef;
            }
            if(fe.type == 'output') {
                //-- Element is an Output --//
                OutputDefinition outputDef = new OutputDefinition();
                outputDef.type = edSObj.AO_Type__c == 'Display Text' ? 'rich' : edSObj.AO_Type__c;
                outputDef.value = edSObj.Display_Text_Value__c;
                fe.outputDefinition = outputDef;
                if(feSObj.Admin_Only__c && !adminUpdate) {
                    // always hidden from front-end but will populate an empty value in the response
                    fe.initiallyHidden = true;
                }
            }

        }

        // add child elements to their sections
        for(AO_Form_Element__c elem : formElementonForm) {
            FormElement parentElem = elemsById.get(elem.Parent_Element__c);
            if (parentElem != null && parentElem.type == 'Section') {
                parentElem.sectionDefinition.childElements.add(elemsById.get(elem.Id));
            }
        }

        formDef.prefilledValues = new Map<String, Object>();
        for(AO_Form_Submission__c savedSubmission : form.Form_Submissions__r) {
            if(submissionId != null && savedSubmission.Id != submissionId) {
                // specific submission requested, skip non-matching submissions
                continue;
            }
            if(aFormMapObj.AO_Sequence__c == MULTI_SUBMIT_FORM && !DRAFT_STATUSES.contains(savedSubmission.AO_Status__c) && String.isBlank(submissionId)) {
                // multiple form submissions allowed on the MULTI_SUBMIT_FORM
                continue;
            }
            if(formProgramId != null && savedSubmission.AO_Program_Form_Map__c != formProgramId) {
                // program-specific form submission, skip non-matching submissions
                continue;
            }
            formDef.savedSubmissionId = savedSubmission.Id;

            formDef.readOnly = !DRAFT_STATUSES.contains(savedSubmission.AO_Status__c) && !adminUpdate;  
            if(formDef.readOnly) {
                for(FormElement elem : elemsById.values()) {
                    if(elem.inputDefinition != null) {
                        elem.inputDefinition.readOnly = true;
                    }
                }
            }

            if((aFormMapObj.AO_Program__r.AO_Form_Deadline_Date__c != null && aFormMapObj.AO_Program__r.AO_Form_Deadline_Date__c < Date.today()) && aFormMapObj.AO_Sequence__c == SEQUENCE_PRIMARY){
                formDef.message = PROGRAM_OUTSIDE_RANGE_MESSAGE;
            }
            else if((savedSubmission.AO_Deadline_Date__c != null && savedSubmission.AO_Deadline_Date__c < Date.today()) && aFormMapObj.AO_Sequence__c != SEQUENCE_PRIMARY && aFormMapObj.AO_Sequence__c != SEQUENCE_SUBSEQUENT){
                formDef.message = PROGRAM_OUTSIDE_RANGE_MESSAGE;
            }

            if(String.isNotBlank(savedSubmission.AO_Response_Json__c)){
                List<Object> jsonObjList = (List<Object>) JSON.deserializeUntyped(savedSubmission.AO_Response_Json__c);

                for (Object obj : jsonObjList) {
                    Map<String, Object> jsonObj = (Map<String, Object>) obj;
                    formDef.prefilledValues.put((String)jsonObj.get('elementId'), jsonObj.get('value'));
                }
            }
            break; // only load the first matching submission
        }

        User u = [
            SELECT ContactId, Contact.Primary_Course_Attempt__c FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        Map<String,Id> prefillObjects = new Map<String,Id>{};
        if(u?.ContactId != null) {
            prefillObjects.put('Contact', u.ContactId);
            Emergency_Contact__c [] emergencyContact = [SELECT Id FROM Emergency_Contact__c WHERE Contact__c =: u.ContactId AND Active__c = true];
            if(!emergencyContact.isEmpty()){
                prefillObjects.put('Emergency_Contact__c', emergencyContact[0].Id);
            }
        }
        if(u?.Contact?.Primary_Course_Attempt__c != null) {
            prefillObjects.put('Course_Attempt__c', u.Contact.Primary_Course_Attempt__c);
        }

        formDef.prefilledValues.putAll(
            AoFormClientController.getPrefillData(formElementonForm, prefillObjects)
        );

        return formDef;
    }

    public class Answer {
        @AuraEnabled public String elementId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String type {get; set;} // as defined in inputDefinition.type
        @AuraEnabled public Object value {get; set;}
    }

    /**
     * @param formId
     * @param answers
     * @param submissionId  can be null for new submissions
     * @param programFormId  can be null
     * @param isDraft
     */
    @AuraEnabled(Cacheable=false)
    public static Id submitForm(Id formId, List<Answer> answers, Id submissionId, String programFormId, Boolean isDraft) {
        try{
            String key = SystemSettingsUtil.getInstance().getByKeyFeature('AO_ABROAD', 'ENCRYPTION_KEY')?.value__c;
            AO_Program_Form_Map__c aFormMapObj = new AO_Program_Form_Map__c();
            Id abroadRecordTypeId =Schema.SObjectType.AO_Form_Submission__c.getRecordTypeInfosByDeveloperName().get('Monash_Abroad').getRecordTypeId();
            
            if(programFormId != null) {
                programFormId = AOEncryptionUtil.decrypt256(key, EncodingUtil.urlDecode(programFormId,'UTF-8'));
                aFormMapObj = [SELECT AO_Form__c, AO_Program__r.End_Date__c, AO_Program__r.Start_Date__c,AO_Program__c, AO_Sequence__c FROM AO_Program_Form_Map__c WHERE Id = :programFormId WITH SYSTEM_MODE LIMIT 1];
                formId = aFormMapObj.AO_Form__c;
            }
            /*if(String.isNotBlank(submissionId)){
                submissionId = AOEncryptionUtil.decrypt256(key, EncodingUtil.urlDecode(submissionId, 'UTF-8'));
            }*/
            User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE];
            AO_Program_Applicant__c[] applicant = [SELECT Id FROM AO_Program_Applicant__c WHERE AO_Program__c = :aFormMapObj.AO_Program__c AND AO_Contact__c = :u.ContactId WITH SYSTEM_MODE];
            Id applicantId = applicant.isEmpty() ? null : applicant[0].Id;
            AO_Form_Submission__c submission = getDraftSubmission(submissionId, applicantId);
            submission.RecordTypeId = abroadRecordTypeId;
            submission.AO_Form__c = formId;
            submission.AO_Submitted_By_User__c = u.Id;
            if(!isDraft) {
                submission.AO_Submitted_Date__c = Date.today();
            }
            submission.AO_Student__c = u.ContactId;
            submission.AO_Status__c = isDraft ? STATUS_DRAFT : STATUS_SUBMITTED;
            submission.AO_Response_Json__c = JSON.serializePretty(answers);
            submission.AO_Program_Form_Map__c = programFormId;

            upsert submission;

            // link any newly uploaded files to the submission
            Boolean hasFiles = false; // use to skip unnecessary query
            for(Answer a :answers) {
                if (a.type == 'file upload') {
                    hasFiles = true;
                    break;
                }
            }
            if(hasFiles) {
                Set<Id> existingDocIds = new Set<Id>();
                for(ContentDocumentLink cdl :[
                    SELECT ContentDocumentId FROM ContentDocumentLink
                    WHERE LinkedEntityId = :submission.Id WITH SYSTEM_MODE
                ]) {
                    existingDocIds.add(cdl.ContentDocumentId);
                }
                ContentDocumentLink[] newLinks = new ContentDocumentLink[0];
                for (Answer a : answers) {
                    if (a.type == 'file upload') {
                        List<Object> files = (List<Object>) a.value;
                        if (files == null) {
                            // skip empty object
                            continue;
                        }
                        for (Object f : files) {
                            Map<Object, Object> fileData = (Map<Object, Object>) f;
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = (Id) fileData.get('documentId');
                            if(existingDocIds.contains(cdl.ContentDocumentId)) {
                                // skip any existing files
                                continue;
                            }
                            cdl.LinkedEntityId = submission.Id;
                            cdl.ShareType = 'I'; // Inferred permission - Access leve is determined by related record
                            cdl.Visibility = 'AllUsers';
                            newLinks.add(cdl);
                        }
                    }
                }
                insert newLinks;
            }

            return submission.Id;
        }
        catch(Exception e){
            nebula.logger.exception(e.getMessage(), e);
            return null;
        }
    }

    public static AO_Form_Submission__c getDraftSubmission(String submissionId, Id userId) {
        if(submissionId != null) {
            return [
                SELECT Id FROM AO_Form_Submission__c
                WHERE Id = :submissionId AND AO_Program_Applicant__c = :userId WITH SYSTEM_MODE /*AND
                    AO_Status__c IN :DRAFT_STATUSES*/
            ];
        } else {
            return new AO_Form_Submission__c();
        }
    }

    /**
     * Given lists of sobjects+fields, return the fields that are found via describe
     * Case in returned map will match input
     *
     * @param prefillMappings  objectName => {fieldName => elementId}
     * @return objectName => fieldList
     */
    public static Map<String,String[]> getExistingFields(Map<String,Map<String,String>> prefillMappings) {
        Map<String,String[]> objectFieldValid = new Map<String,String[]>();

        if(!prefillMappings.isEmpty()) {
            Schema.DescribeSObjectResult[] results = Schema.describeSObjects(new List<String>(prefillMappings.keySet()));

            for(String objName : prefillMappings.keySet()) {
                for(Schema.DescribeSObjectResult result : results) {
                    if(result.getName() == objName) {
                        // match given object name with described name
                        String[] fields = new String[0];
                        for(String field : prefillMappings.get(objName).keySet()) {
                            if(result.fields.getMap().containsKey(field)) {
                                // above works because field describe map is case-insensitive
                                fields.add(field);
                            }
                        }
                        objectFieldValid.put(objName, fields);
                    }
                }
            }
        }
        return objectFieldValid;
    }

    /**
     * Given a list of form elements, return a map of prefill mappings
     * @param elems
     * @return objectName => {fieldName => elementId}
     */
    public static Map<String,Map<String,String>> getPrefillMappings(AO_Form_Element__c[] elems) {
        Map<String,Map<String,String>> prefillMappings = new Map<String,Map<String,String>>();
        // collect prefill fields
        for(AO_Form_Element__c elem : elems) {
            AO_Question_Library__c ed = elem.Element_Definition__r;
            if(ed == null) {
                continue;
            }

            if(String.isNotBlank(ed.AO_Prefill_Value_Object__c) && String.isNotBlank(ed.AO_Prefill_Value_Field__c)) {
                if(!prefillMappings.containsKey(ed.AO_Prefill_Value_Object__c)) {
                    prefillMappings.put(ed.AO_Prefill_Value_Object__c, new Map<String,String>());
                }
                prefillMappings.get(ed.AO_Prefill_Value_Object__c).put(ed.AO_Prefill_Value_Field__c, elem.Id);
            }
        }
        return prefillMappings;
    }

    /**
     * @param elems
     * @param objectIds
     *
     * @return value of field from appropriate object to be automatically populated in questions
     */
    public static Map<String,Object> getPrefillData(AO_Form_Element__c[] elems, Map<String, Id> objectIds) {

        // objectName => {fieldName => elementId}
        Map<String,Map<String,String>> prefillMappings = getPrefillMappings(elems);

        Map<String,String[]> objectFields = getExistingFields(prefillMappings);

        // elementId => value
        Map<String,Object> prefillValues = new Map<String,Object>();

        for(String objName : objectFields.keySet()) {
            String[] fields = objectFields.get(objName);
            if(fields.isEmpty() || !objectIds.containsKey(objName)) {
                continue;
            }
            String conditionExp = 'Id = :Id';
            Map<String,String> conditionVals = new Map<String,String>{'Id' => objectIds.get(objName)};

            // build query
            String query = String.format(
                'SELECT {0} FROM {1} WHERE {2} LIMIT 1',
                new String[]{String.join(fields,', '), objName, conditionExp}
            );

            List<SObject> results = Database.queryWithBinds(query, conditionVals, AccessLevel.SYSTEM_MODE);

            if(!results.isEmpty()) {
                SObject result = results[0];
                for(String field : fields) {
                    // map field value to elementId
                    String elementId = prefillMappings.get(objName).get(field);
                    prefillValues.put(elementId, result.get(field));
                }
            }
        }
        //System.debug('Prefill-->RA-->'+ prefillValues);
        return prefillValues;
    }

    /**
     * @param formId
     * @param answers
     * @param submissionId  can be null for new submissions
     * @param programFormId  can be null
     * @param isDraft
     * @description method used to update response JSON in case an Admin is updating the response from Form Submission screen
     */
    @AuraEnabled(Cacheable=false)
    public static Id updateAdminResponse(Id submissionId, Id programFormId, List<Answer> answers) {
        try{
            AO_Form_Submission__c formSub = [SELECT Id, AO_Program_Form_Map__c, AO_Program_Applicant__c FROM AO_Form_Submission__c WHERE Id=:submissionId WITH SYSTEM_MODE LIMIT 1];
            AO_Form_Submission__c submission = getDraftSubmission(submissionId, formSub.AO_Program_Applicant__c);
            submission.AO_Response_Json__c = JSON.serializePretty(answers);
            //AO_Form_Submission__c submission = new AO_Form_Submission__c(Id = submissionId, AO_Response_Json__c = JSON.serializePretty(answers));
            upsert submission;
            return submission.Id;
        }
        catch(Exception e){
            nebula.logger.exception(e.getMessage(), e);
            return null;
        }
    }
}