/**
 * @description Selector class for User object
 * @group       Selectors
 */
public inherited sharing class UsersSelector extends BaseSelector {
    public UsersSelector() {
        super(false);
    }
    
    public UsersSelector(Boolean newOverrideObjectPermissions) {
        super(newOverrideObjectPermissions);
    }

    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return User.sObjectType;
    }

    /**
     * @description Returns users based on contact Ids (for users that are 
     * community users)
     */
    public List<User> selectUsersByContactId(List<Id> contactIds) {
        List<User> users = new List<User>();
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE ContactId IN :contactIds', 
            new List<String>{
                    getFieldListString(),                  
                    getSObjectName()
            }
        );
        System.debug('-- queryString: ' + queryString);
        return (List<User>) Database.query(queryString);
    }
}