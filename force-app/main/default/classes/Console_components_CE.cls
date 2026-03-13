/**
 * Custom Controller Extension for use in custom service console component(s).
 * Specifically, the component that surfaces person notes, citizenship and interests
 *
 * @author Carl Vescovi, PwC
 * @revision 16/01/19 - APRivera - Remove dependency on API.monash
 *           22/02/19 - APRivera - Added MSG to saying 'No Student Id available to search notes in Callista'
 *           15/03/19 - MJC - Added details error logging to track down a bug
 *           23/04/19 - MJC - Added null check to stop exception. populateLists REALLY needs some TLC.
 *           01/05/19 - MJC - Added logic to stop .add(index,item) from returning an out of bounds error.
 */
public with sharing class Console_components_CE {
    
    public Case c {get; private set;}
    public Id caseId {get; private set;}
    public Id contactId {get; private set;}
    public string studentId {get; private set;}
    public Boolean under18 {get; private set;}
    public String notesLabel {get;private set;}
    public String tab {get;set;} // used to retain tab context across refreshes of tabbed view
    public string courseIdSelected {get;set;}
    public List<Person_Note__c> personNotes {get; private set;} // used in tabbed console component
    public Contact caseContact {get; private set;}
    public boolean loadingAttempted {get;set;}
    public boolean httpError {get;set;}
    public string rid {get; private set;}
    
    /** 
     * formats the current datetime into a string
     * @return string representing current date time
     */
  
    public string formattedDateTime {
        get{
            string res = c.createddate.format();
            if(c.createddate.date() == date.today()) { return 'Today at '+res.substringAfter(' '); } else
            if(c.createddate.date() == date.today().addDays(-1)){ return 'Yesterday at '+res.substringAfter(' '); } else
            { return String.valueOf(c.createddate.date().daysBetween(date.today())) + ' days ago at '+ res.substringAfter(' '); }
                
        }
    }
    
    /** 
     * retrieves the stored styles that could potentially be applied to person notes
     * @return map of styles to strings that might be used in notes
     */
    
    public Map<string, Person_Note_Style__c> noteStyles {
        get{
            if(noteStyles == null) noteStyles = Person_Note_Style__c.getAll();
            return noteStyles;
        }
        private set;
    }

    /** step in the page startup process, to attempt course and application list refreshes */

    public pageReference refreshLists(){
        httpError = false;
        loadingAttempted = false;
        populateLists();
        loadingAttempted = true;
        
        if(tab.indexOf('__item') != -1){
            tab = tab.subStringBetween('tab-default-','__item');
        } else {
            tab = '1' ; // default person notes tab
        }
        
        return null;
    }

    
    /** 
     * retrieves information from CRM relating to case being looked at, linked contact
     * information, and person notes information
     */
    
    private void populateLists(){
        under18 = false; 
        notesLabel = '';
        personNotes = new List<Person_Note__c>();
        caseContact = new contact();
        
        try{
            if(caseId != null){
                c = [select id, Enquiry_Type__c, contactId, IsClosed, Course_Code__c, Course__c, contact.Person_Id__c, Citizenship_at_Enquiry__c, CreatedDate,
                         (select id, name, course__c, course__r.Name, course__r.Course_Description__c, specialisation__c, specialisation_f__c, Study_Area__c, Detailed_Study_Area__c, createdbyid
                            from Enquiry_Interests__r)
                     from Case where id =:caseId limit 1];
                if(c != null && c.contactId != null) contactId = c.contactId; // using case context, so source contactid from case record

                studentId = (c.contact.Person_Id__c != null) ? c.contact.Person_Id__c : '';
            }
                    
            if(contactId != null){
                Date todaysDate = date.today(); // used in filter to exclude expired person notes
                caseContact = [select birthdate, Person_ID__c, Residency_Status__c, Citizenship_Code__c, Citizenship_Type_Description__c, has_admin_enc__c, has_academic_enc__c, ESOS__c,
                                   (select id, name, type__c, notes__c, Style_Text__c, important__c from Person_Notes__r where ( Expires__c >:todaysDate or Expires__c = null ) order by type__c),
                                   (select id, casenumber, subject, priority, createddate, status from Cases Order by CreatedDate DESC limit 30)
                                from contact where id =:contactId limit 1];
                studentId = (caseContact.Person_Id__c != null)? casecontact.Person_Id__c : '';
            }

            if(!caseContact.person_notes__r.isEmpty()) personNotes = caseContact.person_notes__r;

            // Have to check if c has been instantiated
            if(c != null && c.contactId != null) {
                // if student is encumbered (from previous callout) then note in the person notes to be surfaced in UI
                if(caseContact.has_admin_enc__c > 0 || caseContact.has_academic_enc__c > 0){
                    personNotes.add(new Person_Note__c(Notes__c = 'Encumbered', Important__c = true,Style_Text__c = ''));
                }else{
                    personNotes.add(new Person_Note__c(Notes__c = 'No Encumbrances',Style_Text__c = ''));
                }
                addpersonNoteForCitizenshipType(caseContact, personNotes);
            }

            // assess for being under 18 yo
            if(caseContact.birthdate != null ){
                integer yrs = date.today().year() - caseContact.birthdate.year();
                yrs += (caseContact.birthdate.day() > date.today().day() && caseContact.birthdate.month() > date.today().month() ) ? 1 : 0;
                under18 = (yrs < 18);
            }

            // if u18, then add a person note as important
            if(under18) personNotes.add(new Person_Note__c(Notes__c = 'Under 18', Important__c = true,Style_Text__c = ''));

            if(studentId > ''){
                retrieveStudentPersonNotes(studentId, personNotes);
            }else{
                personNotes.add(new Person_Note__c(Type__c = 'MSG',Notes__c = 'No Student Id available to search notes in Callista', Style_Text__c = ''));
            }
        } catch (exception ex){
            CaseServices.storeExLog('Console component', 'Console_components_CE', 'populate lists' ,ex.getMessage() + ex.getStackTraceString());
        }

        // apply admin controlled css where applicable to person notes
        // if is a match on type then that is only overridden by match on notes content
        for(Person_Note__c pnote : personNotes){
            string baseStyle = (pnote.Important__c) ? 'background:red;color:white;' : '';
            if(noteStyles.containsKey(pnote.Type__c)) baseStyle =  noteStyles.get(pnote.Type__c).css__c;
            if(noteStyles.containsKey(pnote.Notes__c)) baseStyle = noteStyles.get(pnote.Notes__c).css__c;
            pnote.Style_Text__c = baseStyle;
        }
    }

    //retrieved citizenship type of student
    public static void addpersonNoteForCitizenshipType(Contact caseConRec, List<Person_Note__c> lstPersonNotes){
        Map<String, String> mapContactCtznCodePickVal = getContactCitizenshipPicklistValue();
        String strCitizenship = 'CITZN: ';
        String strDescription = 'AP-CITZN: ';
        strCitizenship += (caseConRec.Citizenship_Code__c == null) ? 'N/A' : mapContactCtznCodePickVal.get(caseConRec.Citizenship_Code__c);
        strCitizenship += (caseConRec.ESOS__c) ? ' - ESOS' : '';
        strDescription += (caseConRec.Citizenship_Type_Description__c == null) ? 'N/A' : caseConRec.Citizenship_Type_Description__c;

       lstPersonNotes.add(new Person_Note__c(Notes__c = strCitizenship + ' | ' + strDescription, Style_Text__c = ''));
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

    public static void retrieveStudentPersonNotes(String studentId, List<Person_Note__c> lstPersonNotes){
        HttpResponse response = (Test.isRunningTest()) ? SMSServices.mockPersonNotesResponse2() : SMSServices.invokeMIXAPICallout(studentId);
        MIXAPI_StudentPersonNote notesResult = new MIXAPI_StudentPersonNote();
        notesResult.notes = new List<MIXAPI_StudentPersonNote.cls_notes>();
        Boolean hasPersonNote = false;

        System.debug(LoggingLevel.DEBUG, 'response.getstatusCode: ' + response.getstatusCode());
        if (response.getstatusCode() == 200) notesResult = (MIXAPI_StudentPersonNote) System.JSON.deserialize(response.getBody(), MIXAPI_StudentPersonNote.class);

        for (MIXAPI_StudentPersonNote.cls_notes pNote : notesResult.notes) {
            if (pNote.noteType == 'AUTHINFO' || pNote.noteType == 'SECRTY_CHK') {
                lstPersonNotes.add(new Person_Note__c(Notes__c = pNote.text, Important__c = false, Name = pNote.admissionApplicationId, Type__c = pNote.noteType, Style_Text__c = ''));
                hasPersonNote = true;
            }
        }
        
        if ((notesResult.notes.isEmpty() && response.getStatusCode() == 200) || (!notesResult.notes.isEmpty() && !hasPersonNote)) {
            if (lstPersonNotes.size() > 0 ) {
                // Add to the top of the list
                lstPersonNotes.add(0,new Person_Note__c(Type__c = 'MSG', Notes__c = 'No notes found in Callista.', Style_Text__c = ''));
            } else {
                // .add(index,item) gives an out of bounds error when used against an empty list
                lstPersonNotes.add(new Person_Note__c(Type__c = 'MSG', Notes__c = 'No notes found in Callista.', Style_Text__c = ''));
            }
        }
    }

   /** 
    * controller instantiation method 
    * @param controller standard page controller for use by extension
    */
    public Console_components_CE(ApexPages.StandardController controller) {
        // can be used from either case or contact context, so need to check which view is in use
        id recId = controller.getId(); // prevent xss as is cast to an id, not a string directly
        rid = (String)recId;
        
        studentId = '';
        if(rid == null) rid = '';
        
        if(rid > '' && rid.startsWith('003')){ // contact view
            contact ctmp = [select id, Person_Id__c from contact where id =:rid limit 1];
            contactId = rid;
            if(ctmp.Person_Id__c != null) studentId = ctmp.Person_Id__c;
            
        } else
        if(rid > '' && rid.startsWith('500')){ // case view
            c = [ select id, contactid, createddate, contact.Person_Id__c from Case where id =:rid limit 1];
            caseId = c.id;
            contactId = c.contactId;
            if(c.contact.Person_Id__c != null) studentId = c.contact.Person_Id__c;
            
        }
        tab = '1'; // default
        courseIdSelected = '';
        loadingAttempted = false;
        httpError = false;
    }

    /** 
     * retrieves a list of picklist values from Case.Enquiry_type__c field 
     * @return list of select options
     */
    
    public list<selectOption> casetypes {
        get{
            if(casetypes == null){
                 casetypes = new list<selectOption>();
                 Schema.DescribeFieldResult fieldResult = Case.Enquiry_Type__c.getDescribe();
                   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
                   for( Schema.PicklistEntry f : ple)
                   {
                      casetypes.add(new SelectOption(f.getLabel(), f.getValue()));
                   }              
            
            }
            return casetypes;
        }
        private set;
    }
}