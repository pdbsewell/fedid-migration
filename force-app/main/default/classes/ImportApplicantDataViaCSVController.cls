/**
* @author Nadula Karunaratna
* @date 20-SEP-2017
* @group Professional Development
* @description Upload CSV file for Offline Bulk Registrations by staff member. 
*              This creates all necessory records for for a registration and add an ACP and a Contact for each line in CSV under one Application record 
* @revision Nadula Karunaratna | 06/07/2020 | PRODEV-532 | PMD Sev 1 - code optimisation 
*/

public class ImportApplicantDataViaCSVController {

    public String documentName {get;set;}
    public Blob csvFileBody{get;set;}
    public String[] contactDataLines {get;set;}
    public List <Contact> lstContacts {get;set;}
    public boolean readSuccess {get;set;}
    public List<String> lstFieldNames{get;set;}
    Contact conObj;
    public String contactDataAsString;
    String fieldValue;
    Integer fieldNumber;
    Map <String, Integer> fieldNumberMap = new Map < String, Integer > ();
    public boolean showDataPanel {get;set;}  

    //use to generate the data table
    public List <Contact> lstContactsData {get;set;}
    public List<String> lstFieldNamesData {get;set;}
      

    //Define incoming paramters 
    public String applicationID {get; set;} 
    public String courseOfferingID {get; set;} 

    public String courseCode {get; set;}
    public String courseName {get; set;}    
    public String howManyApplicants {get; set;}    

    //display file upload buttons
    public boolean displayUploadBlock {get;set;}

    //showMessagePanel_1
    public boolean showMessagePanel_1 {get;set;}
    

  public ImportApplicantDataViaCSVController () 
  {
    documentName = '';
    readSuccess = FALSE;
    contactDataLines = new String[] {};
    lstContacts = new List <Contact> ();
    lstFieldNames = new List<String>();
    
    showDataPanel =  FALSE;
    displayUploadBlock = TRUE;
    showMessagePanel_1 = FALSE;
  }

  public void readFromFile(){
    lstContacts.clear();    
    try{
        contactDataAsString = csvFileBody.toString();
        system.debug('contactDataAsString ' +contactDataAsString );          
        readCSVFile();
    }
    catch(exception e){
        readSuccess = FALSE;
        ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error reading CSV file');
        ApexPages.addMessage(errorMessage);
        showDataPanel =  FALSE;
    }
  }

  public void enableReUploadCSV() {
    showMessagePanel_1 = FALSE;
    displayUploadBlock = TRUE;    
  } 

  public void readCSVFile() {
    
    lstContacts.clear();
    contactDataLines = contactDataAsString.split('\n');
    string[] csvFieldNames = contactDataLines[0].split(',');
    for (Integer i = 0; i < csvFieldNames.size(); i++) {
        fieldNumberMap.put(csvFieldNames[i], i);
        lstFieldNames.add(csvFieldNames[i].trim());
    }

    system.debug('contactDataLines ' +contactDataLines);

    for (Integer i = 1; i < contactDataLines.size(); i++) {
        conObj = new Contact();
        string[] csvRecordData = contactDataLines[i].split(',');
        for (String fieldName: csvFieldNames) {
            fieldNumber = fieldNumberMap.get(fieldName);
            fieldValue = csvRecordData[fieldNumber];
            conObj.put(fieldName.trim(), fieldValue.trim());
        }           

        lstContacts.add(conObj);                
    }
    Integer applicantsCount;
    applicantsCount = integer.valueOf(howManyApplicants.trim());
    if((lstContacts.size() > 0) && (lstContacts.size() == applicantsCount)){
        readSuccess = TRUE;
        showDataPanel = TRUE;   
        displayUploadBlock = FALSE;
        lstContactsData = lstContacts;
        lstFieldNamesData = lstFieldNames;

    } else {
        //do something to stop registering, but remember user can not go back to select intended number
        ApexPages.Message errorMessage2 = new ApexPages.Message(ApexPages.Severity.ERROR,'Number of applicants in file does not match to the intended number selected!');
        ApexPages.addMessage(errorMessage2);
        displayUploadBlock = FALSE;
        showMessagePanel_1 = TRUE;
        showDataPanel = FALSE;

        lstContacts.clear();
        lstFieldNames.clear();        
    }            
  }

