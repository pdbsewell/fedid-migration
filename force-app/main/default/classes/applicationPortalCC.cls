/*******************************************************************************
* @author       Ant Custodio
* @date         30.Mar.2017         
* @description  controller class for applicationPortal.cmp lightning component
* @revision     Stefan Scheit (2018-09-15): Changed class to with sharing
*******************************************************************************/
public with sharing class applicationPortalCC {
    private static User userRecord;
    
    @AuraEnabled
    public static Map<String, Object> initDataLoad(Id applicationId)
    {
        Map<String, Object> mapResults = new Map<String, Object> ();
        // salutations
        mapResults.put('salutations', retrieveSalutations());
        
        // gender
		mapResults.put('genders', retrieveGender());
                
        // previous institutions
        mapResults.put('institutions', retrievePreviousInstitutions());
        // state list
        mapResults.put('state_list', retrieveState());      
        
        // country
        mapResults.put('countries', retrieveCountries());        
                
        retrieveUserDetails();
        
        // application
        mapResults.put('application', getCurrentApplication(applicationId));
        
        // previous submitted applications
        mapResults.put('previous_applications', getSubmittedApplications(userRecord.ContactId));
        return mapResults;
    }
    
    
    private static List<Application__c> getSubmittedApplications(Id contactId)
    {
        List<Application__c> listApps = [SELECT id 
                                         FROM Application__c 
                                         WHERE Applicant__c =: contactId AND Status__c = 'Submitted'];
        return listApps;
    }
    
    
    private static Application__c getCurrentApplication(Id appId)
    {   
        List<Application__c> listApps = [SELECT id, Campus_Location__c
                                         FROM Application__c 
                                         WHERE id =: appId];
        if(listApps.size() == 1)
        	return listApps[0];
        return null;
    }
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         30.Mar.2017         
    * @description  retrieve the community user's details
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static User retrieveUserDetails() {
        userRecord = [SELECT Id, 
                      FirstName, 
                      LastName, 
                      Email, 
                      App_Birthdate__c,
                      App_Salutation__c,
                      App_Gender__c,
                      MobilePhone,
                      Phone,
                      App_Citizenship__c,
                      App_Previous_Surname__c,
                      App_Previous_Monash_ID__c,
                      App_Previous_Monash_Institution__c,
                      App_Country_of_Residence__c,
                      App_Previously_Studied_at_Monash__c,
                      App_Residency_Status__c,
                      App_Home_Phone__c,
                      App_HasDisabilities__c,
                      App_Aboriginal_or_Torres_Strait_Islander__c,
                      Street,
                      City,
                      State,
                      PostalCode,
                      Country,
                      Other_Given_Name__c,
                      App_Citizenship_Type_Name__c,
                      App_Address_Type__c,
                      ContactId
                      FROM User
                      WHERE Id = :UserInfo.getUserId()];
        return userRecord;
    }
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         2.Apr.2017         
    * @description  updates the community contact
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static User updateUserRecord (User userRec, Id applicationId) {
        try {
            if (userRec.App_Address_Type__c == 'POSTAL') {
                userRec.Country = 'Australia';
            }
            
            if(applicationId != null)
            {                
            	Application__c app = getCurrentApplication(applicationId);
                String citizenshipCode = userRec.App_Residency_Status__c;
                if(!MyApplicationUtilities.isInternational(citizenshipCode))
                {
                    app.Is_Sponsored__c = false;
                    update app;
                }
            }
            update userRec;
            
        } catch (Exception e) {
            throw new AuraHandledException('Unable to update your details: ' + e.getMessage());
        }
        
        return userRec;
    }

    /*******************************************************************************
    * @author       Ant Custodio
    * @date         5.Apr.2017         
    * @description  removes the values when toggle checkbox is set to false
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static User removeValuesWhenUnticked (User userToUpdate) {
        if (!userToUpdate.App_Previously_Studied_at_Monash__c) {
            userToUpdate.App_Previous_Monash_ID__c = '';
            userToUpdate.App_Previous_Monash_Institution__c = ''; 
        }

        return userToUpdate;
    }
    
    /*******************************************************************************
    * @author       Ant Custodio
    * @date         30.Mar.2017         
    * @description  lets the user edit the details
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static void updateDetails () {
        //TODO
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of australian states
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveSalutations() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.App_Salutation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of gender
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveGender() {
        List<String> options = new List<String>();

        //TODO - need to change this
        options.add('Male');
        options.add('Female');
        options.add('Indeterminate / Intersex / Unspecified');   

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of citizenship
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveCitizenship() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.App_Citizenship__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of Country of Residence
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveResidence() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.App_Country_of_Residence__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of Residency Status
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveResidencyStatus() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.App_Residency_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of Previous Institutions
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrievePreviousInstitutions() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = User.App_Previous_Monash_Institution__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         3.May.2017         
    * @description  gives the list of Citizenship Type Options from the custom setting
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveCitizenshipTypeOptions() {
        String campusOfStudy = 'Australian campus and any location not listed below';
        List<String> options = new List<String>();
        for (Callista_Citizenship_Type__c citizenshipType: [    SELECT  Id, Name, Explanation__c, Campus_of_Study__c
                                                                FROM    Callista_Citizenship_Type__c 
                                                                WHERE   Campus_of_Study__c =: campusOfStudy
                                                                LIMIT   50 ]) {
            options.add(citizenshipType.Explanation__c);
        }
        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         3.May.2017         
    * @description  gives the list of Citizenship Type Options from the custom setting
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Callista_Citizenship_Type__c retrieveCitizenshipTypeByName(String ctName) {
        Callista_Citizenship_Type__c citizenshipRec = new Callista_Citizenship_Type__c();
        for (Callista_Citizenship_Type__c citizenshipType: [    SELECT  Id, Campus_of_Study__c,
                                                                        Explanation__c
                                                                FROM    Callista_Citizenship_Type__c 
                                                                WHERE   Name =: ctName
                                                                LIMIT   1 ]) {
            citizenshipRec = citizenshipType;
        }
        return citizenshipRec;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of Residency Status
    * @revision     cannot retrieve state from user
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveCampusOfStudyOptions() {
        List<String> options = new List<String>();

        //TODO - need to change this
        options.add('Australian campus and any location not listed below');
        options.add('Malaysian campus');
        options.add('South African campus');

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         4.Apr.2017         
    * @description  gives the list of Residency Status
    * @revision     cannot retrieve state from user
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveState() {
        List<String> options = new List<String>();

        /*Schema.DescribeFieldResult fieldResult = User.State.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }*/
        //TODO - need to change this
        options.add('Australian Capital Territory');
        options.add('New South Wales');
        options.add('Northern Territory');
        options.add('Queensland');
        options.add('South Australia');
        options.add('Tasmania');
        options.add('Victoria');
        options.add('Western Australia');

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         26.Apr.2017         
    * @description  gives the list of countries
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static List<String> retrieveCountries() {
        List<String> options = new List<String>();

        Schema.DescribeFieldResult fieldResult = Contact_Qualification__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            if (f.getLabel() != 'Australia') {
                options.add(f.getLabel());
            }
        }       

        return options;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         26.Apr.2017         
    * @description  returns to true if postcode entered is found
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Boolean findPostCodeNumber(String postCode) {
        Boolean isFound = false;
        
        for (Australian_Postcodes__c postCodeRec: [ SELECT Id, Name 
                                                    FROM Australian_Postcodes__c LIMIT 50000 ]) {
            if (postCodeRec.Name == postCode) {
                isFound = true;
                //break operation once found
                break;
            }
        }

        return isFound;
    }

    /*******************************************************************************
    * @author       Anterey Custodio
    * @date         12.Jun.2017         
    * @description  returns true if the user already has at least 1 submitted
                        application
    * @revision     
    *******************************************************************************/
    @AuraEnabled
    public static Boolean hasSubmittedApplication(String contactId) {
        Boolean hasSubmittedApp = false;
        
        //query on application. If there is at least one submitted, return true
        Integer submittedApps = 0;
        submittedApps = [   SELECT COUNT() 
                            FROM Application__c 
                            WHERE Applicant__c =: contactId 
                                AND Status__c = 'Submitted' ];
        if (submittedApps > 0) {
            hasSubmittedApp = true;
        }

        return hasSubmittedApp;
    }
}