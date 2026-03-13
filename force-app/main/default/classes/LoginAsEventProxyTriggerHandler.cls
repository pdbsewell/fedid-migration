/**
 * @description       : Trigger handler class for LoginAsEventProxy__e platform events.
 * @author            : Peter Sewell
 * @group             : Trigger Handler
 * @last modified on  : 2022-01-16
 * @last modified by  : Peter Sewell
 * Modifications Log 
 * Ver   Date         Author          Modification
 * 1.0   2022-01-16   Peter Sewell   Initial Version
**/
public class LoginAsEventProxyTriggerHandler implements PlatformEventTrigger.HandlerExtended {

    public static final string ELEVATED_PRIVILEGES_CP_NAME = 'ElevatedPrivilegesUser';
    List<user> usersWithElevatedPrivs;
    string sourceUsername = null;  // username of user doing the login as
    string targetUsername = null;  // username of the user being logged in as
    string targetUserId = null;    // id of the user being logged in as

    public LoginAsEventProxyTriggerHandler() {
        usersWithElevatedPrivs = getUsersWithCustomPermission(ELEVATED_PRIVILEGES_CP_NAME);
    }

    public void process(SObject rec) {
        LoginAsEventProxy__e evt = (LoginAsEventProxy__e) rec;
        sourceUsername = evt.DelegatedUsername__c;
        targetUsername = evt.Username__c;
        targetUserId = evt.UserId__c;
        system.debug('*** Login As event received');
    }

    public void execute() {
        doExecute();
    }

    private void doExecute() {
        
        try {
            // If user WITHOUT elevated privs CP assigned attempts to login as user WITH elevated privs CP assigned, 
            // then kill the logged-in-as user session
            if (!isElevatedPrivs(sourceUsername, usersWithElevatedPrivs) && 
                isElevatedPrivs(targetUsername, usersWithElevatedPrivs)) {
                system.debug('****** Login-as invalid, kill session for ' + targetUsername);
                if (!Test.isRunningTest()) {
                    // Kill the session of the logged-in-as user
                    delete [Select Id from AuthSession WHERE UsersId = :targetUserId AND SessionType='SubstituteUser'];
                }
            } 
        } catch(Exception e) {
            LogUtilityException.logException(e, 'Could not kill "logged in as" user session');
        }
    }

    private static List<User> getUsersWithCustomPermission(String name) {
        Set<Id> permissionSetIds = new Set<Id>();
        for (SetupEntityAccess access : [
            SELECT ParentId 
            FROM SetupEntityAccess 
            WHERE SetupEntityId IN (
                SELECT Id 
                FROM CustomPermission 
                WHERE DeveloperName = :name
            )
        ]) {
            permissionSetIds.add(access.ParentId);
        }
        return permissionSetIds.isEmpty() ? new List<User>() : [
            SELECT Id, Name, Username FROM User WHERE Id IN (
                SELECT AssigneeId FROM PermissionSetAssignment
                WHERE PermissionSetId IN :permissionSetIds
            )
        ];
    }

    private static boolean isElevatedPrivs(String username, List<user> usersWithElevatedPrivs) {
        boolean retval = false;

        for (user u : usersWithElevatedPrivs) {
            if (u.Username == username) {
                retval = true;
                break;
            }
        }
        
        return retval;
    }
    /*
    // Demo node client code to republish LoginAsEventStream events to LoginAsEventProxy__e
    // Uses jsforce module
    var jsforce = require('jsforce');
    var username = 'yourusername';
    var password = 'yourpasswordandtoken';
    var conn = new jsforce.Connection({
        loginUrl : 'https://test.salesforce.com',
        clientId : 'yourclientid',
        clientSecret : 'yourclientsecret',
        redirectUri : 'https://test.salesforce.com/services/oauth2/callback'
    });
    conn.login(username, password, function(err, userInfo) {
        if (err) { return console.error(err); }
        console.log('waiting');
        conn.streaming.topic("/event/LoginAsEventStream").subscribe(function(message) {
            console.dir(message.payload);
            let p = message.payload;
            conn.requestPost('/services/data/v53.0/sobjects/LoginAsEventProxy__e/',
                {
                    Application__c: p.Application,
                    Browser__c: p.Browser,
                    DelegatedOrganizationId__c: p.DelegatedOrganizationId,
                    DelegatedUsername__c: p.DelegatedUsername,
                    EventDate__c: p.EventDate,
                    EventIdentifier__c: p.EventIdentifier,
                    LoginAsCategory__c: p.LoginAsCategory,
                    LoginHistoryId__c: p.LoginHistoryId,
                    LoginKey__c: p.LoginKey,
                    LoginType__c: p.LoginType,
                    Platform__c: p. Platform,
                    SessionKey__c: p.SessionKey,
                    SessionLevel__c: p.SessionLevel,
                    SourceIp__c: p.SourceIp,
                    TargetUrl__c: p.TargetUrl,
                    UserId__c: p.UserId,
                    Username__c: p.Username,
                    UserType__c: p.UserType
                },
                {},
                function(err, response) {
                    console.log('republished');
                    console.log(response);
            });
        });
    });
    */
}