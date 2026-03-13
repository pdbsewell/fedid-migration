/**
 * @author      Peter Sewell
 * @description Transaction Security Policy class detecting events to block
 * @group       Apex Class
 * @revision    23.11.23 - Peter Sewell - Created
 *              09.01.24 - Peter Sewell - Allow login types of 'SAML XXX Initiated SSO' 
 *              27.02.24 - Peter Sewell - Handle sensitive File Access events 
 * 				02.08.25 - Sachin Shetty- Allow application of type - Mulesoft JWT App
 */
global class TSP_EventsToBlock implements TxnSecurity.EventCondition {
    
    // Permissions used to filter specific events for specific users
    // 
    public static final string CONST_ENFORCE_SSO_API_NAME = 'TSP_Enforce_SSO_Login';

    // Event constants of interest

    // Valid SSO login types
    static final Set<String> LOGIN_SSO_TYPES = new Set<String> {
        'SAML Sfdc Initiated SSO',
        'SAML Idp Initiated SSO'
    };

    // SSO enforced for these app types
    static final Set<String> LOGIN_SSO_APP_TYPES = new Set<String> {
        'Browser'
    };
        
    // Allowed app types
    static final Set<String> ALLOWED_APP_TYPES = new Set<String> {
        'Mulesoft JWT App'
    };

    // Other constants
    static final string CUSTOM_NOTIFICATION_API_NAME = 'UniCRM_Alert_Notification'; // Where in app messages are sent
    static final string FILE_NOTIFICATION_CONTENT_RESOURCE = 'fileaccesswarning';   // Static resource containing notification content
    static final string DUMMY_TARGET_RECORD_ID = '000000000' + '000000AAA';         // To use when sending custom notification
    private static Map<String, Set<Id>> permissionSetIdCache = new Map<String, Set<Id>>();

    // Main event evaluation loop
    //
    public boolean evaluate(SObject event) {

        // Only perform TSP event evaluation in Prod unless Enforce TSP in Sandbox is set to true
        if (!evaluateTSP()) {
            return false;
        }

        switch on event{
            when LoginEvent loginEvent {
                return evaluateLoginEvent(loginEvent);
            }
            when FileEventStore fileEvent {
                return evaluateFileEvent(fileEvent);
            }
            when null {
                return false;   
            }
            when else{
                return false;
            }
        }
    }

    // Should we evaluate TSP in this org
    //
    private boolean evaluateTSP() {
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (runningInASandbox && !isFeatureEnabledTspInSandbox()) {
            return false;
        }
        return true;
    }

    // Check feature switch for Non SSO Login
    //
    private boolean isFeatureEnabledTspInSandbox() {
        Feature_Switch_TSP__c cs = Feature_Switch_TSP__c.getOrgDefaults();
        return cs.Evaluate_TSP_in_Sandbox__c;
    }


    // Evaluate the Login Event
    //
    private boolean evaluateLoginEvent(LoginEvent loginEvent) {

        // Detect Non SSO Login policy breach
        if (isNonSsoLoginPolicyBreach(loginEvent)) {
            return true;
        }

        // Detect other login events we want to block
        // ...

        // Nothing of interest
        return false;
    }

    // Detect a non SSO (non SAML) login by a user who must use SSO
    //
    private boolean isNonSsoLoginPolicyBreach (LoginEvent loginEvent) {

        // Is TSP SSO detection feature switch enabled?
        if (!isFeatureEnabledDetectNonSSOLogin()) {
            return false; // nope
        }
        
        // TSP not enforced for these applications
        if(ALLOWED_APP_TYPES.contains(loginEvent.Application) ){
			return false;
        }

        // Did an SSO enforced user login via non SSO on a Browser?
        if (!LOGIN_SSO_TYPES.contains(loginEvent.LoginType) && 
            LOGIN_SSO_APP_TYPES.contains(loginEvent.Application) &&
            isUserEnforcedSSO(loginEvent.UserId)) {
            return true; 
        }

        return false; 
    }

    // Check feature switch for Non SSO Login
    //
    private boolean isFeatureEnabledDetectNonSSOLogin() {
        Feature_Switch_TSP__c cs = Feature_Switch_TSP__c.getOrgDefaults();
        return cs.Detect_Non_SSO_Login__c;
    }

    // Is SSO enforced for this user
    //
    private boolean isUserEnforcedSSO(Id userId) {
        return hasUserPermission(userId, CONST_ENFORCE_SSO_API_NAME);
    }

    // Is user assigned a specific permission set?
    //
    private static Boolean hasUserPermission(Id userId, String psApiName) {
        // Check cache first
        if (!permissionSetIdCache.containsKey(psApiName)) {
            Set<Id> psIds = new Set<Id>();
    
            // Get Permission Set
            for (PermissionSet ps : [
                SELECT Id 
                FROM PermissionSet 
                WHERE Name = :psApiName
            ]) {
                psIds.add(ps.Id);
            }
    
            // Get associated Permission Set Groups
            for (PermissionSetGroupComponent psg : [
                SELECT PermissionSetGroupId 
                FROM PermissionSetGroupComponent 
                WHERE PermissionSet.Name = :psApiName
            ]) {
                psIds.add(psg.PermissionSetGroupId);
            }
    
            permissionSetIdCache.put(psApiName, psIds);
        }
    
        // Query user assignments — direct or via group
        List<PermissionSetAssignment> userAssignments = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId
            AND (PermissionSetId IN :permissionSetIdCache.get(psApiName)
                OR PermissionSetGroupId IN :permissionSetIdCache.get(psApiName))
            LIMIT 1
        ];
    
        return !userAssignments.isEmpty();
    }

    // Evaluate the File Event
    //
    private boolean evaluateFileEvent(FileEventStore fileEvent) {

        // Is TSP File Event detection feature switch enabled?
        if (!isFeatureEnabledDetectFileEvents()) {
            return false; // nope
        }

        // Is the File of interest to us
        if (!isFileEventOfInterest(fileEvent)) {
            return false; // nope
        }    

        // File is of interest, so post a notification to user
        FileEventInAppNotification aFileEventInAppNotification = new FileEventInAppNotification(fileEvent);
        System.enqueueJob(aFileEventInAppNotification);

        return true;
    }

    // Check feature switch for File Events
    //
    private boolean isFeatureEnabledDetectFileEvents() {
        Feature_Switch_TSP__c cs = Feature_Switch_TSP__c.getOrgDefaults();
        return cs.Detect_File_Events__c;
    }

    // Return true of this event relates to a file of interest
    //
    private boolean isFileEventOfInterest(FileEventStore fileEvent) {

        // Only interested in previews and downloads by UI users
        if (!fileEvent.FileAction.contains('UI_DOWNLOAD') && !fileEvent.FileAction.contains('PREVIEW')) {
            return false;
        }

        // Ignore files that have been archived by File Mover utility
        for (ContentDocument cd : [SELECT Id, Title FROM ContentDocument WHERE Id = :fileEvent.DocumentId]) {
            if (cd.Title.startsWith(ArchiveDocumentUtilities.ARCHIVE_TITLE_PREFIX))  {
                return false;
            }
        }

        // Only interested in files associated to contacts 
        Boolean fileAssociatedToContact = false;
        for (ContentDocumentLink cdl : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :fileEvent.DocumentId]) {
            if (String.valueOf(cdl.LinkedEntityId).substring(0,3) == '003') {
                fileAssociatedToContact = true;
                break;
            }
        }
        if (!fileAssociatedToContact) {
            return false;
        }

        // If we get here we have a file of interest
        return true;
    }

    // Async class to post in app message to user
    //
    public class FileEventInAppNotification implements Queueable {
        private FileEventStore fileEvent;
        private ContentVersion contentVersion;
    
        public FileEventInAppNotification(FileEventStore fileEvent) {
            this.fileEvent = fileEvent;
            this.contentVersion = [
                SELECT Id, Title 
                FROM ContentVersion 
                WHERE ContentDocumentId =:fileEvent.DocumentId AND IsLatest = true
            ];
        }
    
        public void execute(QueueableContext context) {

            // Get the Id for our custom notification type
            CustomNotificationType notificationType = [
                SELECT Id, DeveloperName 
                FROM CustomNotificationType 
                WHERE DeveloperName=:CUSTOM_NOTIFICATION_API_NAME
            ];
        
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
    
            // Set the contents for the notification
            notification.setTitle('File ' + fileAction() + ': ' + this.contentVersion.Title); 
            notification.setBody(readStaticResource(FILE_NOTIFICATION_CONTENT_RESOURCE));
    
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(DUMMY_TARGET_RECORD_ID); // Dummy record id needed
            
            // Actually send the notification
            try {
                Set<String> recipientIds = new Set<String>();
                recipientIds.add(fileEvent.userId);
                notification.send(recipientIds);
            }
            catch (Exception e) {
                LogUtilityException.logExceptionMSG('TSP_EventsToBlock.FileEventInAppNotification', 'UserId ' + fileEvent.userId, e.getMessage());
            }
        }

        private string fileAction() {
            String fileAction = 'Accessed';
            if (fileEvent.FileAction.contains('UI_DOWNLOAD')) {
                fileAction = 'Downloaded';
            } 
            if (fileEvent.FileAction.contains('PREVIEW')) {
                fileAction = 'Viewed';
            } 
            return fileAction;
        }
    }

    // Return content of static resource 
    //
    private static String readStaticResource(String resourceName) {
        String content = '';
        for (StaticResource srObject : [select id,body from StaticResource Where Name = :resourceName]) {
            content = srObject.body.toString();
        }
        return content;
    }
}