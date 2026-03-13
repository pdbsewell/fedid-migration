/**
 * @author Inderpal Dhanoa
 * @date 20 Mar 2023
 * @group Test Class
 * @description Test class to cover the OnBoardAlumniControlle
 */
@isTest// (isParallel=true) Insert failed. First exception on row 0; first error: APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User:
public class OnBoardAlumniController_Test {
    public static final string JWTSecret = 'a1b2c3d4e5f6g7h8';

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         8.Nov.2021
    * @description  Test setup
    *******************************************************************************/
    @testSetup
    static void setup() {

        Id recType = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Student').getRecordTypeId();
        Date dtDOB = Date.today();
        Id proId =[select id from profile where name ='Customer Community General User'].id;
        Integer rnd = Integer.valueOf(Math.random()*9999);
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        List<Contact> lstContacts = new List<Contact>();
        List<User> lstUsers = new List<User>(); 
        List<PermissionSetAssignment> l_permSetList = new List<PermissionSetAssignment>();

        Contact cont1 = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'Contact', LastName= 'TempAlumni 1' , Birthdate = dtDOB.addDays(-500), Personal_Email__c = String.valueOf(rnd) + 'testuser@monash.edu', RecordTypeId = recType), false);
        lstContacts.add(cont1);
        Contact cont2 = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'Contact', LastName= 'TempAlumni 2', Birthdate = dtDOB.addDays(-800), Personal_Email__c = String.valueOf(rnd) + 'testuser2@monash.edu', RecordTypeId = recType), false);
        lstContacts.add(cont2);
        Contact cont3 = (Contact)TestDataFactory.createSObject(new Contact(FirstName = 'Contact', LastName= 'TempAlumni 3', Birthdate = dtDOB.addDays(-800), Personal_Email__c = String.valueOf(rnd) + 'testuser3@monash.edu', RecordTypeId = recType), false);
        lstContacts.add(cont3);
        insert lstContacts;

        // User creation

        User user2 = (User)TestDataFactory.createSObject(new User(Username = String.valueOf(rnd) + 'testuser2@monash.edu', 
                                                                    email = String.valueOf(rnd) + 'testuser2@monash.edu', 
                                                                    ContactId = cont2.id, LastName ='test', Alias ='test', isActive = true, TimeZoneSidKey ='Australia/Sydney', LocaleSidKey ='en_AU', 
                                                                    EmailEncodingKey ='ISO-8859-1', ProfileId = proId, LanguageLocaleKey ='en_US'), false);
        lstUsers.add(user2);
        
        User user3 = (User)TestDataFactory.createSObject(new User(Username = String.valueOf(rnd) + 'testuser3@monash.edu', 
                                                                    email = String.valueOf(rnd) + 'testuser3@monash.edu', 
                                                                    ContactId = cont3.id, LastName ='test', Alias ='test', isActive = true, TimeZoneSidKey ='Australia/Sydney', LocaleSidKey ='en_AU', 
                                                                    EmailEncodingKey ='ISO-8859-1', ProfileId = proId, LanguageLocaleKey ='en_US'), false);
        lstUsers.add(user3);

        System.runAs(thisUser) {
            Database.insert(lstUsers); // Avoid mixed DML error

            PermissionSet alumniUser = [SELECT Id, name FROM permissionSet where name = 'Alumni_Portal_Permission_Set']; 
            PermissionSet myAppUser = [SELECT Id, name FROM permissionSet where name = 'Customer_Community_My_Application'];
    
            PermissionSetAssignment permSet2 = (PermissionSetAssignment)TestDataFactory.createSObject(new PermissionSetAssignment(AssigneeId=user2.Id, PermissionSetId=alumniUser.Id), false);
            l_permSetList.add(permSet2);
            PermissionSetAssignment permSet3 = (PermissionSetAssignment)TestDataFactory.createSObject(new PermissionSetAssignment(AssigneeId=user3.Id, PermissionSetId=myAppUser.Id), false);
            l_permSetList.add(permSet3);
    
            insert l_permSetList;
        }

    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.validateContactInfo().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void validateContactInfo_FreshUserTest(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id,Name FROM Contact WHERE Name = 'Contact TempAlumni 1' ORDER BY createdDate DESC LIMIT 1];
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));
        Date dtDOB = Date.today();
        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.ContactWrapper reLinks = OnBoardAlumniController.validateContactInfo(encodedPayload, String.valueOf(dtDOB.addDays(-500)), 'dummyToken');
        
        Test.stopTest();

        // THEN:  
        System.assertEquals(reLinks.s_userStatus, 'FreshUser');
    }


    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.validateContactInfo().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void validateContactInfo_AlumniUserTest(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id,Name FROM Contact WHERE Name = 'Contact TempAlumni 2' ORDER BY createdDate DESC LIMIT 1];
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));

        Date dtDOB = Date.today();
        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.ContactWrapper reLinks = OnBoardAlumniController.validateContactInfo(encodedPayload, String.valueOf(dtDOB.addDays(-800)), 'dummyToken');
        
        Test.stopTest();

        // THEN:  
        System.assertEquals(reLinks.s_userStatus, 'AlumniUser');
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.validateContactInfo().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void validateContactInfo_NonAlumniUserTest(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id,Name FROM Contact WHERE Name = 'Contact TempAlumni 3' ORDER BY createdDate DESC LIMIT 1];
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));
        Date dtDOB = Date.today();
        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.ContactWrapper reLinks = OnBoardAlumniController.validateContactInfo(encodedPayload, String.valueOf(dtDOB.addDays(-800)), 'dummyToken');
        
        Test.stopTest();

        // THEN:  
        System.assertEquals(reLinks.s_userStatus, 'NonAlumniUser');
    } 


    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.setupAlumniUser().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void setupAlumniUser_Test(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id, Firstname, LastName, Personal_Email__c, BirthDate FROM Contact WHERE Name = 'Contact TempAlumni 1' ORDER BY createdDate DESC LIMIT 1];
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));
        
        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.setupAlumniUser(encodedPayload, relCont[0].FirstName, relCont[0].LastName, String.valueOf(relCont[0].Personal_Email__c), String.valueOf(relCont[0].BirthDate));
        
        Test.stopTest();

        // THEN:  
        List<User> relUser = [SELECT Id,UserName FROM User WHERE ContactId = :relCont[0].Id];
        System.assertEquals(relUser[0].UserName, relCont[0].Personal_Email__c);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.setupAlumniUser().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void createEnquiry_Test(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id, Firstname, LastName, Personal_Email__c, BirthDate FROM Contact WHERE Name = 'Contact TempAlumni 1' ORDER BY createdDate DESC LIMIT 1];
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));
        
        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.createEnquiry(encodedPayload, String.valueOf(relCont[0].BirthDate));
        
        Test.stopTest(); 

        // THEN:  
        List<Case> relCase = [SELECT Id,Description FROM Case WHERE ContactId = :relCont[0].Id];
        System.assertEquals('Date of birth validation failed when trying to activate alumni portal account', relCase[0].Description);
    }

    /*******************************************************************************
    * @author       Inderpal Dhanoa
    * @date         10/03/2023
    * @description  Test Method for OnBoardAlumniController.extendUserAsAlumni().
    * @revision     1.0
    *******************************************************************************/
    @isTest
    public static void extendUserAsAlumni_Test(){ 
        // GIVEN:   
        List<Contact> relCont = [SELECT Id, Firstname, LastName, BirthDate FROM Contact WHERE Name = 'Contact TempAlumni 3' ORDER BY createdDate DESC LIMIT 1]; 
        String jwt = OnBoardAlumniController.generateJWT(OnBoardAlumniController_Test.JWTSecret,relCont[0].Id);
        String encodedPayload = EncodingUtil.base64Encode(Blob.valueOf(jwt));

        Test.startTest();
        // WHEN:  
        OnBoardAlumniController.extendUserAsAlumni(encodedPayload, String.valueOf(relCont[0].BirthDate));
        
        Test.stopTest();

        // THEN:  
        PermissionSet alumniPermSet = [SELECT Id, name FROM permissionSet where name = 'Alumni_Portal_Permission_Set'];
        User updatedUser = [SELECT Id FROM User WHERE ContactId = :relCont[0].Id];

        List<PermissionSetAssignment> lstAssignedPermSet = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =:updatedUser.Id AND  PermissionSetId = :alumniPermSet.Id];

        System.assert(lstAssignedPermSet.size() > 0, 'Alumni Perm Set not Assigned');
    }
}