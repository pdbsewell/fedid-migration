/**
 * Fun basic example of what an Apex Custom Notification API might look like! 
 *
    new CustomNotification()
        .type('BatchApexError')
        .title('Batch Error')
        .body('Some useful information')
        .sendToCurrentUser();
 */
public inherited sharing class CustomNotification {

    @TestVisible private String notificationTypeName;
    @TestVisible private String notificationBody;
    @TestVisible private String notificationTitle;
    @TestVisible private List<Id> recipientIds;
    @TestVisible private Id targetId;
    @TestVisible private Id senderId; 

    public CustomNotification() {
        this.targetId = UserInfo.getUserId();
    }    

    public CustomNotification type(String type) {
        this.notificationTypeName = type;
        return this;
    }

    public CustomNotification title(String title) {
        this.notificationTitle = title;
        return this;
    }

    public CustomNotification body(String body) {
        this.notificationBody = body;
        return this;
    }

    public CustomNotification sendToCurrentUser() {
        this.recipientIds = new List<ID> { UserInfo.getUserId() };
        return send();
    }
    
    public CustomNotification send() {
        // Until there is an Apex API for Custom Notification 
        //   delegage to an Autolaunch Flow wrapper
        new FlowProcess()
            .named('SendCustomNotification')
            .with('CustomNotificationTypeName', this.notificationTypeName)
            .with('NotificationBody', this.notificationBody)
            .with('NotificationTitle', this.notificationTitle)
            .with('RecipientIds', this.recipientIds)
            .with('TargetId', this.targetId)
            .run(); 
        return this;       
    }
}