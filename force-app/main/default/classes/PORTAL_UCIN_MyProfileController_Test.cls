/**
* Test class for My Profile Controller
*
* @author:  Zachary Soohoo
* @version: 1.0
* @since:   1.0
*/
@isTest(isParallel=false)
public class PORTAL_UCIN_MyProfileController_Test {   
    static public User systemUser;
    static public User communityUser;
    static public Contact con;
    static public Account acct;
    static public Affiliation__c aff;
    static public Address__c address2;
    //map objects
    static public Map<String, Email__c> emailMap;
    static public Map<String, Phone__c> phoneMap;
    static public Map<String, Social__c> socialMap;
    static Map<String, Email__c> originalMailMap;
    static Map<String, Phone__c> originalPhoneMap;
    static Map<String, Social__c> originalSocialMap;
    static Address__c originalAddress;
    static Address__c originalBusinessAddress;
    
    @testSetup static void setupData() {
        UserRole ur = new UserRole(Name = 'CEO');
        insert ur;
        
        Id systemProfileId = [select id from profile where name=: 'System Administrator'].id;
        systemUser = new User(alias = 'sysUser',
                                 email = 'testSystemUsermig123@test.com',
                                 emailencodingkey='UTF-8',
                                 lastname = 'Superman',
                                 languagelocalekey='en_US',
                                 localesidkey='en_US',
                                 profileid = systemProfileId,
                                 IsActive = true,
                                 timezonesidkey='America/Los_Angeles',
                                 username = 'testSystemUsermig123@test.com',
                                 UserRoleId = ur.Id);
        insert systemUser;
        systemUser.email = 'testSystemUsermig113@test.com';
        update systemUser;
        List<User> Userlst = new List<User>();
        Userlst.add(systemUser);
		UserServices.UpdateSobjectsQueueable apc = new UserServices.UpdateSobjectsQueueable(Userlst);
          Test.startTest();
            System.enqueueJob(apc);
          Test.stopTest();
        System.assertEquals(systemUser.email, 'testSystemUsermig113@test.com');

        System.runAs(systemUser) {
            acct = new Account();
                acct.Name = 'Household';
            insert acct;

            String city = 'Irvine';
            String state = 'CA';
            String zip = '92602';
            String country = 'USA';

            con = new Contact();
            con.AccountId = acct.Id;
            con.Last_Name__c = 'Last';
            con.First_Name__c = 'First';
            con.ucinn_ascendv2__Contact_Type__c = 'Current Student';
            con.ucinn_ascendv2__Preferred_Class_Year__c = '2010';
            con.Birthdate = Date.newInstance(1988, 8, 12);
            con.ucinn_ascendv2__Donor_ID__c = '123456789';
            con.Email = 'personal@test.com';
            con.Personal_Email__c = 'personal@test.com';
            con.Phone = '123-456-7890';
            con.ucinn_ascendv2__Personal_Email__c = 'personal@test.com';
            con.ucinn_ascendv2__Business_Email__c = 'business@test.com';
            con.ucinn_ascendv2__Other_Email__c = 'other@test.com';
            con.ucinn_ascendv2__Preferred_Email_Type__c = 'Personal';
            con.MobilePhone = '123-456-7890';
            con.HomePhone = '123-456-7891';
            con.ucinn_ascendv2__Preferred_Phone_Type__c = 'Mobile';
            con.MailingStreet = '230 Commerce #123';
            con.MailingCity = city;
            con.MailingState = state;
            con.MailingPostalCode = zip;
            con.MailingCountry = country;
            con.OtherStreet = '230 Commerce #456';
            con.OtherCity = city;
            con.OtherState = state;
            con.OtherPostalCode = zip;
            con.OtherCountry = country;
            con.ucinn_ascendv2__Preferred_Address_Type__c = 'Mailing';
            con.Volunteer_Status__c = 'Not Active - Withdrawn';
            con.Volunteer_at_Monash__c = true;
            insert con;

            
            //phone object tied to con
            Phone__c phone = new Phone__c();
            phone.Contact__c = con.Id;
            phone.Classification__c = 'Private';
            phone.Name = '555-555-5555';
            insert phone;
            
            //email object tied to con
            Email__c email = new Email__c();
            email.Classification__c = 'Private';
            email.Contact__c = con.Id;
            email.Name = 'test1234632@gmail.com';
            insert email;
            
            
            //social handles tied to con
            Social__c social2 = new Social__c();
            social2.Contact__c = con.Id;
            social2.Type__c = 'LinkedIn';
            social2.Name = 'Test handle';
            social2.Classification__c = 'Private';
            insert social2;

            Account institution = new Account();
            String facultyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Faculty').getRecordTypeId();
            institution.RecordTypeId = facultyRecordTypeId;
            institution.Name = 'Test Faculty';
            insert institution;
            
            Contact_Qualification__c qual = new Contact_Qualification__c();
            qual.Contact__c = con.Id;
            qual.Faculty__c = institution.Id;
            qual.Other_Qualification__c = 'Test Qualification';
            qual.Obtained_Status__c = 'MONASH-OBTAINED';
            qual.Institution_Name__c = 'Monash University';
            insert qual;

            Account company = new Account();
            company.Name = 'Salesforce';
            insert company;
            
            String employeeRecordTypeId = Schema.SObjectType.Affiliation__c.getRecordTypeInfosByDeveloperName().get('Employee').getRecordTypeId();
            //Added affiliation__c 10-3-19 for modified class
            aff = new Affiliation__c();
            //fields to match query
            aff.Is_Active__c = true;
            aff.Is_Primary__c = true;
            aff.Contact__c = con.Id;
            aff.RecordTypeId = employeeRecordTypeId;
            //additional fields to be found from query
            aff.Position__c = 'Test Position';
            aff.Account__c = acct.id;
            aff.Start_Date__c = system.today();
            insert aff;

            Id profileId = [select id from profile where name=: 'Customer Community General User'].id;
            communityUser = new User(alias = 'comUser',
                                    email = 'testCommunityUsermig123@test.com',
                                    emailencodingkey='UTF-8',
                                    lastname = 'Batman',
                                    languagelocalekey='en_US',
                                    localesidkey='en_US',
                                    profileid = profileId,
                                    IsActive = true,
                                    ContactId = con.Id,
                                    timezonesidkey='America/Los_Angeles',
                                    username = 'testCommunityUsermig123@test.com');
            insert communityUser;

            Set<String> s_AlumniPortalPermissionSet = new Set<String>();
            String s_labelAlumniPermSet = String.valueOf(Label.Alumni_Portal_Permission_Set);
            String s_labelManageAlumniPermSet = String.valueOf(Label.Manage_Alumni_Portal_Users);

            for(String permSet : s_labelAlumniPermSet.split(';')){
                s_AlumniPortalPermissionSet.add(permSet);
            }

            List<PermissionSet> l_permSet = [SELECT Id FROM PermissionSet WHERE Name IN :s_AlumniPortalPermissionSet];
            List<PermissionSetAssignment> l_permSetAssign = new List<PermissionSetAssignment>();

            if(!l_permSet.isEmpty()){
                
                for(PermissionSet permSet : l_permSet){
                    PermissionSetAssignment alumniPermSetAssign = new PermissionSetAssignment(PermissionSetId = permSet.Id, AssigneeId = communityUser.Id);
                    l_permSetAssign.add(alumniPermSetAssign);
                }
            }

            l_permSet = [SELECT Id FROM PermissionSet WHERE Name = :s_labelManageAlumniPermSet];

            User systemUser = [SELECT Id, username FROM User WHERE username = 'testSystemUsermig123@test.com'];

            PermissionSetAssignment alumniPermSetAssign = new PermissionSetAssignment(PermissionSetId = l_permSet[0].Id, AssigneeId = systemUser.Id);
            l_permSetAssign.add(alumniPermSetAssign);

            insert l_permSetAssign; 

            System.debug('communityUser: ' + communityUser.Id);
            System.debug('communityUser.con.Id: ' + communityUser.ContactId);
        }
    }
    
    
    @IsTest
    static void misc()
    {
        User comUser = [SELECT ID,IsPortalEnabled, ContactId FROM User WHERE Username = 'testCommunityUsermig123@test.com'];
        
        Id contactId = comUser.ContactId;
        
        List<Phone__c> phonesToSave = new List<Phone__c>();
        Phone__c phone = new Phone__c();
        phone.Contact__c = contactId;
        phone.Classification__c = 'Private';
        phone.Name = '555-555-5558';
        Phone__c phone2 = phone.clone(false, true);
        phone2.Type__c = 'Mobile';
        phone2.Name = '555-555-5556';
        Phone__c phone3 = phone.clone(false, true);
        phone.Classification__c = 'Business';
        phone3.Type__c = 'Landline';
        phone3.Name = '555-555-5557';
         
        phonesToSave.add(phone);
        phonesToSave.add(phone2);
        phonesToSave.add(phone3);
        insert phonesToSave;
            
            
        List<Address__c> addressesToAdd = new List<Address__c>();
            
        Address__c address = new Address__c();
        address.Contact__c = contactId;
        address.City__c = 'Irvine';
        address.Street_Name__c = 'Test1 Street';
        address.Post_Code__c = '92602';
        address.Type__c = 'Mailing';
        address.Classification__c = 'Private';
        address.Is_Primary__c = true;
            
        Address__c businessAddress = new Address__c();
        businessAddress.Contact__c = contactId;
        businessAddress.City__c = 'Springfield';
        businessAddress.Street_Name__c = ' 743 Evergreen Terrace';
        businessAddress.Post_Code__c = '92602';
        businessAddress.Classification__c = 'Business';
            
        addressesToAdd.add(address);
        addressesToAdd.add(businessAddress);
        insert addressesToAdd;
        
        test.startTest();
        
        
        
        //PORTAL_UCIN_MyProfileControllerTest.setupData();
        system.runAs(comUser) {          
            PORTAL_UCIN_MyProfileController.SERVER_getVolunteerPreferences(); //returns null           
            Map<String, Object> userInfo = PORTAL_UCIN_MyProfileController.SERVER_getUserInfo();
            system.debug('userinfoo '+userInfo);
            Object convertedType = (Object) System.Json.deserialize(System.Json.serialize(userInfo.get('contact')), Contact.Class);
            Contact constituentRec = (Contact) convertedType;
            System.assertEquals(constituentRec.Volunteer_at_Monash__c, true);
            Map<String, String> affilMap = (Map<String, String>) userInfo.get('affilMap');
            System.assertEquals('Test Position', affilMap.get('position'));
            System.assertEquals(constituentRec.Contact_Qualifications__r[0].Faculty__r.Name, 'Test Faculty');
            
            PORTAL_UCIN_MyProfileController.SERVER_getVolunteerPreferences();
            String status = 'Active';
            String roleValues ='Mentor';
            String skillValues = 'CEO & General Management';
            String areaValues = 'Art and Design';
            PORTAL_UCIN_MyProfileController.SERVER_saveVolunteerPreferences(status, roleValues, skillValues, areaValues);
            Contact updatedContact = [SELECT Id, Volunteer_Status__c FROM Contact WHERE Id = :constituentRec.Id]; 
            System.assertEquals(updatedContact.Volunteer_Status__c, 'Active');
            PORTAL_UCIN_MyProfileController.getUserInformation(contactId);
            System.assertNotEquals(null, contactId);
            System.assertEquals(comUser.IsPortalEnabled, true);
        } 
        
        test.stopTest();
    }

