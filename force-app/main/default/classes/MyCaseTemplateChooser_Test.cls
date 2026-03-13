/**
* @author Kristian Vegerano
* @date 29.May.2019
* @group Test Class
* @description  Test Class to test the functionality of MyCaseTemplateChooser
* @revision     APRivera, 20.January.2019 - Increased Code Coverage <br/>
* @revision     RPunjabi, 09.June.2023 - Add functionality to clear body content. <br/>
*/

@isTest(isParallel=false) // APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: EmailTemplate: []
public class MyCaseTemplateChooser_Test {

    @istest
    public static void testMethodTemplateChooserException() {
        //.. Create Template
        EmailTemplate e = new EmailTemplate (developerName = 'Monash_connect_default_email', FolderId = UserInfo.getUserId(),TemplateType= 'Text', Name = 'Monash_connect_default_email');
        insert e;
        
        List<User> userList= TestHelper.createTestUsers('System Administrator',1);
        system.assertEquals(userList.size(),1);
        User u=userList[0];
        system.runAs(u)
        {
            case newCase = new case(Channel__c='Web',
                    Origin='ask.monash@monash.edu',
                    Community_Status__c='I need help with accepting my employment offer from Monash',
                    Description='testcase description');
            insert newCase;


            MyCaseTemplateChooser classInstance = new MyCaseTemplateChooser();
            classInstance.getDefaultEmailTemplateId(newCase.Id);
        }
    }

    @istest
    public static void testMethodTemplateChooser() {

        List<User> userList= TestHelper.createTestUsers('System Administrator',1);
        system.assertEquals(userList.size(),1);
        User u=userList[0];
        List<UserRole> roleList=[select id from UserRole where developerName='Monash_Connect_Officer'];
        if(roleList.size()>0) {
            u.userroleId=roleList[0].Id;
            update u;
        }

        EmailTemplate e = new EmailTemplate (developerName = 'Monash_connect_default_email', FolderId = UserInfo.getUserId(),TemplateType= 'Text', Name = 'Monash_connect_default_email');
        insert e;

        system.runAs(u) {
            case newCase = new case(Channel__c='Web',
                    Origin='ask.monash@monash.edu',
                    Community_Status__c='I need help with accepting my employment offer from Monash',
                    Description='testcase description');
            insert newCase;
            
            MyCaseTemplateChooser classInstance = new MyCaseTemplateChooser();
            classInstance.getDefaultEmailTemplateId(newCase.Id);
        }
    }

    // Test Email message Template chooser
    @istest
    public static void testMethodTemplateChooserLEX_Case() {
        List<User> userList= TestHelper.createTestUsers('System Administrator', 1);
        User u = userList[0];

        system.runAs(u) {
            Test.startTest();

            Case newCase = new Case(Enquiry_Type__c = 'Awards',
                    Origin = 'Email',
                    Description='testcase description');
            insert newCase;

            MyCaseTemplateChooser classInstance = new MyCaseTemplateChooser();
            List<Map<String, Object>> defaultSettingAsUntypedObject = new List<Map<String, Object>>
            {
                    new Map<String, Object>
                    {
                            'targetSObject' => new EmailMessage(),
                            'contextId' => newCase.Id,
                            'actionType' => 'SendEmail',
                            'actionName' => 'Case.MRO_Send_Email',
                            'fromAddressList' => new List<String> { 'salesforce@test.com' }
                    }
            };

            List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings =
                    (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsUntypedObject), List<QuickAction.SendEmailQuickActionDefaults>.class);

            classInstance.onInitDefaults((QuickAction.QuickActionDefaults[])defaultsSettings);
            System.assertEquals('Case', defaultsSettings[0].getContextId().getSObjectType().getDescribe().getName());
            Test.stopTest();
        }
    }
}