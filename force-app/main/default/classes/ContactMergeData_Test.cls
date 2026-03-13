/**
* @description Test Class for ContactMergeData
*
* @author P. Victoriano
* @date 01/03/2021
*
* @group Common
* @revision
*
**/
@isTest(isParallel=true)
private class ContactMergeData_Test {
    private static ContactMergeData wrapper;

    @isTest
    static void testPopulate() {
        Contact con = new Contact();
        User usr = new User();
        DuplicateFieldInfo dfi = new DuplicateFieldInfo();
        Test.startTest();
        ContactMergeData wrap = new ContactMergeData(con, usr, dfi);
        Test.stopTest();
    }
    @isTest
    static void testPopulateDeserialise() {
        List<ContactMergeData> newList = new List<ContactMergeData>();
        String sJson = testDataCreator();

        Test.startTest();

        ContactMergeData wrapper = (ContactMergeData) JSON.deserializeStrict(sJson, ContactMergeData.class);
        newList.add(wrapper);
        newList.sort();
        //
        String sNewJson = sJson.replaceAll('\"Email\":\"personalemail@email.com\"', '\"Email\":\"alumemail@email.com\"');
        sNewJson = sNewJson.replaceAll('\"Username\":\"personalemail@email.com0.433\"', '\"Username\":\"alumniemail@email.com0.433\"');
        ContactMergeData wrapper2 = (ContactMergeData) JSON.deserializeStrict(sNewJson, ContactMergeData.class);
        newList.add(wrapper2);
        newList.sort();

        //Only 1 record - Sorting verification 
        System.assertEquals('personalemail@email.com',
                            newList.get(0).contactRecord.Email,
                            'Incorrect Sorting 1'
                           );

        Test.stopTest();

    }
    @isTest
    static void testDataCompareNoUser() {
        List<ContactMergeData> newList = new List<ContactMergeData>();
        String sJson = testDataCreator();
        //
        Test.startTest();

        ContactMergeData wrapper = (ContactMergeData) JSON.deserializeStrict(sJson, ContactMergeData.class);
        wrapper.linkUser(null);

        String sNewJson = sJson.replaceAll('\"Email\":\"personalemail@email.com\"', '\"Email\":\"alumemail@email.com\"');
        ContactMergeData wrapper2 = (ContactMergeData) JSON.deserializeStrict(sNewJson, ContactMergeData.class);
        Integer intRet = wrapper.compareTo(wrapper2);
        //
        System.assertEquals(1, intRet, 'Incorrect No User Sort logic');

        Test.stopTest();
    }
    @isTest
    static void testDataCompareNoUserHasPersonId() {
        List<ContactMergeData> newList = new List<ContactMergeData>();
        String sJson = testDataCreator();
        //
        Test.startTest();

        ContactMergeData wrapper = (ContactMergeData) JSON.deserializeStrict(sJson, ContactMergeData.class);
        //Has Person Id on Current record
        wrapper.contactRecord = new Contact(Person_ID_unique__c = '1234');
        wrapper.linkUser(null);
        

        String sNewJson = sJson.replaceAll('\"Email\":\"personalemail@email.com\"', '\"Email\":\"alumemail@email.com\"');
        ContactMergeData wrapper2 = (ContactMergeData) JSON.deserializeStrict(sNewJson, ContactMergeData.class);
        //Has No Person Id on Previous record
        wrapper2.linkUser(null);
        wrapper2.contactRecord = new Contact();
        
        Integer intRet = wrapper.compareTo(wrapper2);
        //
        System.assertEquals(0, intRet, 'Incorrect No User PersonId Sort logic');

        Test.stopTest();
    }
    @isTest
    static void testDataCompareHasCommUseronCurrentNonPrevious() {
        
        Test.startTest();

        ContactMergeData wrapper = new ContactMergeData(new Contact(), new User(), new DuplicateFieldInfo());
        ContactMergeData wrapper2 = new ContactMergeData(new Contact(), new User(), new DuplicateFieldInfo());
        //Has Community Access injected
        wrapper.hasCommunityAccess = false;
        wrapper2.hasCommunityAccess = true;
        
        Integer intRet = wrapper.compareTo(wrapper2);
        //
        System.assertEquals(1, intRet, 'Sort logic');

        Test.stopTest();
    }

