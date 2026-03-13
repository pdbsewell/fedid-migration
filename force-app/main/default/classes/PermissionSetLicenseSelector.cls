/**
 * @description Selector for PermissionSetLicense
 * This selector can be used to query Permission Set Licenses in the org
 */
public inherited sharing class PermissionSetLicenseSelector 
        extends BaseSelector {
    
    /**
     * @description Returns the object type
     */
    public Schema.SObjectType getSObjectType() {
        return PermissionSetLicense.sObjectType;
    }

    /**
     * @description Query active permission set licenses by developer name
     * @param developerName Developer name of the permission set license to be queried
     * @return Returns a list of Permission Set License
     */
    public List<PermissionSetLicense> selectActivePermissionSetLicenseByDeveloperName(String developerName) {
        String activeStatus = 'Active';
        String queryString = String.format(
            'SELECT {0} FROM {1} WHERE DeveloperName = :developerName AND Status = :activeStatus', 
            new List<String>{
                    getFieldListString(),                  
                    getSObjectName()
            }
        );
        return (List<PermissionSetLicense>) Database.query(queryString);
    }

}