    @IsTest
    static void getUserInformation_TEST(){
        // given : The Logged in User has the Manage Alumni Permission Set assigned to it
        User systemUser = [SELECT Id, IsPortalEnabled, ContactId FROM User WHERE Username = 'testSystemUsermig123@test.com'];
        
        test.startTest();

        system.runAs(systemUser) { 
            User commUser = [SELECT Id, IsPortalEnabled, ContactId FROM User WHERE Username = 'testCommunityUsermig123@test.com'];
        
            // when : The get User Information is trigerred
            PORTAL_UCIN_MyProfileController.UserWrapper obj_UserWrapper = PORTAL_UCIN_MyProfileController.getUserInformation(commUser.contactId);

            // when : The render button should be visible to the User
            System.assertEquals(obj_UserWrapper.b_renderReActivationButton, true);
        }

        test.stopTest();
    }
    
    @IsTest
    static void SERVER_saveProfileInformationTEST()
    {
        User comUser = [SELECT ID FROM User WHERE Username = 'testCommunityUsermig123@test.com'];
        Contact c = [SELECT ID, First_Name__c, Last_Name__c, Salutation_ERDA__c, Suffix FROM Contact WHERE Email = 'personal@test.com' LIMIT 1];

        Name__c preferredName = new Name__c(First_Name__c = c.First_Name__c, Last_Name__c = c.Last_Name__c, Salutation__c = c.Salutation_ERDA__c, Suffix__c = 'Ms');
        
        Map<String, String> preferredMap = new Map<String, String>();
        preferredMap.put('email', 'personal');
        preferredMap.put('phone', 'work');
        
        Map<String, Email__c> mailMap = new Map<String, Email__c>();
        Email__c email = new Email__c();
        email.Classification__c = 'Private';
        email.Contact__c = c.Id;
        email.Name = 'test1234633@gmail.com';
        mailMap.put('Personal', email);
        Email__c email2 = email.clone(false, true);
        email2.Name = 'test1254634@gmail.com';
        mailMap.put('Business', email2);

        
        Map<String, Phone__c> pMap = new Map<String, Phone__c>();
        Phone__c phone = new Phone__c();
        phone.Contact__c = c.Id;
        phone.Classification__c = 'Private';
        phone.Name = '555-555-5556';
        Phone__c phone1 = phone.clone(false, true);
        Phone__c phone2 = phone.clone(false, true);
        phone1.Name = '6666666666';
        phone2.Name = '7777777777';
        pMap.put('Home', phone);
        pMap.put('Work', phone1);
        pMap.put('Mobile', phone2);

        

        Map<String, Social__c> sMap = new Map<String, Social__c>();
        Social__c social = new Social__c();
        social.Contact__c = c.Id;
        social.Type__c = 'LinkedIn';
        social.Name = 'Test handle2';
        social.Classification__c = 'Private';
        Social__c social2 = social.clone(false, true);
        social2.Name = 'Test handle 3';
        sMap.put('LinkedIn', social);
        sMap.put('Twitter', social2);

        
        
        Address__c address = new Address__c();
        address.Contact__c = c.Id;
        address.City__c = 'Irvine';
        address.Street_Name__c = 'Test1 Street';
        address.Post_Code__c = '92602';
        address.Type__c = 'Mailing';
        address.Classification__c = 'Private';
        
        Address__c businessAddress = new Address__c();
        businessAddress.Contact__c = c.Id;
        businessAddress.City__c = 'Springfield';
        businessAddress.Street_Name__c = ' 743 Evergreen Terrace';
        businessAddress.Post_Code__c = '92602';


        Affiliation__c origAffiliation = [SELECT Id, Position__c, End_Date__c, Is_Active__c, Is_Primary__c, Account__r.Name, Account__r.Industry FROM Affiliation__c WHERE Contact__c = :c.Id LIMIT 1];
        
        Map<String, String> origAffilMap = new Map<String, String>();
        origAffilMap.put('position', origAffiliation.Position__c);
        origAffilMap.put('orgName', origAffiliation.Account__r.Name);
        origAffilMap.put('orgIndustry', 'Nuclear Power');
        
        Map<String, String> affilMap = new Map<String, String>();
        affilMap.put('position', 'Tester');
        affilMap.put('orgName', 'Profile Test Class');
        affilMap.put('orgIndustry', 'Nuclear Power');
        
        createOrigDetails(c.Id);

        test.startTest();

        
        system.runAs(comUser) {
            PORTAL_UCIN_MyProfileController.SERVER_saveSetupInformation(comUser);
            
            PORTAL_UCIN_MyProfileController.SERVER_saveProfileInformation(c, preferredMap, preferredName, mailMap, pMap, sMap, 
                                                                          originalMailMap, originalPhoneMap, originalSocialMap, 
                                                                          originalAddress, address, originalBusinessAddress, businessAddress,
                                                                          origAffiliation, origAffilMap, affilMap);

            //Contact savedContact = [SELECT ID, Suffix FROM Contact WHERE Id = :c.Id];
            Name__c savedName = [SELECT Id, Suffix__c FROM Name__c WHERE Contact__c = :c.Id AND Is_Active__c = true AND Is_Primary__c = true];
            Affiliation__c savedAff = [SELECT Id, Position__c FROM Affiliation__c WHERE Contact__c = :c.Id LIMIT 1];
            Address__c savedAddress = [SELECT Id, Street_Name__c FROM Address__c WHERE Contact__c = :c.Id AND Is_Primary__c = true LIMIT 1];
            Email__c savedEmail = [SELECT Id, Name FROM Email__c WHERE Contact__c = :c.Id AND Classification__c = 'Business' LIMIT 1];
            //Phone__c savedPhone = [SELECT Id, Name, Is_Primary__c FROM Phone__c WHERE Contact__c = :c.Id AND Classification__c = 'Business' LIMIT 1];
            Social__c savedSocial = [SELECT Id, Name FROM Social__c WHERE Contact__c = :c.Id AND Type__c = 'Twitter' LIMIT 1];
            
            System.assertEquals(savedName.Suffix__c, 'Ms');
            System.assertEquals(savedAff.Position__c, 'Test Position');
            System.assertEquals(savedAddress.Street_Name__c, 'Test1 Street');
            System.assertEquals(savedEmail.Name, 'test1254634@gmail.com');
            //System.assertEquals(savedPhone.Name, '6666666666');
            //System.assertEquals(savedPhone.Is_Primary__c, true);
            System.assertEquals(savedSocial.Name, 'Test handle 3');
        } 

        test.stopTest();
    }

