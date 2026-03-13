/**
 * @author Peter Sewell
 * @date 20/09/2021
 * @description Class to send alerts when user with Break Glass Profile is inserted, updated or logs in
 * @revision
 */
public without sharing class BreakGlassAlert {
    static final String ALERT_CATEGORY = 'SECOPS';
    static final String SERVICE_NAME_PREFIX = 'SFDC';
    static final String BREAK_GLASS_CFG_NAME = 'BREAK_GLASS_ALERT';
    // Set of alert types
    static final Set<String> alertTypes = new Set<String>{
        'BREAK_GLASS_LOGIN',
        'BREAK_GLASS_LOGOUT',
        'BREAK_GLASS_USER_INSERT',
        'BREAK_GLASS_USER_UPDATE'
    };
    // List of alerts to emit
    List<BreakGlassAlert.Alert> alerts = new List<BreakGlassAlert.Alert>();
    // Constructor
    public BreakGlassAlert() {}

    // Class to hold parameters passed to the invocable method below
    public class BreakGlassAlertInputs {
        @InvocableVariable(required=true)
        Public String alertType;
        @InvocableVariable(required=true)
        Public String message;
    }

    /**
     * @author Peter Sewell
     * @date 20/09/2021
     * @description Method to send alerts when user with Break Glass Profile is inserted, updated or logs in
     * @param Complex class holding 'type' of alert and a 'message' to send with the alert
     */
    @InvocableMethod(label='Sends break-glass alert to email and end-point')
    public static void sendAlert(List<BreakGlassAlertInputs> details) {
        BreakGlassAlert bg = new BreakGlassAlert();
        for (BreakGlassAlertInputs detail : details) {
            bg.add(detail.alertType, detail.message );
        }
        bg.emit();
    }

    // Add an alert to the send list, with message
    public void add(String theType, String msg) {
        if (alertTypes.contains(theType)) {
            alerts.add(new Alert(theType, msg));
        }
    }

    /**
     * @author Peter Sewell
     * @date 20/09/2021
     * @description Method to publish all alerts in the alert list as Platform Events
     */
    public void emit() {
        List<BreakGlassAlert__e> alertEvents = new List<BreakGlassAlert__e>();
        // Limit DML by updating isProd in bulk off a single SELECT
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        for (BreakGlassAlert.Alert alert : alerts) {
            alert.isProd = !runningInASandbox;
            String alertJson = JSON.serialize(alert);
            alertEvents.add(new BreakGlassAlert__e(alertJson__c=alertJson));
        }
        alerts.clear();
        if (alertEvents != null) {
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(alertEvents);
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    // Log success
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }
            }
        }
    }
    /**
     * @description createEmailAlert Creates Email Contents
     * @author pvic0002
     * @param  alert     alert description
     * @param  emailFrom emailFrom description
     * @param  emailTo   emailTo description
     * @return           return description
     */
    public static Messaging.SingleEmailMessage createEmailAlert(BreakGlassAlert.Alert alert, String emailFrom, String emailTo) {
        if (Test.isRunningTest()) {
            emailTo = 'noreply@salesforce.com'; // we dont want to really send an email
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :emailFrom];
        if (owea.size() > 0) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        mail.setToAddresses(new String[] {emailTo});
        // mail.setSenderDisplayName('Break Glass Alert');
        mail.setSubject('Salesforce UniCRM Break Glass User Alert');
        String messageBody = '<html><body>';
        messageBody += '<p>Break Glass Admin user activity has been detected:</p>';
        messageBody += '<p><strong>' + alert.category + ':' + alert.type + ' </strong></p>';
        messageBody += '<p><strong>UTC Time: </strong>' + alert.timeStamp + '</p>';
        messageBody += '<p><strong>Service: </strong>' + alert.service + '</p>';
        messageBody += '<p><strong>Prod?: </strong>' + alert.isProd + '</p>';
        messageBody += '<p><strong>User: </strong>' + alert.userName + '</p>';
        messageBody += '<p><strong>IP: </strong>' + alert.ipAddress + '</p>';
        messageBody += '<p><strong>Message: </strong>' + alert.message + '</p>';
        messageBody += '<p></p>';
        messageBody += '<p><small>Please do not reply directly to this email. Support will not receive any reply messages to this email.</small></p>';
        messageBody += '</body></html>';
        mail.setHtmlBody(messageBody);
        return mail;
    }
     /**
     * @author Peter Sewell
     * @date 20/09/2021
     * @description Method to send an alert as an email
     * @param alert The alert payload to email
     * @param emailFrom The FROM address in the email (must be on the org wide address list)
     * @param emailTo The TO address in the email (where the alert will be sent)
     */
    public static void sendEmailAlert(List<Messaging.SingleEmailMessage> mails) {
        if (mails != null && !mails.isEmpty()) {
            List<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(mails);
            LogUtilityException.logEmailErrors(emailResult);
        }
    }
    /**
     * @author Peter Sewell
     * @date 20/09/2021
     * @description Method to POST an alert as a callout to a named credential
     * @param alertJson The alert payload in Json format
     * @param namedCredential The named credential to POST to
     */
    @future (callout=true)
    public static void sendCalloutAlert(String alertJson, String namedCredential) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + namedCredential);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody(alertJson);
        Http http = new Http();
        HTTPResponse res = http.send(req);
    }

    /**
     * @author Peter Sewell
     * @date 20/09/2021
     * @description Handle platform event trigger logic
     * @param alerts The alert event payload from the platform event
     */
    public static void handleAlertEvent(List<BreakGlassAlert__e> events) {
        // Get distribution details from Custom Metadata
        Map<String,String> bgd = getBreakGlassAlertParams();
        if (!bgd.isEmpty()) {
            String namedCredential = bgd.containsKey('NAMED_CREDENTIAL') ? bgd.get('NAMED_CREDENTIAL'):'';
            String emailFrom = bgd.containsKey('FROM_EMAIL') ? bgd.get('FROM_EMAIL') : '';
            String emailToList = bgd.containsKey('TO_EMAIL_LIST') ? bgd.get('TO_EMAIL_LIST') : '';
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<String> emailToAddresses = new List<String>();
            if (emailToList != null) {
                emailToAddresses = emailToList.split(',');
            }
            // Iterate through each alert
            for (BreakGlassAlert__e event : events) {
                BreakGlassAlert.Alert alert = (BreakGlassAlert.Alert) JSON.deserialize(event.alertJson__c, BreakGlassAlert.Alert.class);
                if (namedCredential != null) {
                    BreakGlassAlert.sendCalloutAlert(event.alertJson__c, namedCredential);
                }
                for (String emailTo : emailToAddresses) {
                    emails.add(
                        BreakGlassAlert.createEmailAlert(alert, emailFrom, emailTo)
                        );
                }
            }
            //Sends Email
            BreakGlassAlert.sendEmailAlert(emails);
        }
    }
     /**
     * @author RANAND
     * @date 01/08/2022
     * @description get configurable email parameters from System Settings metadata
     */
    public Static Map<String, String> getBreakGlassAlertParams(){
        Map<String, String> keyValuePair = new Map<String, String>();
        List<System_Settings__mdt> breakGlassMetadatas = SystemSettingsUtil.getInstance().getByFeature(BREAK_GLASS_CFG_NAME);
        if(!breakGlassMetadatas.isEmpty()){
            for(System_Settings__mdt objSettings : breakGlassMetadatas){
                keyValuePair.put(objSettings.Key__c, objSettings.Value__c);
            }
        }
        return keyValuePair;
    }
    
    // Represents a break-glass alert event
    public class Alert {
        public Datetime timeStamp;
        public String category;
        public String type;
        public String service;
        public String userName;
        public String ipAddress = '0.0.0.0';
        public Boolean isProd;
        public String message;
        Public Alert(String theType, String msg) {
            // Auto populate the alert payload from UserInfo and Auth.SessionManagement
            timeStamp = Datetime.now();
            category = ALERT_CATEGORY;
            type = theType;
            service = SERVICE_NAME_PREFIX + ':' + UserInfo.getOrganizationId();
            userName = UserInfo.getUserName();
            if (!Test.isRunningTest()) {
                Map<String, String> session = Auth.SessionManagement.getCurrentSession();
                if (session.containsKey('SourceIp')) {
                    ipAddress = session.get('SourceIp');
                }
            }
            isProd = false; // gets changed to actual value later in @future doEmit call
            message = msg;
        }
    }
}