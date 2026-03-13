/**
 * @description Service for handling Salesforce Permission Set licenses
 * @group Permission Set Licenses
 */
public inherited sharing class PermissionSetLicenseService {
    
    private Dao permissionSetLicenseAssignDao;
    private PermissionSetLicenseSelector permissionSetLicenseSelector;
    private PermissionSetLicenseAssignSelector permissionSetLicenseAssignSelector;

    /**
     * @description Constructor for setting class dependencies
     * @param permissionSetLicenseAssignDao Data access object for Permission Set License selector
     * @param permissionSetLicenseSelector The permission set license selector
     * @param PermissionSetLicenseAssignSelector The permission set license assign selector
     */
    public PermissionSetLicenseService(
        Dao permissionSetLicenseAssignDao, 
        PermissionSetLicenseSelector permissionSetLicenseSelector,
        PermissionSetLicenseAssignSelector permissionSetLicenseAssignSelector
    ) {
        this.permissionSetLicenseAssignDao = permissionSetLicenseAssignDao;
        this.permissionSetLicenseSelector = permissionSetLicenseSelector;
        this.permissionSetLicenseAssignSelector = permissionSetLicenseAssignSelector;
    }

    /**
     * @description Provisions permission set licenses to users
     * Throws an InsufficientPermSetLicenseException exception if there are not 
     * enough free licenses
     * @param users A set of users to give the permission set license to
     * @param permissionSetLicenseDeveloperName The permission set license developer name 
     */
    public void provisionPermissionSetLicense(Set<User> users, 
            String permissionSetLicenseDeveloperName) {

        PermissionSetLicense permissionSetLicense = 
            this.retrievePermSetLicense(permissionSetLicenseDeveloperName);
            
        /* 
        Check if users already have license, if so, skip these users
        A duplicate error is thrown by Salesforce if we try to give the user 
        a license and they already have one
        */
        Set<User> usersToProvisionLicense = new Set<User>();
        Map<User, Boolean> usersByHasLicenseState = 
            this.isLicenseAlreadyProvisioned(users, 
                permissionSetLicenseDeveloperName
            );
        for (User user : usersByHasLicenseState.keySet()) {
            if (usersByHasLicenseState.get(user) == false) {
                usersToProvisionLicense.add(user);
            }
        }

        if (usersToProvisionLicense.size() > 
                this.remainingFreeLicenses(permissionSetLicense)) {
			nebula.logger.error('Unable to assign ' +  permissionSetLicense.MasterLabel, new list<user>(usersToProvisionLicense));
            throw new InsufficientPermSetLicenseException(
                'Not enough remaining licenses to provision for all users ' 
                + 'requested. Requested: ' + 
                String.valueOf(usersToProvisionLicense.size())
                + ' licenses, but system has: ' + 
                String.valueOf(this.remainingFreeLicenses(permissionSetLicense))
                + ' remaining licenses for: ' + permissionSetLicense.MasterLabel
            );    
        }

        List<PermissionSetLicenseAssign> permissionSetLicensesToProvision = new List<PermissionSetLicenseAssign>();
        for (User user : usersToProvisionLicense) {
            PermissionSetLicenseAssign permissionSetLicenseAssign = new PermissionSetLicenseAssign();
            permissionSetLicenseAssign.AssigneeId = user.Id;
            permissionSetLicenseAssign.PermissionSetLicenseId = permissionSetLicense.Id;
            permissionSetLicensesToProvision.add(permissionSetLicenseAssign);
        }
        // Upserts do not work, hence we need to do all this search and insert
        permissionSetLicenseAssignDao.insertRecords(permissionSetLicensesToProvision);
    }

    /**
     * @description Determines if users already has a permission set license assigned
     * @param users A set of users to check for
     * @param permissionSetLicenseDeveloperName The permission set license developer name
     * @return Returns a map of users and whether they already have a license
     * True indicates that the user already has a license
     */
    public Map<User, Boolean> isLicenseAlreadyProvisioned(Set<User> users, 
            String permissionSetLicenseDeveloperName) {

        Map<User, Boolean> licenseProvisionStateByUser = new Map<User, Boolean>();

        PermissionSetLicense permissionSetLicense = 
            this.retrievePermSetLicense(permissionSetLicenseDeveloperName);

        List<PermissionSetLicenseAssign> licensesAssigned = 
            this.permissionSetLicenseAssignSelector
                .selectPermissionSetLicenseAssignByUserIdsAndLicenseId(
                    this.extractUserIdsFromUsers(users), 
                    permissionSetLicense.Id
                );

        Set<Id> userIdsWithLicense = new Set<Id>();

        for (PermissionSetLicenseAssign licenseAssigned : licensesAssigned) {
            userIdsWithLicense.add(licenseAssigned.AssigneeId);
        }

        for (User user : users) {
            if (userIdsWithLicense.contains(user.Id)) {
                licenseProvisionStateByUser.put(user, true);
            } else {
                licenseProvisionStateByUser.put(user, false);
            }
        }
        return licenseProvisionStateByUser;
    }

    /**
     * @description Retrieves the Permission Set License record
     */
    private PermissionSetLicense retrievePermSetLicense(
            String permissionSetLicenseDeveloperName) {
        List<PermissionSetLicense> permissionSetLicenses = 
            this.permissionSetLicenseSelector
                .selectActivePermissionSetLicenseByDeveloperName(
                    permissionSetLicenseDeveloperName
                );
        if (permissionSetLicenses.isEmpty()) {
            throw new NoPermSetLicenseFoundException(
                'Active Permission Set License not found for developerName: '
                + permissionSetLicenseDeveloperName
            );
        }
        return permissionSetLicenses[0];
    }

    /**
     * @description Returns a set of userIds from a set of User records
     */
    private Set<Id> extractUserIdsFromUsers(Set<User> users) {
        Set<Id> userIds = new Set<Id>();
        for (User user : users) {
            userIds.add(user.Id);
        }
        return userIds;
    }

    /**
     * @description Returns the number of licenses remaining for a permission 
     * set license
     */
    private Integer remainingFreeLicenses(PermissionSetLicense permissionSetLicense) {
        return permissionSetLicense.TotalLicenses - permissionSetLicense.UsedLicenses;
    }
}