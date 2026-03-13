/**
* @author Shalini Mendu
* @date 20-JUN-2018
* @group Professional Development
* @description Apex controller for StdRegistration aura component
* @revision Nadula Karunaratna | 31/01/2019 | PRODEV-332 | Added MSDI 
* @revision Nadula Karunaratna | 19/06/2019 | PRODEV-359 | Added Invoicing 
* @revision Nadula Karunaratna | 11/02/2020 | PRODEV-456 | Updated method getCOByName to read field Name 
* @revision Nadula Karunaratna | 17/02/2020 | PRODEV-456 | Added method retrieveFacultyData 
* @revision Nadula karunaratna | 09/07/2020 | PRODEV-567 | Summer 20 FIx - Introducing inner class systemModeDataAccess with without sharing
* @revision Cartick Sub - 18 October 2020 - PRODEV-656 - Set Enquiry Managing Faculty to MCPD if that is the parent Course Managing Faculty
* @revision Cartick Sub - 29 October 2020 - PRODEV-660 - Set Owner on records, to overcome default assignment to guest user 
* @revision Cartick Sub - 8 April 2021 - PRODEV-476 - Migrate Magento data from custom labels to custom settings
* @revision Cartick Sub - 18 May 2021 - PRODEV-686 - A few tidy-ups
* @revsion Ken McGuire - 24 May 2021 - PRODEV-687 - Migrate key methods to StdRegServices
*           P.Victoriano - 26 May 2021 - update getMagentoURL
* @revsion Ven Vairavan - 28 June 2022 - PRODEV-1072 - Invoice Payment Error
**/

