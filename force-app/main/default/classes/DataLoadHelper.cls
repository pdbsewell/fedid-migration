public with sharing class DataLoadHelper {
    
    public static void clearAllReferenceData(String createdById) {
        deleteVenues(createdById);
        deleteCourses(createdById);
        deleteCourseOfferings(createdById);   
    }

    public static void deleteVenues(String createdById) {
        List<Venue__c> venues = [SELECT ID,CreatedDate FROM Venue__c WHERE CreatedById = :createdById LIMIT 10000];
        delete venues;
    }

    public static void deleteCourses(String createdById) {
        List<Course__c> courses = [SELECT ID,CreatedDate FROM Course__c WHERE CreatedById = :createdById LIMIT 10000];
        delete courses;
    }

    public static void deleteCourseOfferings(String createdById) {
        List<Course_Offering__c> cos = [SELECT ID,CreatedDate FROM Course_Offering__c WHERE CreatedById = :createdById LIMIT 10000];
        delete cos;
    }

    public static void deleteACPs(String createdById, Integer batchChunkSize) {
        String batchScope = 'SELECT ID,CreatedDate FROM Application_Course_Preference__c WHERE CreatedById = \''+createdById+'\' AND ID != \'a200l0000004Qi2\'';
        database.executeBatch(new BatchDeleteRecords(batchScope), batchChunkSize);
    }

    public static void deleteApplications(String createdById, Integer batchChunkSize) {
        String batchScope = 'SELECT ID,CreatedDate FROM Application__c WHERE CreatedById = \''+createdById+'\' AND ID != \'a240l0000000EM1\'';
        database.executeBatch(new BatchDeleteRecords(batchScope), batchChunkSize);
    }

    public static void deleteEnquiries(String createdById, Integer batchChunkSize) {
        String batchScope = 'SELECT ID,CreatedDate FROM Case WHERE CreatedById = \''+createdById+'\' AND ID != \'5000l000000pkOh\'';
        database.executeBatch(new BatchDeleteRecords(batchScope), batchChunkSize);
    }

    public static void deleteContacts(String createdById, Integer batchChunkSize) {
        String batchScope = 'SELECT ID,CreatedDate FROM Contact WHERE CreatedById = \''+createdById+'\' AND ID != \'0030l0000033H5H\'';
        database.executeBatch(new BatchDeleteRecords(batchScope), batchChunkSize);
    }

    public static void deletePayments(String createdById, Integer batchChunkSize) {
        String batchScope = 'SELECT ID,CreatedDate FROM Payment__c WHERE CreatedById = \''+createdById+'\' AND ID != \'a2I0l0000001dUG\'';
        database.executeBatch(new BatchDeleteRecords(batchScope), batchChunkSize);
    }

    public static void processReferenceData(String createdById){
        
        List<Course_Offering__c> cos = [SELECT Id, Status__c, Legacy_Course_ID__c, Legacy_Venue_ID__c, Legacy_Time_ID__c, Legacy_Presenter_ID__c, Legacy_Cancellation__c, Part_of_the_Day__c FROM Course_Offering__c WHERE CreatedById = :createdById];
        List<String> legacyCourseIds = new List<String>();
        List<String> legacyVenueIds = new List<String>();

        for(Course_Offering__c co : cos) {
            legacyCourseIds.add(co.Legacy_Course_Id__c);
            legacyVenueIds.add(co.Legacy_Venue_Id__c);   
        }


        List<Course__c> courses = [SELECT Id, Legacy_Course_Id__c, Fee__c, APST_Standards__c, Hours_of_Attendance__c, Points__c, Level__c FROM Course__c WHERE Legacy_Course_Id__c IN :legacyCourseIds]; 
        Map<String, String> courseIds = new Map<String, String>();
        Map<String, Decimal> courseFee = new Map<String, Decimal>();
        for(Course__c course : courses) {
            courseIds.put(course.Legacy_Course_Id__c, course.Id);
            courseFee.put(course.Legacy_Course_Id__c, course.Fee__c);
            course.Concession_Fee__c = course.Fee__c;

            if(course.Hours_of_Attendance__c == null || course.Hours_of_Attendance__c == '')
                course.Hours_of_Attendance__c = '0';
            if(course.APST_Standards__c == null || course.APST_Standards__c == '')
                course.APST_Standards__c = '0';
            if(course.Points__c == null)
                course.Points__c = 0;
            if(course.Level__c == null || course.Level__c == '')
                course.Level__c = 'Non award';
        }
        update courses;


        List<Venue__c> venues = [SELECT Id, Legacy_Venue_Id__c FROM Venue__c WHERE Legacy_Venue_Id__c IN :legacyVenueIds];
        Map<String, String> venueIds = new Map<String, String>();
        for(Venue__c venue : venues) {
            venueIds.put(venue.Legacy_Venue_Id__c, venue.Id);
        }

        Map<String,String> presenters = DataLoadHelper.getPresenters();
        for(Course_Offering__c co : cos) {
            co.Venue__c = venueIds.get(co.Legacy_Venue_Id__c);
            co.Course__c = courseIds.get(co.Legacy_Course_Id__c);
            co.Fee__c = courseFee.get(co.Legacy_Course_Id__c);
            co.Concession_Fee__c = courseFee.get(co.Legacy_Course_Id__c);
            co.Part_of_the_Day__c = DataLoadHelper.getPartOfTheDay(co.Legacy_Time_ID__c);
            co.Course_Presenter_Name__c = presenters.get(co.Legacy_Presenter_ID__c);
            if(co.Legacy_Cancellation__c)
                co.Status__c = 'Cancelled';
                co.Reason_for_Cancellation__c = 'test';
        }
        update cos;
        
    }

    public static void processEnquiriesBatch(String createdById, String ownerId) {
        String query = 'SELECT Id, ContactId, Course__c, Preferred_Time__c, CreatedDate, Legacy_Course_ID__c, Legacy_Contact_ID__c, Legacy_Preferred_Time_ID__c, Legacy_Processed_Flag__c FROM Case WHERE CreatedById = \''+createdById+'\'';
        if(ownerId != null && ownerId != '') {
            query = query + 'AND OwnerId = '+'\''+ownerId+'\'';
        }
        database.executeBatch(new BatchProcessEnquiries(query),500);
    }

    public static void processApplicationsBatch(String createdById) {
        database.executeBatch(new BatchProcessApplications('SELECT Id, createdById, Legacy_Application_ID__c, Legacy_Enquiry_ID__c, Legacy_Course_Offering_ID__c, Legacy_Submitted_Date__c, Applicant__c, Applicant__r.MailingStreet, Applicant__r.MailingCity, Applicant__r.MailingState, Applicant__r.MailingPostalCode, Applicant__r.OtherStreet, Applicant__r.OtherCity, Applicant__r.OtherState, Applicant__r.OtherPostalCode, Applicant__r.Company__c  FROM Application__c WHERE CreatedById = \''+createdById+'\''),500);
    }

    public static void processContactsBatch(String createdById) {
        database.executeBatch(new BatchProcessContacts('SELECT Id, Email FROM Contact WHERE CreatedById = \''+createdById+'\''),10000);
    }

    // Retrieve country code by name
    public static String getPartOfTheDay(String identifiers) {
        if(identifiers == '1')
            return 'Day';
        else if(identifiers == '2')
            return 'Evening';
        else if(identifiers == '3')
            return 'Weekend';  
        else
            return '';
    }

    // Retrieve all presenters
    public static Map<String, String> getPresenters() {
        String queryString = queryBuilder('Presenter__c');
        List<Presenter__c> presenters = Database.Query(queryString);
        Map<String, String> outputMap = new Map<String, String>();
        if(presenters.size()>0){
            for(Presenter__c presenter : presenters) {
                outputMap.put(presenter.Name, presenter.Full_Name__c);
                System.debug('!@#$% NAME : ' + presenter.Name + ' | ' + 'Full Name : ' + presenter.Full_Name__c);   
            }
            System.debug('!@#$% List : ' + outputMap);
        }
        return outputMap;    
    }

    // Generic method that generates a query for all fields on any object
    public static String queryBuilder(String sobjName) {
        if(sobjName != null && sobjName != ''){
            String SobjectApiName = sobjName;
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
            String commaSepratedFields = '';
            for(Schema.SObjectField val : fieldMap.values()){
                if(val.getDescribe().isAccessible()){                    
                    if(commaSepratedFields == null || commaSepratedFields == ''){
                        commaSepratedFields = val.getDescribe().getName();
                    }else{
                        commaSepratedFields = commaSepratedFields + ', ' + val.getDescribe().getName();
                    }
                }                
            }
            
            String query = 'select ' + commaSepratedFields + ' from ' + SobjectApiName;
            return query;
        }        
        return null;
    }

}