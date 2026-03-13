/**
* @author Nadula Karunaratna
* @date 15-01-2020
* @group Professional Development
* @description Report should eliminate all acps and enquiries of registered students for the same course, and show all unsuccessful acps and enquiries
* @revision Nadula Karunaratna | 10-08-2018 | Modified to read login user Role and idenify faculty from it, and filter data using Faculty
* @revision Nadula Karunaratna | 15-01-2020 | Updated class header comment
* @revision Cartick Sub - 18 May 2021 - PRODEV-686 - Add MCPD to logic
* @revision Vinothraja - 04 Mar 2025 - EPCP-4368 - Converted getLoginUserFaculty() to return faculty name from a Map, to solve PMD issues in Test class
*/
 
 public class Console_ReportEnquiryNotEnrolled { 

    public String getCriteria {get;set;}    
    public List<String> criteriaArray {get;set;}
    public Map<String, String> mapRoleFaculty = new Map<String, String> {
        'Education Short Courses Team' =>'Faculty of Education',
        'BusEco Short Courses Team' => 'Faculty of Business & Economics',
        'Medicine Short Courses Team' => 'Faculty of Medicine, Nursing & Health Sciences',
        'Arts Short Courses Team' => 'Faculty of Arts',
        'MSDI Short Courses Team' => 'Monash Sustainable Development Institute',
        'Monash Centre for Professional Development' => 'Monash Centre for Professional Development'
    };
    
    // Criteria
    public String fromDate {get;set;}
    public String toDate {get;set;}
    public String courseCode {get;set;}
    public String courseLocation {get;set;}
    public String marketingOptOut {get;set;}
    public String userFacultyName {get;set;}

    // CSV Headers
    public string header {get;set;}

    public Console_ReportEnquiryNotEnrolled(){
        header = 'firstName,lastName,mailingStreet1,mailingStreet2,mailingStreet3,mailingCity,mailingState,mailingPostalCode,phone,Mobile,email,email Opt Out,Course Location,Course Code';        
    }

    public String getLoginUserFaculty(){
        String uRoleId = UserInfo.getUserRoleId();
        UserRole uRole = [select Name from UserRole where id=:uRoleId]; 

        return mapRoleFaculty.containsKey(uRole.Name) ? mapRoleFaculty.get(uRole.Name) : 'All Faculties';
    }

    public class ReportContact {
        public String firstName {get; set;}
        public String lastName {get; set;}        
        public String mailingStreet1 {get; set;}
        public String mailingStreet2 {get; set;}
        public String mailingStreet3 {get; set;}        
        public String mailingCity {get; set;}
        public String mailingState {get; set;}
        public String mailingPostalCode {get; set;}
        public String phone {get; set;}
        public String mobilePhone {get; set;}
        public String email {get; set;}
        public String emailOptOut {get; set;}
        public String courseLocation {get; set;}
        public String courseCode {get; set;}
    }

    public List<ReportContact> reportContactList {get; set;}
    public List<ReportContact> reportContactList2 {get; set;}
    public Set<ReportContact> emailReportContactSet {get; set;}

    public void processData(){

        criteriaArray = new List<String>();
        criteriaArray = getCriteria.split('\\|');
        fromDate = criteriaArray[0]+'T00:00:00Z';
        toDate = criteriaArray[1]+'T00:00:00Z';
        courseCode = criteriaArray[2];
        courseLocation = criteriaArray[3];
        marketingOptOut = criteriaArray[4];
                
        // Console_ReportEnquiryNotEnrolled.page breaks the faculty name due to ampersand
        if(criteriaArray[5] == 'Faculty of Medicine, Nursing ') 
            userFacultyName = 'Faculty of Medicine, Nursing & Health Sciences';
        else if(criteriaArray[5] == 'Faculty of Business ') 
            userFacultyName = 'Faculty of Business & Economics';
        else
            userFacultyName = criteriaArray[5];
        
        // ACP filter        
        String soqlFilterACP = 'AND createdDate >= '+fromDate+' AND createdDate <= '+toDate;
        soqlFilterACP += (courseCode != 'null' ? ' AND Course__r.Name = \'' + courseCode + '\'' : '');
        soqlFilterACP += (courseLocation != 'null' ? ' AND Course_Offering__r.Campus__c = \'' + courseLocation + '\'' : '');
        soqlFilterACP += (marketingOptOut != 'null' ? ' AND Applicant__r.HasOptedOutOfEmail = ' + marketingOptOut : '');
        soqlFilterACP += (userFacultyName != 'All Faculties' ? ' AND Managing_Faculty_Text__c = \'' + userFacultyName + '\'' : '');        

        // Case filter
        String soqlFilterCase = ' AND createdDate >= '+fromDate+' AND createdDate <= '+toDate;
        soqlFilterCase += (courseCode != 'null' ? ' AND Course__r.Name = \'' + courseCode + '\'' : '');
        soqlFilterCase += (courseLocation != 'null' ? ' AND Course_Location__c = \'' + courseLocation + '\'' : '');
        soqlFilterCase += (marketingOptOut != 'null' ? ' AND Contact.HasOptedOutOfEmail = ' + marketingOptOut : '');
        soqlFilterCase += (userFacultyName != 'All Faculties' ? ' AND Course_Managing_Faculty__c = \'' + userFacultyName + '\'' : '');

        reportContactList = new List<ReportContact>();
        reportContactList2 = new List<ReportContact>();

        // EnqIDs of Applied - Registered
        SET<String> setACPRegisteredEnqID = new SET<String>();
        SET<String> setACPRegisteredEmail = new SET<String>();
        String soqlQuery1 = 'SELECT Application__r.enquiry_number__c, Applicant__r.email FROM Application_Course_Preference__c WHERE (Application__r.enquiry_number__r.recordtype.Name = \'Professional Development\' OR Application__r.enquiry_number__r.Category_Level_1__c = \'Professional Development\') AND status__c = \'Registered\' ' + soqlFilterACP + ' LIMIT 10000';
        List<Application_Course_Preference__c> myquerydata1 = Database.query(soqlQuery1);
        for (Application_Course_Preference__c acp : myquerydata1){
            setACPRegisteredEnqID.add(acp.Application__r.enquiry_number__c);
            setACPRegisteredEmail.add(acp.Applicant__r.email);
        }

        // EnqIDs of Applied - NOT Registered
        SET<String> setACPNOTRegisteredEnqID = new SET<String>();
        SET<String> setACPNOTRegisteredEmail = new SET<String>();
        String soqlQuery2 = 'SELECT Id, Application__r.enquiry_number__c, Applicant__r.firstName, Applicant__r.lastName, Applicant__r.MailingStreet, Applicant__r.mailingCity, Applicant__r.mailingState, Applicant__r.mailingPostalCode, Applicant__r.phone, Applicant__r.mobilePhone, Applicant__r.email, Applicant__r.HasOptedOutOfEmail, Course_Offering__r.Campus__c, Course__r.Name FROM Application_Course_Preference__c WHERE (Application__r.enquiry_number__r.recordtype.Name = \'Professional Development\' OR Application__r.enquiry_number__r.Category_Level_1__c = \'Professional Development\') AND status__c != \'Registered\' AND Applicant__r.email NOT IN : setACPRegisteredEmail ' + soqlFilterACP + ' LIMIT 10000';
        List<Application_Course_Preference__c> myquerydata2 = Database.query(soqlQuery2);
        for (Application_Course_Preference__c acp : myquerydata2){
            
            setACPNOTRegisteredEnqID.add(acp.Application__r.enquiry_number__c);
            setACPNOTRegisteredEmail.add(acp.Applicant__r.email);
            
            ReportContact a = new ReportContact();
            a.firstName = acp.Applicant__r.firstName;
            a.lastName = acp.Applicant__r.lastName;

            if(acp.Applicant__r.MailingStreet != null){
                
                String cleanedMailingStreet = acp.Applicant__r.MailingStreet;            
                cleanedMailingStreet = cleanedMailingStreet.replace('\r\n', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace('\n', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace('\r', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace(',', ':::');

                String[] lstMailingStreet = new String[3];
                lstMailingStreet = cleanedMailingStreet.split(':::');
                if(lstMailingStreet.size() == 1){ a.mailingStreet1 = lstMailingStreet[0]; }
                else if(lstMailingStreet.size() == 2){ 
                    a.mailingStreet1 = lstMailingStreet[0]; 
                    a.mailingStreet2 = lstMailingStreet[1]; 
                } else if(lstMailingStreet.size() == 3){ 
                    a.mailingStreet1 = lstMailingStreet[0]; 
                    a.mailingStreet2 = lstMailingStreet[1]; 
                    a.mailingStreet3 = lstMailingStreet[2]; 
                }
            }

            a.mailingCity = acp.Applicant__r.mailingCity;
            a.mailingState = acp.Applicant__r.mailingState;
            a.mailingPostalCode = acp.Applicant__r.mailingPostalCode;
            a.phone = acp.Applicant__r.phone;
            a.mobilePhone = acp.Applicant__r.mobilePhone;
            a.courseLocation = acp.Course_Offering__r.Campus__c;
            a.courseCode = acp.Course__r.Name;  
            a.email = acp.Applicant__r.email;
            a.emailOptOut = (acp.Applicant__r.HasOptedOutOfEmail==true ? 'Yes' : 'No');
            reportContactList.add(a);                        
           
        }

        // EnqIDs of All Applied (With ACP, regardless of ACP status)
        SET<String> setAllAppliedEnqID = new SET<String>();
        setAllAppliedEnqID.addAll(setACPRegisteredEnqID);
        setAllAppliedEnqID.addAll(setACPNOTRegisteredEnqID);

        // EnquIDs of All NOT Applied    
        SET<String> setAllNOTAppliedEnqID = new SET<String>();        
        String soqlQuery3 = 'SELECT Id, Contact.firstName, Contact.lastName, Contact.MailingStreet, Contact.mailingCity, Contact.mailingState, Contact.mailingPostalCode, Contact.phone, Contact.mobilePhone, Contact.email, Contact.HasOptedOutOfEmail, Course_Location__c, Course__r.Name FROM Case WHERE (RecordType.Name = \'Professional Development\' OR Category_Level_1__c = \'Professional Development\') AND Id NOT IN : setAllAppliedEnqID AND Contact.email NOT IN : setACPRegisteredEmail AND Contact.email NOT IN : setACPNOTRegisteredEmail' + soqlFilterCase + ' LIMIT 10000';
        List<Case> myquerydata3 = Database.query(soqlQuery3);
        for (Case enq : myquerydata3){
            setAllNOTAppliedEnqID.add(enq.Id);
                    
            ReportContact b = new ReportContact();
            b.firstName = enq.Contact.firstName;
            b.lastName = enq.Contact.lastName;

            if(enq.Contact.MailingStreet != null){

                String cleanedMailingStreet = enq.Contact.MailingStreet;            
                cleanedMailingStreet = cleanedMailingStreet.replace('\r\n', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace('\n', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace('\r', ':::');
                cleanedMailingStreet = cleanedMailingStreet.replace(',', ':::');

                String[] lstMailingStreet = new String[3];
                lstMailingStreet = cleanedMailingStreet.split(':::');
                if(lstMailingStreet.size() == 1){ b.mailingStreet1 = lstMailingStreet[0]; }
                else if(lstMailingStreet.size() == 2){ 
                    b.mailingStreet1 = lstMailingStreet[0]; 
                    b.mailingStreet2 = lstMailingStreet[1]; 
                } else if(lstMailingStreet.size() == 3){ 
                    b.mailingStreet1 = lstMailingStreet[0]; 
                    b.mailingStreet2 = lstMailingStreet[1]; 
                    b.mailingStreet3 = lstMailingStreet[2]; 
                }
            }
            
            b.mailingCity = enq.Contact.mailingCity;
            b.mailingState = enq.Contact.mailingState;
            b.mailingPostalCode = enq.Contact.mailingPostalCode;
            b.phone = enq.Contact.phone;
            b.mobilePhone = enq.Contact.mobilePhone;            
            b.courseLocation = enq.Course_Location__c;
            b.courseCode = enq.Course__r.Name;
            b.email = enq.Contact.email;  
            b.emailOptOut = (enq.Contact.HasOptedOutOfEmail==true ? 'Yes' : 'No');
            reportContactList.add(b);

        }   
 
        // Remove duplicates
        Map<String, ReportContact> emailReportContactMap = new  Map<String , ReportContact>();

        // Initialize map
        for(ReportContact reportContactObj : reportContactList){
            emailReportContactMap.put(reportContactObj.email, reportContactObj);
        }

        for(ReportContact reportContactObj: emailReportContactMap.values()) {
            reportContactList2.add(reportContactObj);
        }
    }
}