public with sharing class StdRegController {

    // A Property to retrieve the System Admin User Id
    public static String SystemAdminUserId {
        get {
            return Environment_Settings__c.getOrgDefaults().System_Admin_User_Id__c;
        }
    }
    //Retrieve Course Offer by Name 
    @AuraEnabled
    public static List<String> retrieveCOPSList(String coName) {
        System.debug('coName='+coName);
        List<String> options = new List<String>();

        List<Course_Offering_Pricing__c> ebDtRes = [Select StartDate__c,EndDate__c from Course_Offering_Pricing__c where Active__c= true and  Course_Offering__r.Name=:coName  and  StartDate__c<=TODAY  and EndDate__c>=TODAY ORDER BY StartDate__c limit 1];
        List<Course_Offering_Pricing__c> copList = null;
        String pricingType ='Early Bird';
        if(ebDtRes.size()>0) {
            //Fix for EarlyBird pricing display issue PRODEV-348 | Nadula Karunaratna | 19/03/2019
            copList = [Select Pricing_Name__c,StartDate__c,EndDate__c,Fee__c,DiscountEvidenceType__c from Course_Offering_Pricing__c where Active__c= true AND Course_Offering__r.Status__c!='Full' AND Course_Offering__r.Name=:coName AND Pricing_Type__c= :pricingType];
        }else {
            copList = [Select Pricing_Name__c,StartDate__c,EndDate__c,Fee__c,DiscountEvidenceType__c from Course_Offering_Pricing__c where Active__c= true AND Course_Offering__r.Name=:coName AND Pricing_Type__c!= :pricingType];
        }
        for(Course_Offering_Pricing__c cop : copList) {
            options.add(cop.Pricing_Name__c+' - $'+cop.Fee__c+ '#'+cop.Id+'@'+cop.DiscountEvidenceType__c);
        }
        return options;
    }
    //Retrieve Course Offering record by Name
    @AuraEnabled
    public static Course_Offering__c getCOByName(String coName){
        System.debug('coName=='+coName);
        try {
            List<Course_Offering__c> courseOfferings = [SELECT Name, Id, Start_Date__c, End_Date__c, Fee__c, Concession_Fee__c, No_of_Sessions__c, Course__r.Course_Code__c, Number_of_Remaining_Places__c, Course__r.Course_Description__c, Venue__r.Name,Course__r.Managing_Faculty__c,Course__r.Type__c,Status__c,Course__r.FormstackURL__c,Course__r.Is_Selective__c, Course_Code_F__c, is_selective__c, Pay_by_Invoice__c, Course__r.Name,Pay_by_Cost_Centre_and_Fund__c FROM Course_Offering__c where Name = :coName];
            if (courseOfferings != null && courseOfferings.size() > 0) {
                System.debug('courseOfferings[0]=' + courseOfferings[0]+'&&&&'+courseOfferings[0].is_selective__c);
                return courseOfferings[0];
            }
        }catch(Exception ex)
        {
            System.debug('***** EXCEPTION FROM getCOByName*****'+ex.getMessage()+'**Line Number**'+ex.getLineNumber());
            return null;
        }
        return null;
    }
    //Retrieve the Salutations picklist field values from Contact
    @AuraEnabled
    public static List<String> retrieveSalutations() {
        System.debug('************* retrieveSalutations ************');
        List<String> options = new List<String>();
        options.add('');
        Schema.DescribeFieldResult fieldResult = Contact.Salutation.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }
        return options;
    }
    //Retrieve HeardFrom picklist field values from Case
    @AuraEnabled
    public static List<String> retrieveHeardFrom() {
        List<String> options = new List<String>();
        options.add('');
        Schema.DescribeFieldResult fieldResult = Case.Heard_About_From__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }
        return options;
    }
    @AuraEnabled
    public static List<String> retrieveCountries(){
      List<String> options  = new List<String>();
        options.add('');
        for(Country_Attribute__c con:
        [select Country__c, ISO_Alpha_2__c from Country_Attribute__c where PD_Shared__c=true order by Country__c ])
        {
            options.add(con.Country__c+'$'+con.ISO_Alpha_2__c);
        }
        return options;
    }
    @AuraEnabled
    public static List<String> retrieveStateForCountry(String countryCode){
        List<String> options  = new List<String>();
        options.add('');
        System.debug('retrieveStateForCountry==='+countryCode);
        for(State__c sta : [select Name, State_Code__c from State__c where Country_ISO_2__c =:countryCode order by Name desc])
        {
            System.debug('sta==='+sta);
            options.add(sta.Name+'$'+sta.State_Code__c);
        }
        return options;
    }
	@AuraEnabled
	public static StdRegServices.CourseRegistration processCourseEnquiry(StdRegServices.CourseEnquiry enquiry) {
		StdRegServices.CourseRegistration processedCourseEnquiry = new StdRegServices().createCourseRegistration(enquiry);
        processedCourseEnquiry.enforceSecurity();
        return processedCourseEnquiry;
	} 
    @AuraEnabled
    public static StdRegServices.CourseRegistration updateCourseRegistration(StdRegServices.CourseRegistration registration) {
        StdRegServices.CourseRegistration updatedCourseRegistration = new StdRegServices().updateCourseRegistration(registration);
        updatedCourseRegistration.enforceSecurity();
        return updatedCourseRegistration;
    }
    @AuraEnabled
    public static StdRegServices.CoursePayment processCoursePaymentRequest(StdRegServices.CoursePaymentRequest paymentRequest) {
        system.debug('*** process course payment paymentRequest = ' +paymentRequest);
      	StdRegServices.CoursePayment processedCoursePaymentRequest = new StdRegServices().processCoursePayment(paymentRequest);
        system.debug('*** process course payment result before enforce security = ' +processedCoursePaymentRequest);
      	processedCoursePaymentRequest.enforceSecurity();
        system.debug('*** process course payment result after enforce security = ' +processedCoursePaymentRequest);
        return processedCoursePaymentRequest;
    }
    @AuraEnabled
    public static StdRegServices.CoursePayment confirmCoursePayment(StdRegServices.CoursePayment coursePayment) {
      	StdRegServices.CoursePayment coursePaymentConfirmation = new StdRegServices().confirmCoursePayment(coursePayment);
      	coursePayment.enforceSecurity();
        return coursePaymentConfirmation;
    }
    @AuraEnabled
    public static StdRegServices.CourseEnqiryAttachments deleteAttachments(StdRegServices.CourseEnqiryAttachments enquiryAttachments) {
        StdRegServices.CourseEnqiryAttachments remainingAttachments = new StdRegServices().deleteAttachments(enquiryAttachments);
        remainingAttachments.enforceSecurity();
        return remainingAttachments;
    }
    @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert,
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks
        System.debug('Id=='+ parentId+',=='+fileName+',=='+contentType+',=='+fileId);
        if (fileId == '') {
            //fileId = saveTheFile(parentId, fileName, base64Data, contentType);
            fileId = StdRegServices.createAttachment(parentId, fileName, base64Data, contentType);
        } else {
            appendToFile(fileId, base64Data);
        }
        return Id.valueOf(fileId);
    }
    private static void appendToFile(Id fileId, String base64Data) {
        System.debug('inside-appendToFile');
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment a = [
                SELECT Id, Body
                FROM Attachment
                WHERE Id =: fileId
        ];
        String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
        update a;
    }
    @AuraEnabled
    public static List<Attachment> retrieveDocuments(String parentId) {
       return stdRegServices.getAttachments(parentId);
    }
    //getting terms and conditions page link for the course faculty
    @AuraEnabled
    public static String retrieveFacultyTnc(String faculty)
    {
        System.debug('retrieveFacultyTnc=='+faculty);

        List<Faculty_Custom_Data__mdt> tncCsList = [Select Terms_and_Conditions_URL__c,Managing_Faculty__c from Faculty_Custom_Data__mdt where Managing_Faculty__c=:faculty];

        System.debug('tncCsList=='+tncCsList);

        for(Faculty_Custom_Data__mdt tc: tncCsList) {

            if (faculty.startsWithIgnoreCase(tc.Managing_Faculty__c)) {
                return tc.Terms_and_Conditions_URL__c;
            }
        }
        return null;
    }
     @AuraEnabled
    public static String getMagentoURL(String paymentId){
        System.debug('*****IN getMagentoURL*****'+paymentId);
        return StdRegServices.retrieveMagentoURL(paymentId);
    }
    //PRODEV-456 | 11-02-2020 | Nadula Karunaratna
    //Retrieve faculty specific data from 'Faculty_Custom_Data__mdt' custom metadata type to display on the online application registration page
    @AuraEnabled
    public static List <Faculty_Custom_Data__mdt> retrieveFacultyData(String courseCode) {        
        return CourseLookupController.retrieveFacultyData(courseCode);        
    }
}