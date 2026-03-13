/**
* @author Vineeth Batreddy
* @date 2017
* @group Professional Development
* @description This class acts as the controller for CourseLookup lightning component
* @revision 11-01-2020 | Nadula karunaratna | Added method 'retrieveFacultyData' to retrieve faculty specific data from 'Faculty_Custom_Data__mdt' custom metadata type to display on the online application registration page
* @revision 17-02-2020 | Nadula karunaratna | Updated method getCourseOffering with Course__r.Name for test classes PRODEV-490
* @revision 11 March 2021 - Cartick Sub - Filter Course Offerings on Registration Close Date where possible
*/
 
public class CourseLookupController {
    
    @AuraEnabled
    public static Course__c getCourseDetails(String courseCode){
        List<Course__c> course = [SELECT Id, Name, Course_Description__c FROM Course__c WHERE Name =:courseCode];
        if(course != null && course.size() >0){
            return course[0];
        }
        return null;
    }

    /** 
    @description Retrieves from the database the Course Offerings for the specified Course
    @param courseCode The parent Course code
    @return A list of Course Offerings open for registration
    @revision 11 March 2021 - Cartick Sub - Modify filters
    **/
    @AuraEnabled
    public static List<Course_Offering__c> getCourseOffering(String courseCode) {
        List<Course_Offering__c> courseOfferings = [
            SELECT Id,
            Name,
            Course__r.Name,
            Start_Date__c,
            Registration_Close_Date__c,
            End_Date__c,
            Fee__c,
            Concession_Fee__c,
            No_of_Sessions__c,
            Course_Code_F__c,
            Number_of_Remaining_Places__c,
            Course__r.Course_Description__c,
            Venue__r.Name,
            Status__c,
            Apply_GST__c,
            Part_of_the_Day__c,
            Customised_course_offering__c,
            Course__r.Managing_Faculty__c,
            Is_Selective__c 
            FROM Course_Offering__c 
            WHERE Course_Code_F__c = :courseCode AND (Status__c = 'Available' OR Status__c = 'Full' OR Status__c = 'EOI')
            ORDER BY Start_Date__c
        ];
        if(courseOfferings.isEmpty()) {
            return null;
        } else {
            /* If a Course Offering's Registration Close Date is null, check if the Start Date is after today
            If a Course has a Registration Close Date, check if it is on or after today */
            List<Course_Offering__c> courseOfferingsFilteredByRegClose = new List<Course_Offering__c>();
            for (Course_Offering__c courseOffering : courseOfferings) {
                if (courseOffering.Registration_Close_Date__c == null) {
                    if (courseOffering.Start_Date__c > Date.today()) {
                        courseOfferingsFilteredByRegClose.add(courseOffering);
                    }
                } else {
                    if (courseOffering.Registration_Close_Date__c >= Date.today()) {
                        courseOfferingsFilteredByRegClose.add(courseOffering);
                    }
                }
            }
            if (courseOfferingsFilteredByRegClose.isEmpty()) {
                return null;
            } else {
                return courseOfferingsFilteredByRegClose;
            }
        }
    }

    @AuraEnabled
    public static String retrieveFacultyEmail(String courseCode) {
        List<Course__c> coList = [select Managing_Faculty__c from Course__c where Name = :courseCode];

                System.debug('coList=='+coList);
        if (coList.size() > 0) {
            List<Faculty_Custom_Data__mdt> facultyEmailList = [Select Faculty_Email__c,Managing_Faculty__c from Faculty_Custom_Data__mdt where Managing_Faculty__c = :coList[0].Managing_Faculty__c];

            System.debug('facultyEmailList==' + facultyEmailList);
            String facultyEmail = 'edu.pdp@monash.edu';
            for (Faculty_Custom_Data__mdt email1 : facultyEmailList) {

                if (coList[0].Managing_Faculty__c.startsWithIgnoreCase(email1.Managing_Faculty__c)) {
                    facultyEmail =  email1.Faculty_Email__c;
                }
            }
            System.debug('facultyEmail=='+facultyEmail);
            return facultyEmail;

        } else {
            return null;
        }
    }

    //PRODEV-456 | 06-02-2020 | Nadula Karunaratna
    //Retrieve faculty specific data from 'Faculty_Custom_Data__mdt' custom metadata type to display on the online application registration page
    @AuraEnabled
    public static List <Faculty_Custom_Data__mdt> retrieveFacultyData(String courseCode) {
        List<Course__c> coList = [select Managing_Faculty__c from Course__c where Name = :courseCode];

        try{
            List<Faculty_Custom_Data__mdt> facultyDataList = [Select Faculty_Email__c,Managing_Faculty__c,Faculty_Phone_Label__c from Faculty_Custom_Data__mdt where Managing_Faculty__c = :coList[0].Managing_Faculty__c];

            if (coList[0].Managing_Faculty__c.startsWithIgnoreCase(facultyDataList[0].Managing_Faculty__c)) {
                return facultyDataList;
            }            

        }catch(Exception e) {
            System.debug('***** EXCEPTION FROM retrieveFacultyData***** - '+e.getMessage()+'**Line Number**'+e.getLineNumber());
        }

        return null;

    }    


}