    @IsTest
    static void syncUserDetailsFromContact_TEST()
    {

        User systemUser = [SELECT Id, IsPortalEnabled, ContactId, Contact.Email FROM User WHERE Username = 'testSystemUsermig123@test.com'];
        system.runAs(systemUser) {

            test.startTest();
            
            // given : The Portal User has the Alumni Permission Set assigned to it
            User commUser = [SELECT Id, Contact.Personal_Email__c FROM User WHERE username = 'testCommunityUsermig123@test.com'];
            
            // when : The sync button is trigerred
            commUser = PORTAL_UCIN_MyProfileController.syncUserDetailsFromContact(commUser.Id);

            test.stopTest();

            // then : the UserName and Email is updated
            commUser = [SELECT Id, UserName FROM User WHERE username = 'personal@test.com'];
            system.assertEquals(commUser.UserName, 'personal@test.com'); 
        }          
    }

    @IsTest
    static void reactivatePortalAccount_TEST()
    {
        User systemUser = [SELECT Id, IsPortalEnabled, ContactId FROM User WHERE Username = 'testSystemUsermig123@test.com'];
        
        test.startTest();

        system.runAs(systemUser) {
            // given : The Portal User has the Alumni Permission Set assigned to it
            User commUser = [SELECT Id FROM User WHERE username = 'testCommunityUsermig123@test.com'];
            
            // when : The Permission set re-assignment is trigerred
            commUser = PORTAL_UCIN_MyProfileController.reactivatePortalAccount(commUser.Id);

            test.stopTest();

            // then : the permission set is deleted and re-assigned to the User
            Set<String> s_AlumniPortalPermissionSet = new Set<String>();
            String s_label = String.valueOf(Label.Alumni_Portal_Permission_Set);
            for(String permSet : s_label.split(';')){
                s_AlumniPortalPermissionSet.add(permSet);
            }
            List<PermissionSetAssignment> l_linkedPermsissionSetAssgn = [SELECT Id, PermissionSetId, PermissionSet.Name 
                                                                        FROM PermissionSetAssignment 
                                                                        WHERE PermissionSet.Name IN :s_AlumniPortalPermissionSet
                                                                        AND AssigneeId = :commUser.Id];
            
            String s_assignedPermSets;
            for(PermissionSetAssignment permSetAssg : l_linkedPermsissionSetAssgn){
                s_assignedPermSets = s_assignedPermSets + permSetAssg.PermissionSet.Name + ';';    
            }
            system.assert(s_assignedPermSets.contains(s_label)); 
        }
               
    }
    
