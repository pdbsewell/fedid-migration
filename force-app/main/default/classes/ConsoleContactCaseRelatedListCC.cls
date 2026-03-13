/**
 * @author          Kristian Vegerano
 * @description     Extension class for Console_ContactEnquiryRelatedList visualforce page
 */
public with sharing class ConsoleContactCaseRelatedListCC {
    public Contact pageContact {get; set;}
    public List<Case> enquiryList {get; set;}
    
    /**
     * @author          Kristian Vegerano
     * @description     Constructor
     */
    public ConsoleContactCaseRelatedListCC(ApexPages.StandardController contactController) {
        //Initialize Variables
        pageContact = new Contact();
        enquiryList = new List<Case>();
        
        //Query required contact fields
        pageContact = [SELECT Id, Name 
                       FROM Contact 
                       WHERE Id = :((Contact)contactController.getRecord()).Id LIMIT 1];
                       
        
        //Query related enquiry records
        for(Case loopEnquiry : [SELECT Id, CaseNumber, Subject, Priority, CreatedDate, Status
                                FROM Case
                                WHERE ContactId = :pageContact.Id
                                ORDER BY CaseNumber DESC]){
            enquiryList.add(loopEnquiry);
        }
    }
}