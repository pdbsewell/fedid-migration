/**
* @author Kristian Vegerano
* @date 29.May.2019
* @group Enquiry Management
* @description  Sets default email template
* @revision     APRivera, 20.January.2019 - Removed (!Test.isRunningTest()). <br/>
* @revision     RPunjabi, 09.June.2023 - Add functionality to clear body content. <br/>
*/

global class MyCaseTemplateChooser implements Support.EmailTemplateSelector, QuickAction.QuickActionDefaultsHandler {
    // Empty constructor
    global MyCaseTemplateChooser() {    }
    // The main interface method
   global ID getDefaultEmailTemplateId(ID caseId) {
        String emailTemplate = Label.defaultEmailTemplate;
        Id userRoleId = userInfo.getUserRoleId();
        system.debug('userRoleId is ' + userRoleId);
        if (userRoleId != null) {
            UserRole role = [select Id, developerName from UserRole where id = :userRoleId];
            system.debug('role is ' + role);
            List<CaseRoleEmailTemplateMapping__mdt> roleEmailTemplateMapping = [select EmailTemplate__c, UserRoleName__c from CaseRoleEmailTemplateMapping__mdt where UserRoleName__c = :role.developerName];
            system.debug('roleEmailTemplateMapping is ' + roleEmailTemplateMapping);
            if (roleEmailTemplateMapping.size() > 0) {
                emailTemplate = roleEmailTemplateMapping[0].EmailTemplate__c;
            }
        }
        List<EmailTemplate> etList = [SELECT id FROM EmailTemplate WHERE DeveloperName = :emailTemplate];
        if (etList.size() == 0) {
            throw new LimitException('No Email Template named ' + emailTemplate + ' found.');
        }
        return etList[0].id;
    }
    //global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaultsList) {
        //.. Traverse through actions
        for (Integer i = 0; i < defaultsList.size(); i++) {
            QuickAction.QuickActionDefaults defaults = defaultsList.get(i);
            
            // Check if the quick action is the standard case feed `SendEmail` action
            if (
                defaults instanceof QuickAction.SendEmailQuickActionDefaults &&
                defaults.getTargetSObject().getSObjectType() == EmailMessage.sObjectType &&
                defaults.getActionType().equals('SendEmail')
            ) {
                String actionName = defaults.getActionName();
                Id contextId = defaults.getContextId();
                
                // check if the related object is a Case  and process it in 
                if (actionName.equals('Case.MRO_Send_Email') && 
                    contextId != null &&
                    contextId.getSobjectType() == Case.sObjectType
                ) {
                    applySendEmailDefaultsForCase((QuickAction.SendEmailQuickActionDefaults) defaults, actionName);
                    break;
                }
            }
        }
    }
    
    private void applySendEmailDefaultsForCase(QuickAction.SendEmailQuickActionDefaults sendEmailDefaults, string sendType) {
        //Case c = [SELECT Id, ContactId, RecordTypeId FROM Case WHERE Id = :sendEmailDefaults.getContextId()]; 
        
        EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
        if (sendType.contains('MRO_Send_Email')) {        
            //emailMessage.HtmlBody  = '';
            sendEmailDefaults.setTemplateId(getTemplateId('MRO Awards Default Template'));
            sendEmailDefaults.setInsertTemplateBody(false);
            sendEmailDefaults.setIgnoreTemplateSubject(false);
        }
    }
    
    private ID getTemplateId(String templateName) {
        ID templateId = null;  
        List<EmailTemplate> templates = new List<EmailTemplate>([
            SELECT id
            FROM EmailTemplate
            WHERE Name = :templateName
            LIMIT 1
        ]);
        
        if ( templates.size() > 0 ) {
            templateId = templates[0].id;
        } else {
            System.debug(LoggingLevel.ERROR, 'Unable to locate email template using name "' + templateName + '"' );
        } 
        return templateId;
    }
}