    @IsTest
    static void SERVER_saveOtherProfileInformationTEST()
    {
        User comUser = [SELECT ID FROM User WHERE Username = 'testCommunityUsermig123@test.com'];
        Contact c = [SELECT ID, First_Name__c, Last_Name__c, Salutation_ERDA__c, Suffix FROM Contact WHERE Email = 'personal@test.com' LIMIT 1];

        Name__c preferredName = new Name__c(First_Name__c = c.First_Name__c, Last_Name__c = 'Newlastname', Salutation__c = c.Salutation_ERDA__c, Suffix__c = 'Ms');
        
        createOrigDetails(c.Id);
        
        Map<String, String> preferredMap = new Map<String, String>();
        preferredMap.put('email', 'personal');
        preferredMap.put('phone', 'home');
        
        Map<String, Email__c> mailMap = new Map<String, Email__c>();
        Email__c email = new Email__c();
        email.Classification__c = 'Private';
        email.Contact__c = c.Id;
        email.Name = 'test123463311@gmail.com';
        mailMap.put('Personal', originalMailMap.get('Personal'));
        Email__c email2 = email.clone(false, true);
        email2.Name = 'test1254634@gmail.com';
        mailMap.put('Business', email2);
        
        Email__c inactiveEmail = email.clone(false, true);
        inactiveEmail.Name = 'test1254634@gmail.com';
        email.Classification__c = 'Business';
        inactiveEmail.Start_Date__c = Date.today().addDays(-5);
        inactiveEmail.End_Date__c = Date.today().addDays(-4);
        inactiveEmail.Is_Primary__c = false;
        inactiveEmail.Is_Active__c = false;
        insert inactiveEmail;

        
        Map<String, Phone__c> pMap = new Map<String, Phone__c>();
        Phone__c phone = new Phone__c();
        phone.Contact__c = c.Id;
        phone.Classification__c = 'Private';
        phone.Name = '555-555-5551';
        Phone__c phone1 = phone.clone(false, true);
        Phone__c phone2 = phone.clone(false, true);
        phone1.Name = '6666666666';
        phone2.Name = '7777777777';
        pMap.put('Home', originalPhoneMap.get('Home'));
        pMap.put('Work', phone1);
        pMap.put('Mobile', phone2);

        Phone__c inactivePhone = phone.clone(false,true);
        inactivePhone.Name = '6666666666';
        inactivePhone.Start_Date__c = Date.today().addDays(-5);
        inactivePhone.End_Date__c = Date.today().addDays(-4);
        inactivePhone.Is_Primary__c = false;
        inactivePhone.Is_Active__c = false;
        inactivePhone.Classification__c = 'Business';
        inactivePhone.Type__c = 'Landline';
        insert inactivePhone;
        

        Map<String, Social__c> sMap = new Map<String, Social__c>();
        Social__c social = new Social__c();
        social.Contact__c = c.Id;
        social.Type__c = 'LinkedIn';
        social.Name = 'Test handle2';
        social.Classification__c = 'Private';
        Social__c social2 = social.clone(false, true);
        social2.Name = 'Test handle 3';
        sMap.put('LinkedIn', social);
        sMap.put('Twitter', social2);
        
        Social__c inactiveSocial = social.clone(false,true);
        inactiveSocial.Start_Date__c = Date.today().addDays(-5);
        inactiveSocial.End_Date__c = Date.today().addDays(-4);
        inactiveSocial.Is_Primary__c = false;
        inactiveSocial.Is_Active__c = false;
        insert inactiveSocial;
        
        Address__c address = new Address__c();
        address.Contact__c = c.Id;
        address.City__c = 'Irvine';
        address.Street_Name__c = 'Test1 Street';
        address.Post_Code__c = '92602';
        address.Type__c = 'Mailing';
        address.Classification__c = 'Private';
        
        Address__c businessAddress = new Address__c();
        businessAddress.Contact__c = c.Id;
        businessAddress.City__c = 'Springfield';
        businessAddress.Street_Name__c = ' 743 Evergreen Terrace';
        businessAddress.Post_Code__c = '92602';


        Affiliation__c origAffiliation = [SELECT Id, Position__c, End_Date__c, Is_Active__c, Is_Primary__c, Account__r.Name, Account__r.Industry, RecordTypeId FROM Affiliation__c WHERE Contact__c = :c.Id LIMIT 1];
        
        Map<String, String> origAffilMap = new Map<String, String>();
        origAffilMap.put('position', origAffiliation.Position__c);
        origAffilMap.put('orgName', origAffiliation.Account__r.Name);
        origAffilMap.put('orgIndustry', 'Nuclear Power');
        
        Map<String, String> affilMap = new Map<String, String>();
        affilMap.put('position', 'Tester');
        affilMap.put('orgName', origAffiliation.Account__r.Name);
        affilMap.put('orgIndustry', origAffiliation.Account__r.Industry);

        test.startTest();

        
        system.runAs(comUser) {

            PORTAL_UCIN_MyProfileController.SERVER_saveSetupInformation(comUser);
            
            PORTAL_UCIN_MyProfileController.SERVER_saveProfileInformation(c, preferredMap, preferredName, mailMap, pMap, sMap, 
                                                                          originalMailMap, originalPhoneMap, originalSocialMap, 
                                                                          originalAddress, address, originalBusinessAddress, businessAddress,
                                                                          origAffiliation, origAffilMap, affilMap);


            Name__c savedName = [SELECT Id, Suffix__c FROM Name__c WHERE Contact__c = :c.Id AND Is_Active__c = true AND Is_Primary__c = true];
            Affiliation__c savedAff = [SELECT Id, Position__c FROM Affiliation__c WHERE Contact__c = :c.Id AND Is_Active__c = true LIMIT 1];
            Address__c savedAddress = [SELECT Id, Street_Name__c FROM Address__c WHERE Contact__c = :c.Id AND Is_Primary__c = true LIMIT 1];
            Email__c savedEmail = [SELECT Id, Name FROM Email__c WHERE Contact__c = :c.Id AND Classification__c = 'Business' LIMIT 1];
            Phone__c savedPhone = [SELECT Id, Name, Is_Primary__c FROM Phone__c WHERE Contact__c = :c.Id AND Classification__c = 'Business' LIMIT 1];
            Social__c savedSocial = [SELECT Id, Name FROM Social__c WHERE Contact__c = :c.Id AND Type__c = 'Twitter' LIMIT 1];
            
            System.assertEquals(savedName.Suffix__c, 'Ms');
            System.assertEquals(savedAff.Position__c, 'Tester');
            System.assertEquals(savedAddress.Street_Name__c, 'Test1 Street');
            System.assertEquals(savedEmail.Name, 'test1254634@gmail.com');
            System.assertEquals(savedPhone.Name, '6666666666');
            System.assertEquals(savedPhone.Is_Primary__c, false);
            System.assertEquals(savedSocial.Name, 'Test handle 3');
        } 

        test.stopTest();
    }
    
