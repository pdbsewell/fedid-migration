/**
 * Custom Controller Extension for use in Console_tabbedLists_v2 and Console_ContactNotesPanel_v2 Lightning component.
 * Specifically, the component that surfaces person notes, citizenship and interests
 *
 * @author 				APRivera	-	03.09.2018
 * @revisionHistory 	Created		-	03.09.2018
 *                      APRivera    -   10.12.2018 - Removed integration for Encumbrances and citizenship type
 *                      APRivera    -   17.12.2018 - Added filter (Person Note Type) from retrieved person note from Callista via MIX API
 *                      APRivera    -   19.12.2018 - Use encumbrance flag fields on contact to determine student encumbrances
 *                      APRivera    -   19.12.2018 - Use Citizenship_Code__c to display the Citizenship Type on MC Console
 *                      APRivera    -   17/01/2019 - Added ESOS__c in contact SOQL
 *                      APRivera    -   22/02/2019 - Added null validation on Student Id before calling Retrieve Person Notes API to reduce exception logging
 *                      APRivera    -   23/07/2019 - Added method for inserting case comments on user acknowledgement
 *                      APRivera    -   05/08/2019 - Added logic to check and retrieve contact's encumbrances
 */

public class Console_components_CEv2{

    @auraEnabled
    public static void insertCaseComments(Id recordId, Boolean bIsPersonNotes){
        CaseComment cseComment = new CaseComment();
        cseComment.ParentId = recordId;
        String strComment = bIsPersonNotes ? 'Special Care Notes ' : 'Encumbrances ';
        cseComment.CommentBody = strComment + 'acknowledged by ' + userInfo.getName() +'.';
        insert cseComment;
        System.debug(LoggingLevel.DEBUG, 'Case Comment Inserted');
    }

    @auraEnabled
    public static ThisWrapperClass init(Id recordId, String strSource){
        Case c = new Case();
        Id caseId;
        String studentId = '';
        Id contactId;
        ThisWrapperClass thisWrapper = new ThisWrapperClass();

        if(recordId.getSobjectType() == Schema.Contact.SObjectType){
            Contact conRecord = [SELECT Id, Person_ID__c FROM Contact WHERE Id =:recordId LIMIT 1];
            contactId = recordId;
            if(conRecord.Person_ID__c != null) studentId = conRecord.Person_ID__c;
        }else if(recordId.getSobjectType() == Schema.Case.SObjectType){
            c = [ SELECT Id, ContactId, CreatedDate, Contact.Person_ID__c, Status, IsClosed FROM Case WHERE Id =:recordId LIMIT 1];
            caseId = c.Id;
            contactId = c.ContactId;
            if(c.Contact.Person_ID__c != null) studentId = c.Contact.Person_ID__c;
        }

        thisWrapper.userRole = [SELECT	Id, Name FROM UserRole WHERE Id =: UserInfo.getUserRoleId()].Name;
        thisWrapper.studentId = studentId;
        thisWrapper.contactId = contactId;
        thisWrapper.caseId = caseId;
        thisWrapper.cseRec = c;
        thisWrapper.bIsClosed = c.IsClosed;
        thisWrapper.lstPersonNotes = new List<Person_Note__c>();
        if(contactId!=null){populateList(thisWrapper, strSource);}
        return thisWrapper;
    }

    public static void getCaseContact(ThisWrapperClass thisWrapper){
        thisWrapper.caseConRec = new Contact();
        thisWrapper.caseConRec = [SELECT Birthdate, Person_ID__c, Residency_Status__c, Citizenship_Code__c, Citizenship_Type_Description__c, has_admin_enc__c, has_academic_enc__c, ESOS__c,
        (SELECT Id, Name, Type__c, Notes__c, Style_Text__c, Important__c, Expires__c FROM Person_Notes__r),
        (SELECT Id, enc_category__c, enc_description__c, enc_comments__c, Contact__c FROM Encumbrance__r WHERE enc_expiry_date__c >=: System.today() OR enc_expiry_date__c = NULL),
        (SELECT Id, CaseNumber, Subject, Priority, CreatedDate, Status FROM Cases ORDER BY CreatedDate DESC LIMIT 30)
        FROM Contact WHERE Id =: thisWrapper.contactId LIMIT 1];

        thisWrapper.studentId = (thisWrapper.caseConRec.Person_ID__c != null)? thisWrapper.caseConRec.Person_ID__c : '';
    }

    public static void populateList(ThisWrapperClass thisWrapper,String strSource){
        thisWrapper.cseRec = new Case();
        getCaseContact(thisWrapper);
        checkEncumbrance(thisWrapper);
        thisWrapper.bHasSpecialCareNotes = thisWrapper.caseConRec.Person_Notes__r.isEmpty() ? false : true;
        if(strSource == 'CRM'){
            if(!thisWrapper.caseConRec.Person_Notes__r.isEmpty()){
                thisWrapper.lstPersonNotes.addAll(thisWrapper.caseConRec.Person_Notes__r);
            }
        }else{
            addpersonNoteForCitizenshipType(thisWrapper);
            addPersonNotesIfBelow18(thisWrapper);
            if(thisWrapper.studentId != '') retrieveStudentPersonNotes(thisWrapper);
        }
    }

