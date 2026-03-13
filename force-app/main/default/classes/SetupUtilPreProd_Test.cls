/**
* @description Setup Utilities for Jenkins
*
* @author P. Victoriano
* @date 10/07/2019
*
* @group Test Class
* @revision
*
**/
@isTest
private class SetupUtilPreProd_Test {
    private static User usr;

    @isTest static void runTestSpecified() {
        SetupUtilPreProd.setData('DUP', 'ALL');
        map<String,RecordType> mpResult = SetupUtilPreProd.getRecordTypeId();
        System.assertNotEquals(null, mpResult, 'Error mpResult');
        map<String,User>  mpResultUsr = SetupUtilPreProd.getAdminUsers();
        System.assertNotEquals(null, mpResultUsr, 'Error mpResultUsr');

    }
    @isTest static void runTestSpecified2() {
        try {
            SetupUtilPreProd.jenkinsUserName = Userinfo.getUserName();
            User userRec = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true AND Username !=:Userinfo.getUserName() LIMIT 1];
            System.runAs(userRec) {
                SetupUtilPreProd.updateUsersAsync();
            }
        } catch (Exception e) {
            System.assertEquals(null, e.getMessage(), 'Error Update');
        }
    }
    @isTest static void runTestSpecified3() {
        try {
            String str = '{"sandboxName":"test"'+
                         ',"taskType":"Create Admin User"'+
                         ',"permVersion":"V2"'+
                         ',"emails":["user.test@test.com"]}';
            SetupUtilPreProd.selfService(str);
        } catch (Exception e) {
            System.assertEquals(null, e.getMessage(), 'Error Update');
        }
    }
    @isTest static void runTestSpecified4() {
        //
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        createTestUser(pf.Id, 'Test FirstName', 'Test LastName');

        Test.startTest();
        try {
            String str = '{"sandboxName":"test"'+
                         ',"taskType":"Create Build and Test Team User"'+
                         ',"permVersion":"V2"'+
                         ',"emails":["'+usr.Email+'"]}';
            SetupUtilPreProd.selfService(str);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Error Update');
        }
        Test.stopTest();
    }
    @isTest static void runTestSpecified5() {
        try {
            SetupUtilPreProd.setRuntime('PROJ',new List<String> {'TEST','All','PROD'});
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Error Update');
        }
    }
    @isTest static void runTestSpecified6() {
        try {
            Map<String, Schema.SObjectField> fieldMap = new Map <String, Schema.SObjectField> {
                'FirstName' => Contact.FirstName,
                'LastName' => Contact.LastName
            };
            SetupUtilPreProd.SelectFields(fieldMap);
            SetupUtilPreProd.setRuntime('PROJ',new List<String>());
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Error Update');
        }
    }


    @isTest static void runTestSpecified7() {

        // Query your profile from Organization that your want to test.
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        createTestUser(pf.Id, 'TestFirstName7', 'TestLastName7');

        // Query your permission set name from Organization that your want to test.
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Knowledge_Manager_askmonash'];

        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = usr.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        // Run your code with inserted user.

        system.runAs(usr) {

            Knowledge_Article__kav  article_Kav = new Knowledge_Article__kav ();
            article_Kav.title='Testing';
            article_Kav.UrlName ='TestingMonash';
            article_Kav.ValidationStatus ='Published';
            article_Kav.Planned_Publication_Date__c = system.today()+10;
            insert article_Kav;
            SetupUtilPreProd.PublishArticle(article_Kav.Title);
            System.assertEquals('Published',article_Kav.ValidationStatus);
        }
    }

    private static void createTestUser(Id profID, String fName, String lName) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');

        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        usr = new User(  firstname = fName,
                         lastName = lName,
                         email = uniqueName + '@test' + orgId + '.org.invalid',
                         Username = uniqueName + '@test' + orgId + '.org',
                         EmailEncodingKey = 'ISO-8859-1',
                         Alias = uniqueName.substring(18, 23),
                         TimeZoneSidKey = 'America/Los_Angeles',
                         LocaleSidKey = 'en_US',
                         LanguageLocaleKey = 'en_US',
                         ProfileId = profId,
                         UserPermissionsKnowledgeUser = true);
        insert usr;
    }
}