    private static void createOrigDetails(Id contId) {
        originalMailMap = new Map<String, Email__c>();
        Email__c email11 = new Email__c();
        email11.Classification__c = 'Private';
        email11.Contact__c = contId;
        email11.Name = 'test123463311@gmail.com';
        email11.Start_Date__c = Date.today().addDays(-1);
        originalMailMap.put('Personal', email11);
        Email__c email211 = email11.clone(false, true);
        Email__c email311 = email11.clone(false, true);
        email211.Name = 'test125463411@gmail.com';
        email211.Is_Primary__c = true;
        email311.Name = 'test125463511@gmail.com';
        originalMailMap.put('Business', email211);
        originalMailMap.put('Primary', email311);
        insert originalMailMap.values();

        originalPhoneMap = new Map<String, Phone__c>();
        Phone__c phone3 = new Phone__c();
        phone3.Contact__c = contId;
        phone3.Classification__c = 'Private';
        phone3.Name = '555-555-5551';
        phone3.Start_Date__c = Date.today().addDays(-1);
        Phone__c phone4 = phone3.clone(false, true);
        Phone__c phone5 = phone3.clone(false, true);
        phone4.Name = '6666666661';
        phone5.Name = '7777777771';
        phone5.Is_Primary__c = true;
        originalPhoneMap.put('Home', phone3);
        originalPhoneMap.put('Work', phone4);
        originalPhoneMap.put('Mobile', phone5);
        insert originalPhoneMap.values();
        
        originalSocialMap = new Map<String, Social__c>();
        Social__c social11 = new Social__c();
        social11.Contact__c = contId;
        social11.Type__c = 'LinkedIn';
        social11.Name = 'Test handle22';
        social11.Classification__c = 'Private';
        social11.Start_Date__c = Date.today().addDays(-1);
        Social__c social211 = social11.clone(false, true);
        social211.Name = 'Test handle 33';
        social211.Start_Date__c = Date.today().addDays(-1);
        originalSocialMap.put('LinkedIn', social11);
        originalSocialMap.put('Twitter', social211);
        insert originalSocialMap.values();
        
        originalAddress = new Address__c();
        originalAddress.Contact__c = contId;
        originalAddress.City__c = 'Irvine12';
        originalAddress.Street_Name__c = 'Test1 Street';
        originalAddress.Post_Code__c = '92602';
        originalAddress.Type__c = 'Mailing';
        originalAddress.Classification__c = 'Private';
        originalAddress.Start_Date__c = Date.today().addDays(-1);
        insert originalAddress;
        
        originalBusinessAddress = new Address__c();
        originalBusinessAddress.Contact__c = contId;
        originalBusinessAddress.City__c = 'Irvine';
        originalBusinessAddress.Street_Name__c = '123 Fake Street';
        originalBusinessAddress.Post_Code__c = '92602';
        originalBusinessAddress.Type__c = 'Mailing';
        originalBusinessAddress.Classification__c = 'Business';
        originalBusinessAddress.Start_Date__c = Date.today().addDays(-1);
        insert originalBusinessAddress;
    }
}