    @isTest
    static void testPermissionSetAssigned() {
        List<ContactMergeData> newList = new List<ContactMergeData>();
        testDataDML();
        //
        Test.startTest();
        //Assign Permissions for Community
        testAddPermissionSets();
        //Mass Test
        List<ContactMergeData> cmds = ContactMergeController.getEntityData('CommTest','Test',null,null,null);
        ContactMergeData cmd = cmds.get(0);
        System.assertEquals(cmd.contactRecord.Email, 'personalemail@email.com', 'Sorting Issue');
        //
        Test.stopTest();
    }
    //Sample JSON Payload for Blackbox testing
    static String testDataCreator() {
        return '{"userRecord":{"attributes":{"type":"User","url":"/services/data/v51.0/sobjects/User/0052O000001jKV8QAM"},"Id":"0052O000001jKV8QAM","Username":"personalemail@email.com0.433","FirstName":"Paul","LastName":"Test","Email":"personalemail@email.com","ContactId":"0032O000009TiQLQA0","LastLoginDate":"2021-03-01T03:40:27.000+0000","PermissionSetAssignments":{"totalSize":5,"done":true,"records":[{"attributes":{"type":"PermissionSetAssignment","url":"/services/data/v51.0/sobjects/PermissionSetAssignment/0Pa2O000001CGDISA4"},"AssigneeId":"0052O000001jKV8QAM","Id":"0Pa2O000001CGDISA4","PermissionSetId":"0PS4a000000022tGAA","PermissionSet":{"attributes":{"type":"PermissionSet","url":"/services/data/v51.0/sobjects/PermissionSet/0PS4a000000022tGAA"},"Name":"Alumni_Portal_Permission_Set","Type":"Regular","Id":"0PS4a000000022tGAA"}},{"attributes":{"type":"PermissionSetAssignment","url":"/services/data/v51.0/sobjects/PermissionSetAssignment/0Pa2O000001CGDJSA4"},"AssigneeId":"0052O000001jKV8QAM","Id":"0Pa2O000001CGDJSA4","PermissionSetId":"0PS0I000002ROSyWAO","PermissionSet":{"attributes":{"type":"PermissionSet","url":"/services/data/v51.0/sobjects/PermissionSet/0PS0I000002ROSyWAO"},"Name":"Customer_Community_Ask_Monash_Student","Type":"Regular","Id":"0PS0I000002ROSyWAO"}},{"attributes":{"type":"PermissionSetAssignment","url":"/services/data/v51.0/sobjects/PermissionSetAssignment/0Pa2O000001C04zSAC"},"AssigneeId":"0052O000001jKV8QAM","Id":"0Pa2O000001C04zSAC","PermissionSetId":"0PS0I000002ROOvWAO","PermissionSet":{"attributes":{"type":"PermissionSet","url":"/services/data/v51.0/sobjects/PermissionSet/0PS0I000002ROOvWAO"},"Name":"Customer_Community_My_Application","Type":"Regular","Id":"0PS0I000002ROOvWAO"}},{"attributes":{"type":"PermissionSetAssignment","url":"/services/data/v51.0/sobjects/PermissionSetAssignment/0Pa2O000001C04uSAC"},"AssigneeId":"0052O000001jKV8QAM","Id":"0Pa2O000001C04uSAC","PermissionSetId":"0PS4a00000001xeGAA","PermissionSet":{"attributes":{"type":"PermissionSet","url":"/services/data/v51.0/sobjects/PermissionSet/0PS4a00000001xeGAA"},"Name":"Einstein_Discovery_Writeback","Type":"Regular","Id":"0PS4a00000001xeGAA"}},{"attributes":{"type":"PermissionSetAssignment","url":"/services/data/v51.0/sobjects/PermissionSetAssignment/0Pa2O000001C02hSAC"},"AssigneeId":"0052O000001jKV8QAM","Id":"0Pa2O000001C02hSAC","PermissionSetId":"0PS28000002VPl5GAG","PermissionSet":{"attributes":{"type":"PermissionSet","url":"/services/data/v51.0/sobjects/PermissionSet/0PS28000002VPl5GAG"},"Name":"X00e28000002JWZiAAO","Type":"Profile","Id":"0PS28000002VPl5GAG"}}]}},"userLink":"/0052O000001jKV8QAM","primaryClass":"success","permissionSetToCommunityMap":{"Alumni_Portal_Permission_Set":"Alumni","SteelBrickCPQCustomerUser":"Offers","Customer_Community_My_Application":"my.app","Customer_Community_Ask_Monash_Student":"Ask Monash"},"permissionSetIds":["0PS4a000000022tGAA","0PS0I000002ROSyWAO","0PS0I000002ROOvWAO","0PS4a00000001xeGAA"],"matchDescription":"Strong match of Contact which can be auto-merged. This excludes records which contain a SAP staff id (i.e. they are not being merged).","matchDescripMAp":{"Contact_Loose_Match":"A loose match on contact by First Name, Last Name, and Email(s) - Email, Personal Email, Monash Email.","Contact_Potential_Match":"A 2nd tier matching/duplicate rule to allow non-perfect matches to be merged","Contact_Perfect_Match":"Strong match of Contact which can be auto-merged. This excludes records which contain a SAP staff id (i.e. they are not being merged)."},"matchConfidence":"Contact_Perfect_Match 87.0","lastModifiedDateString":"1/3/2021","lastLoginDateString":"1/3/2021","isPrimary":true,"isNonSSOUser":true,"isMyAppUser":true,"isIncluded":true,"includeClass":"success","hasCommunityAccess":true,"dupFieldInfo":{"sapStaffIdDifference":"nullcss","recordId":null,"personalEmailDifference":"samecss","monashEmailDifference":"nullcss","mobilePhoneDifference":"samecss","matchDescription":"Contact_Perfect_Match 87.0","matchConfidence":"87.0","lastNameDifference":"samecss","firstNameDifference":"samecss","emailDifference":"samecss","dupRuleName":"Contact_Perfect_Match","birthdateDifference":"samecss"},"contactRecord":{"attributes":{"type":"Contact","url":"/services/data/v51.0/sobjects/Contact/0032O000009TiQLQA0"},"Id":"0032O000009TiQLQA0","Name":"Paul MyApp Test","FirstName":"Paul","LastName":"Test","Email":"personalemail@email.com","Monash_Email_Address__c":"monash@student.monash.edu","Personal_Email__c":"personalemail@email.com","Birthdate":"1991-12-12","AccountId":"0012O00000BFablQAD","LastModifiedDate":"2021-03-01T03:43:33.000+0000","MobilePhone":"45345345345","Contact_Profile__c":"School Staff/Teacher [SS];Friend;Alumni,Alumni No Degree,Donor","Account":{"attributes":{"type":"Account","url":"/services/data/v51.0/sobjects/Account/0012O00000BFablQAD"},"Id":"0012O00000BFablQAD","Name":"Paul Test"}},"contactLink":"/0032O000009TiQLQA0","communityAccesses":["Alumni","Ask Monash","my.app"],"birthDateString":"12/12/1991","accountRecord":{"attributes":{"type":"Account","url":"/services/data/v51.0/sobjects/Account/0012O00000BFablQAD"},"Id":"0012O00000BFablQAD","Name":"Paul Test"}}';
    }
    static void testDataDML() {
        Contact con = new Contact(
            FirstName = 'CommTest',
            LastName = 'Test',
            Email = 'alumni@email.com',
            Personal_Email__c = 'personalemail@email.com',
            Person_ID_unique__c = String.valueOf(Math.random()).substring(0,6).replaceAll('.',''),
            MobilePhone = '45345345345',
            Monash_Email_Address__c = '',
            Contact_Profile__c = 'Alumni,Alumni No Degree,Donor',
            BirthDate = Date.valueOf('1991-12-12')
        );
        Contact myapp = new Contact(
            FirstName = 'CommTest',
            MiddleName = 'MyApp',
            LastName = 'Test',
            Email = 'personalemail@email.com',
            Personal_Email__c = 'personalemail@email.com',
            Person_ID_unique__c = String.valueOf(Math.random()).substring(0,6).replaceAll('.',''),
            MobilePhone = '45345345345',
            Monash_Email_Address__c = '',
            Contact_Profile__c = 'Friend',
            BirthDate = Date.valueOf('1991-12-12')
        );
        Contact monSt = new Contact(
            FirstName = 'CommTest',
            MiddleName = 'Man',
            LastName = 'Test',
            Email = 'monash@student.monash.edu',
            Personal_Email__c = 'personalemail@email.com',
            Person_ID_unique__c = String.valueOf(Math.random()).substring(0,6).replaceAll('.',''),
            MobilePhone = '5674567890',
            Monash_Email_Address__c = 'monash@student.monash.edu',
            BirthDate = Date.valueOf('1991-12-12')
        );
        List<Contact> cons = new List<Contact> {myapp, con, monSt};
        insert cons;
        //Create user
        User usrRunas = [SELECT Id FROM User WHERE Alias = 'ccore' LIMIT 1];
        //
        System.runAs(usrRunas) {
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Customer Community General User' Limit 1];
            User user1 = new User(
                UserName = con.Email+String.valueOf(Math.random()).substring(0,5),
                FirstName = con.FirstName,
                LastName = con.LastName,
                Alias = 'test'+String.valueOf(Math.random()).substring(0,4),
                email = con.Email,
                ContactId = con.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'a'+String.valueOf(Math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            User user2 = new User(
                UserName = myapp.Email+String.valueOf(Math.random()).substring(0,5),
                FirstName = myapp.FirstName,
                LastName = myapp.LastName,
                Alias = 'test'+String.valueOf(Math.random()).substring(0,4),
                email = myapp.Email,
                ContactId = myapp.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'b'+String.valueOf(Math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            User user3 = new User(
                UserName = monSt.Email+String.valueOf(Math.random()).substring(0,5),
                FirstName = monSt.FirstName,
                LastName = monSt.LastName,
                Alias = 'test'+String.valueOf(Math.random()).substring(0,4),
                email = monSt.Email,
                ContactId = monSt.Id,
                ProfileId = portalProfile.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickName = 'c'+String.valueOf(Math.random()).substring(0,6),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                IsActive = true,
                FederationIdentifier = String.valueOf(Math.random()).substring(0,7).replaceAll('.', '')
            );
            Database.insert(new List<User> {user1,user2,user3});
        }
    }
    static void testAddPermissionSets() {
        //Create user
        User usrRunas = [SELECT Id FROM User WHERE Alias = 'ccore' LIMIT 1];
        //
        System.runAs(usrRunas) {
            //Add Permission Set Assignment
            PermissionSet psAlum = [SELECT Id FROM PermissionSet WHERE Name = 'Alumni_Portal_Permission_Set' LIMIT 1];
            PermissionSet psApp1 = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_My_Application' LIMIT 1];
            PermissionSet psApp2 = [SELECT Id FROM PermissionSet WHERE Name = 'Customer_Community_Ask_Monash_Student' LIMIT 1];
            List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
            List<User> users = [SELECT Id, Email FROM User WHERE FirstName = 'CommTest' AND IsActive = true];
            for(User usrObj :users) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = usrObj.Id;
                //
                if(usrObj.Email == 'alumni@email.com') {
                    psa.PermissionSetId = psAlum.Id;
                } else if(usrObj.Email == 'personalemail@email.com') {
                    psa.PermissionSetId = psApp1.Id;
                } else if(usrObj.Email == 'monash@student.monash.edu') {
                    psa.PermissionSetId = psApp2.Id;
                }
                psas.add(psa);
            }
            insert psas;
        }
    }
}