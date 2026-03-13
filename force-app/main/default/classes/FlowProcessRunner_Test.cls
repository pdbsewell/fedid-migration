@IsTest
public with sharing class FlowProcessRunner_Test {

    @IsTest
    private static void whenFlowProcessEndsExpectsResponse() {
        CustomNotification notification = new CustomNotification();
        notification.type('BatchApexError')
                    .title('Batch Error')
                    .body('Some useful information')
                    .sendToCurrentUser();
        Assert.areEqual(notification.notificationTypeName, 'BatchApexError');
    }
}