  //check if Contact exists, then use existing contct
  //public static Contact getExistingContact(String givenName, String familyName, String email) {
  //  List<Contact> contacts = [SELECT FirstName, LastName, Title, Email, HomePhone, Phone, MobilePhone, MailingStreet, MailingCity, MailingState, MailingPostalCode FROM Contact WHERE FirstName = :givenName AND LastName = :familyName AND Email = :email];
  //  if(contacts.size()>0)
  //    return contacts.get(0);
  //  else
  //    return null;
  //}


  public void saveData() {
    saveBulkApplicantData(lstContacts,courseOfferingID,applicationID,courseCode,courseName);
  }

  public Map<String, Contact> getBulkContacts(List <Contact> lstContacts){
    //Retrieve all existing contacts
    Map<String, Contact> contactUniqueMap = new Map<String, Contact>();

    //Iterate through all contacts passed on this method (lstContacts)
    Set<String> contactFirstNameSet = new Set<String>();
    Set<String> contactLastNameSet = new Set<String>();
    Set<String> contactEmailSet = new Set<String>();
    for(Contact loopContact : lstContacts){
      //Get firstname
      if(loopContact.FirstName != null){
        contactFirstNameSet.add(loopContact.FirstName);
      }
      //Get lastname
      if(loopContact.LastName != null){
        contactLastNameSet.add(loopContact.LastName);
      }
      //Get lastname
      if(loopContact.Email != null){
        contactEmailSet.add(loopContact.Email);
      }
    }

    //Query existing contacts with proper firstname, lastname and email combinations
    for(Contact loopContact : [SELECT Id, FirstName, LastName, Email 
                               FROM Contact
                               WHERE FirstName IN :contactFirstNameSet AND LastName IN :contactLastNameSet AND Email IN :contactEmailSet]){
      contactUniqueMap.put(loopContact.FirstName + ':::' + loopContact.LastName + ':::' + loopContact.Email, loopContact);
    }

    return contactUniqueMap;
  }

  public void saveBulkApplicantData(List <Contact> lstContacts, String courseOfferingID, String applicationID, String courseCode, String courseName){

    Savepoint sp = Database.setSavepoint();

    try {
      //Get all combinations of Firstname, lastname and Email
      Map<String, Contact> contactUniqueMap = getBulkContacts(lstContacts);

      List<Application_Course_Preference__c> acpList = new List<Application_Course_Preference__c>();

      for(Contact lstContact_each : lstContacts){
        if(contactUniqueMap.containsKey(lstContact_each.FirstName + ':::' + lstContact_each.LastName + ':::' + lstContact_each.Email)){
          lstContact_each.Id = contactUniqueMap.get(lstContact_each.FirstName + ':::' + lstContact_each.LastName + ':::' + lstContact_each.Email).Id;
        }     
      }
      if(lstContacts.size() > 0){
        upsert lstContacts;
      }

      Course_Offering__c selectedCourseOffering = [SELECT Id, Course__c,Faculty__c
                                                   FROM Course_Offering__c
                                                   WHERE Id = :courseOfferingID
                                                   LIMIT 1];      

      for(Contact lstContact : lstContacts){                           

        //Create ACP record
        Application_Course_Preference__c acp = new Application_Course_Preference__c();
        acp.Applicant__c = lstContact.Id;
        acp.Application__c = applicationID;
        acp.Course_Offering__c = courseOfferingID;
        acp.Course_Code__c = courseCode; 
        acp.Course_Title__c = courseName;
        acp.Status__c = 'Registered';
        acp.Course__c = selectedCourseOffering.Course__c;
        acp.Course_Type_Text__c = 'Short_Course';        
        acp.Managing_Faculty_Text__c = selectedCourseOffering.Faculty__c;        
        acpList.add(acp);
      }
      
      if(acpList.size() > 0){
        upsert acpList;
      }

      //Display summery
      if(lstContacts.size() > 0){
        ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.INFO, 'Total of [ ' + lstContacts.size() + ' ] student (s) registered.');
        ApexPages.addMessage(errorMessage);
        readSuccess = FALSE;
        displayUploadBlock = FALSE;
      }

    } catch (Exception e) {
      ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured while saving data');
      ApexPages.addMessage(errorMessage);
      Database.rollback(sp);
    }

  } //end savedata


}