    public static void addPersonNotesIfBelow18(ThisWrapperClass thisWrapper){
        // assess for being under 18 yo
        if(thisWrapper.caseConRec.Birthdate != null ){
            Boolean under18 = false;
            Integer yrs = Date.today().year() - thisWrapper.caseConRec.Birthdate.year();
            yrs += (thisWrapper.caseConRec.Birthdate.day() > Date.today().day() && thisWrapper.caseConRec.Birthdate.month() > Date.today().month() ) ? 1 : 0;
            under18 = (yrs < 18);

            // if under 18, then add a person note as important
            if(under18) thisWrapper.lstPersonNotes.add(new Person_Note__c(Notes__c = 'Under 18', Important__c = true,Style_Text__c = ''));
        }
    }

    //retrieved citizenship type of student
    public static void addpersonNoteForCitizenshipType(ThisWrapperClass thisWrapper){
        Map<String, String> mapContactCtznCodePickVal = getContactCitizenshipPicklistValue();
        String strCitizenship = 'CITZN: ';
        String strDescription = 'AP-CITZN: ';
        strCitizenship += (thisWrapper.caseConRec.Citizenship_Code__c == null) ? 'N/A' : mapContactCtznCodePickVal.get(thisWrapper.caseConRec.Citizenship_Code__c);
        strCitizenship += (thisWrapper.caseConRec.ESOS__c) ? ' - ESOS' : '' ;
        strDescription += (thisWrapper.caseConRec.Citizenship_Type_Description__c == null) ? 'N/A' : thisWrapper.caseConRec.Citizenship_Type_Description__c;

        thisWrapper.lstPersonNotes.add(new Person_Note__c(Notes__c = strCitizenship + ' | ' + strDescription, Style_Text__c = ''));
    }

    //Retrieve picklist Entry on Contact Citizenship_Code__c
    public static Map<String, String> getContactCitizenshipPicklistValue(){
        Map<String, String> mapContactCtznCodePickVal = new  Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Contact.Citizenship_Code__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry f : ple){
            mapContactCtznCodePickVal.put(f.getValue(), f.getLabel().substring(4));
        }
        return mapContactCtznCodePickVal;
    }

    //checks encumbrances of students
    public static void checkEncumbrance(ThisWrapperClass thisWrapper){
        if(thisWrapper.caseConRec.has_admin_enc__c > 0 || thisWrapper.caseConRec.has_academic_enc__c > 0){
            thisWrapper.bIsEncumbered = true;
            thisWrapper.lstEncumbrances = thisWrapper.caseConRec.Encumbrance__r;
        }
    }

    public static void retrieveStudentPersonNotes(ThisWrapperClass thisWrapper){
        HttpResponse response = (Test.isRunningTest()) ? SMSServices.mockPersonNotesResponse2() : SMSServices.invokeMIXAPICallout(thisWrapper.studentId);
        MIXAPI_StudentPersonNote notesResult = new MIXAPI_StudentPersonNote();
        notesResult.notes = new List<MIXAPI_StudentPersonNote.cls_notes>();
        Boolean hasPersonNote = false;

        System.debug(LoggingLevel.DEBUG, 'response.getstatusCode: ' + response.getStatusCode());
        if(response.getStatusCode() == 200){
            notesResult = (MIXAPI_StudentPersonNote) System.JSON.deserialize(response.getBody(), MIXAPI_StudentPersonNote.class);
        } else{
            thisWrapper.lstPersonNotes.add(new Person_Note__c(Type__c = 'MSG', Important__c=true, Notes__c = 'Error checking Notes from Callista',Style_Text__c = ''));
            CaseServices.storeExLog('Console component', 'Console_components_CE', 'retrievePersonNotes' , response.getStatus());
        }

        for(MIXAPI_StudentPersonNote.cls_notes pNote: notesResult.notes){
            if(pNote.noteType == 'AUTHINFO' || pNote.noteType == 'SECRTY_CHK'){
                thisWrapper.lstPersonNotes.add(new Person_Note__c(Notes__c = pNote.text, Important__c = false, Name = pNote.admissionApplicationId, Type__c = pNote.noteType, Style_Text__c = ''));
                hasPersonNote = true;
            }
        }

        if((notesResult.notes.isEmpty() && response.getStatusCode() == 200) || (!notesResult.notes.isEmpty() && !hasPersonNote))
            thisWrapper.lstPersonNotes.add(new Person_Note__c(Type__c = 'MSG', Notes__c = 'No notes found in Callista.',Style_Text__c = ''));
    }

    public class ThisWrapperClass{
        @AuraEnabled public String studentId {get; set;}
        @AuraEnabled public Boolean bIsClosed {get; set;}
        @AuraEnabled public Id contactId {get; set;}
        @AuraEnabled public Id caseId {get; set;}
        @AuraEnabled public Case cseRec {get; set;}
        @AuraEnabled public Contact caseConRec {get; set;}
        @AuraEnabled public List<Person_Note__c> lstPersonNotes{get; set;}
        @AuraEnabled public String userRole {get; set;}
        @AuraEnabled public Boolean bHasSpecialCareNotes {get; set;}
        @AuraEnabled public Boolean bIsEncumbered {get; set;}
        @AuraEnabled public List<Encumbrance__c> lstEncumbrances {get; set;}

    }

}