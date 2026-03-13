/**
 * @author          Shalini Mendu
 * @description     Test coverage for class ZkipConstants
 * @revision
 * 		2025-17-08 - Sachin Shetty	- 	Formatting
 **/
@isTest(isParallel=true)
public class ZkipConstants_Test {

    @isTest
    static void testStaticVariableAssignments() {
        ZkipConstants con = new ZkipConstants(); //NOPMD
        Assert.areEqual('callout:', ZkipConstants.ENDPOINT_PREFIX);
        Assert.areEqual('GET', ZkipConstants.METHOD_GET);
        Assert.areEqual('POST', ZkipConstants.METHOD_POST);
        Assert.areEqual('PATCH', ZkipConstants.METHOD_PATCH);
        Assert.areEqual('Bearer ', ZkipConstants.API_ACCESS_KEY_PREFIX);
        Assert.areEqual('application/json', ZkipConstants.CONTENT_TYPE_JSON);
        Assert.areEqual('guests', ZkipConstants.GUEST_TYPE);
        Assert.areEqual('guest-lists', ZkipConstants.GUEST_LIST_TYPE);
        Assert.areEqual('UniCRM Campaign Member Id', ZkipConstants.CUSTOM_FIELD_VALUES_UNICRM_CAMPMEMBID);
        Assert.areEqual('Title', ZkipConstants.CUSTOM_FIELD_VALUES_TITLE);
        Assert.areEqual('Invitee', ZkipConstants.CUSTOM_FIELD_VALUES_INVITEE);
        Assert.areEqual('Suffix 1', ZkipConstants.CUSTOM_FIELD_VALUES_SUFFIX1);
        Assert.areEqual('Guest', ZkipConstants.CUSTOM_FIELD_VALUES_GUESTPARTNER);
        Assert.areEqual('Position', ZkipConstants.CUSTOM_FIELD_VALUES_POSITIONS);
        Assert.areEqual('Dietary Requirements', ZkipConstants.CUSTOM_FIELD_VALUES_DIETREQ);
        Assert.areEqual('Accessibility Requirements', ZkipConstants.CUSTOM_FIELD_VALUES_ACCESSIBILITYREQ);
        Assert.areEqual('Error! Missing Campaign Id', ZkipConstants.ERR_MISSING_CAMPID);
        Assert.areEqual('Error! Missing Custom Setting. Please contact your administrator.', ZkipConstants.ERR_MISSING_SETTING);
        Assert.areEqual('Error! Problem while doing callout. Please contact your administrator.', ZkipConstants.ERR_CALLOUT);
        Assert.areEqual('Error! Event already exists in zkipster.', ZkipConstants.ERR_EVENT_ALRDY_CREATED);
        Assert.areEqual('Error! Event do not exists in Zkipster. Please create first, by clicking Create Event. Thanks!', ZkipConstants.ERR_EVENT_NOT_EXISTS);
        Assert.areEqual('Error! Guest List do not exists in Zkipster. Please create first, by clicking Create Guest List. Thanks!', ZkipConstants.ERR_GUEST_LIST_NOT_EXISTS);
        Assert.areEqual('Error! No Guest List to create in zkipster.', ZkipConstants.ERR_NO_GUEST_LIST_TO_CREATE);
        Assert.areEqual('Error! All Guest List already exists in Zkipster.', ZkipConstants.ERR_ALL_GUEST_LIST_EXISTS);
        Assert.areEqual('Event successfully created in zkipster.', ZkipConstants.SUCC_CREATE_EVENT);
        Assert.areEqual('Error! No Guest List to create in zkipster.', ZkipConstants.ERR_NO_GUEST_LIST_TO_CREATE);
        Assert.areEqual('Event successfully updated in zkipster.', ZkipConstants.SUCC_UPDATE_EVENT);
        Assert.areEqual('Guest Lists successfully created in zkipster.', ZkipConstants.SUCC_CREATE_GUEST_LIST);
        Assert.areEqual('Getting updates from Zkipster started. Please refresh the page.', ZkipConstants.SUCC_GET_UPDATES);
        Assert.areEqual('Error! Getting updates from Zkipster is in progress.', ZkipConstants.ERR_GET_UPDATES);
        Assert.areEqual('Synchronizing Members started. Please refresh the page.', ZkipConstants.SUCC_SYNC_INITIATED);
        Assert.areEqual('Error! Synchronisation Members is in progress.', ZkipConstants.ERR_SYNC_IN_PROGRESS);
        Assert.areEqual('Error! Event already started. Updating details is not allowed.', ZkipConstants.ERR_EVENT_START_DATE_PAST);
        Assert.areEqual('Error! Event already completed.', ZkipConstants.ERR_EVENT_STATUS_COMPLETED);
        Assert.areEqual('Completed', ZkipConstants.CAMP_STATUS_COMPLETED);
    }
}