@isTest(isParallel=false) //  APEX_DATA_ACCESS_RESTRICTION, In parallel Apex tests, DML operations aren't permitted on this type of object: User: []
private class EmailMessageDefaultHandler_Test {
    
    @istest
    public static void testMethodEmailMessageDefaultHandlerException() {
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
            
            
            EmailMessageDefaultHandler classInstance = new EmailMessageDefaultHandler();
            classInstance.getDefaultEmailTemplateId(newCase.Id);
        }
    }
    
    @istest
    public static void testMethodEmailMessageDefaultHandlerChooser() {
        
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
            EmailMessageDefaultHandler classInstance = new EmailMessageDefaultHandler();
            classInstance.getDefaultEmailTemplateId(newCase.Id);
        }
    }
    
    /* HOLD OFF DRAFT AUTO PICKUP - PROVIDE READ ONLY DRAFT OF ENQUIRY OWNER FOR NOW
        @istest
        public static void testMethodEmailMessageDefaultHandlerChooserLEX() {
            List<User> userList= TestHelper.createTestUsers('System Administrator', 1);
            User u = userList[0];
            
            List<EmailTemplate> emailTemplateList = new List<EmailTemplate>();
            emailTemplateList.add(new EmailTemplate (developerName = 'SR_Scenquiries', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'SR_Scenquiries'));
            emailTemplateList.add(new EmailTemplate (developerName = 'SR_Late_Reg', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'SR_Late_Reg'));
            emailTemplateList.add(new EmailTemplate (developerName = 'SR_Key_Agent', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'SR_Key_Agent'));
            insert emailTemplateList;
            
            system.runAs(u) {
                Test.startTest();
                
                    Case newCase = new Case(Enquiry_Type__c = 'Post Application',
                                            Origin = 'scenquiries@monash.edu',
                                            Description='testcase description');
                    insert newCase;
                    
                    QuickAction.SendEmailQuickActionDefaults emailQuickAction;
                    QuickAction.QuickActionDefaultsHandler qdf; 
                    QuickAction.QuickActionDefaults[] defaults = new QuickAction.QuickActionDefaults[]{ emailQuickAction }; 
                    
                    EmailMessageDefaultHandler classInstance = new EmailMessageDefaultHandler();
                    classInstance.onInitDefaults(defaults);
                    
                Test.stopTest();    
            }
        }
    */
}