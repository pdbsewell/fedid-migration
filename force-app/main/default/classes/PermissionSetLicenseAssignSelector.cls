/**
 * @description Selector for PermissionSetLicenseAssign
 */
public inherited sharing class PermissionSetLicenseAssignSelector 
        extends BaseSelector {

    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return PermissionSetLicenseAssign.sObjectType;
    }

    /**
     * @description Query Permission Set License Assign by user ID and license Id
     * @param userIds A set of userIds
     * @param licenseId The licenseId of the permission set license
     * @return Returns a list of Permission Set License Assign
     */
    public List<PermissionSetLicenseAssign> selectPermissionSetLicenseAssignByUserIdsAndLicenseId(
            Set<Id> userIds, Id licenseId) {
        
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE PermissionSetLicenseId = :licenseId AND AssigneeId IN :userIds', 
            new List<String>{
                    getFieldListString(),                  
                    getSObjectName()
            }
        );
        return (List<PermissionSetLicenseAssign>) Database.query(queryString);      
    }

}