/**
 * @description Test class for PermissionSetLicenseService
 */
@isTest(isParallel=true)
public class PermissionSetLicenseService_Test {
    
    private static final String CPQ_PERM_SET_LICENSE_DEV_NAME = 
        'SalesforceCPQ_CPQStandardPerm';

    private static final String EINSTEIN_AGENT_LICENSE_DEV_NAME = 
        'EinsteinAgentPsl';

    private static final Id CPQ_PERMSET_LICENSE_ID = 
        FakeRecordIdGenerator.generateId(
            PermissionSetLicense.getSObjectType()
        );

    private static final Id EINSTEIN_AGENT_PERMSET_LICENSE_ID = 
        FakeRecordIdGenerator.generateId(
            PermissionSetLicense.getSObjectType()
    );

    private static final User USER_1_NO_CPQ_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user1withoutcpqlicense@test.com'  
    );

    private static final User USER_2_WITH_CPQ_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user2withcpqlicense@test.com'
    );

    private static final User USER_3_WITH_CPQ_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user3withcpqlicense@test.com'
    );

    private static final User USER_4_WITH_CPQ_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user4withcpqlicense@test.com'
    );

    private static final User USER_5_NO_CPQ_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user5withoutcpqlicense@test.com'
    );

    private static final User USER_6_NO_EIN_AGT_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user6withouteinagtlicense@test.com'
    );

    private static final User USER_7_NO_EIN_AGT_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user7withouteinagtlicense@test.com'
    );

    private static final User USER_8_WITH_EIN_AGT_LICENSE = userRecordGenerator(
        FakeRecordIdGenerator.generateId(
        User.getSObjectType()),
        'user8witheinagtlicense@test.com'
    );

    /**
     * @description Ensure that the isLicenseAlreadyProvisioned method is 
     * correctly stating that the user has a CPQ license for a user that 
     * already has the CPQ license
     */
    @isTest
    static void shouldCheckUserLicenseStateCorrectlyWhenUserHasCpqLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        Map<User, Boolean> result = 
            permissionSetLicenseService.isLicenseAlreadyProvisioned(
                new Set<User>{USER_2_WITH_CPQ_LICENSE}, 
                CPQ_PERM_SET_LICENSE_DEV_NAME
            );

        System.assertEquals(true, result.values()[0], 
            'Expected true because user does have a CPQ Permission Set License'
        );
        Test.stopTest();
    }

    /**
     * @description Ensure that the isLicenseAlreadyProvisioned method is 
     * correctly stating that the user does not have a CPQ license for a user that 
     * does not have a CPQ license
     */
    @isTest
    static void shouldCheckUserLicenseStateCorrectlyWhenUserDoesNotHaveCpqLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        Map<User, Boolean> result = 
            permissionSetLicenseService.isLicenseAlreadyProvisioned(
                new Set<User>{USER_1_NO_CPQ_LICENSE}, 
                CPQ_PERM_SET_LICENSE_DEV_NAME
            );

        System.assertEquals(false, result.values()[0], 
            'Expected false because user does not have a CPQ Permission Set License'
        );
        Test.stopTest();
    }

    /**
     * @description Ensure that the isLicenseAlreadyProvisioned method is 
     * correctly stating that the two users don't has a CPQ license when both 
     * users don't have the license
     */
    @isTest
    static void shouldCheckUsersLicenseStateCorrectlyWhenTwoUserDoNotHaveCpqLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        Map<User, Boolean> result = 
            permissionSetLicenseService.isLicenseAlreadyProvisioned(
                new Set<User>{
                    USER_1_NO_CPQ_LICENSE,
                    USER_5_NO_CPQ_LICENSE
                }, 
                CPQ_PERM_SET_LICENSE_DEV_NAME
            );
        Test.stopTest();

        // Both users should not have license
        boolean hasLicense = false;
        for (Boolean userHasLicense : result.values()) {
            if (userHasLicense) {
                hasLicense = true;
            }
        }

        System.assertEquals(false, hasLicense, 
            'Expected false because both user does not have a CPQ Permission Set License'
        );
    }

    /**
     * @description Ensure that the isLicenseAlreadyProvisioned method is 
     * correctly stating that the two users both have a CPQ license when both 
     * users both have the license
     */
    @isTest
    static void shouldCheckUsersLicenseStateCorrectlyWhenTwoUserHaveCpqLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        Map<User, Boolean> result = 
            permissionSetLicenseService.isLicenseAlreadyProvisioned(
                new Set<User>{
                    USER_3_WITH_CPQ_LICENSE,
                    USER_4_WITH_CPQ_LICENSE
                }, 
                CPQ_PERM_SET_LICENSE_DEV_NAME
            );
        Test.stopTest();

        // Both users should not have license
        boolean hasLicense = false;
        for (Boolean userHasLicense : result.values()) {
            if (userHasLicense) {
                hasLicense = true;
            } else {
                hasLicense = false;
            }
        }

        System.assertEquals(true, hasLicense, 
            'Expected true because both user have a CPQ Permission Set License'
        );
    }

    /**
     * @description Ensure that the isLicenseAlreadyProvisioned method is 
     * correctly stating that one of two users has CPQ license when only one 
     * of the two actually have the license
     */
    @isTest
    static void shouldCheckUsersLicenseStateCorrectlyWhenOneOfTwoUserHaveCpqLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        Map<User, Boolean> result = 
            permissionSetLicenseService.isLicenseAlreadyProvisioned(
                new Set<User>{
                    USER_1_NO_CPQ_LICENSE,
                    USER_3_WITH_CPQ_LICENSE
                }, 
                CPQ_PERM_SET_LICENSE_DEV_NAME
            );
        Test.stopTest();

        // Both users should not have license
        boolean licenseStateCorrect = false;

        if (result.get(USER_1_NO_CPQ_LICENSE) == false 
                && result.get(USER_3_WITH_CPQ_LICENSE)) {
            licenseStateCorrect = true;
        }

        System.assertEquals(true, licenseStateCorrect, 
            'Expected license state to be correctly returned when one of two users has a CPQ license'
        );
    }

    /**
     * @description Should only create the license when the user doesn't already 
     * have the license
     */
    @isTest
    static void shouldProvisionCPQLicenseToUserWhenUserDoesNotHaveCPQLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();

        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {USER_1_NO_CPQ_LICENSE}, 
            CPQ_PERM_SET_LICENSE_DEV_NAME
        );
        Test.stopTest();

        List<PermissionSetLicenseAssign> cpqPermSetAssignedCreated = 
            permSetLicenseAssignDaoMock.recordsInserted;
        System.assertEquals(
            USER_1_NO_CPQ_LICENSE.Id, 
            cpqPermSetAssignedCreated[0].AssigneeId, 
            'Expected User 1 to be have a permission set assigned created'    
        );

    }

    /**
     * @description Should create the license when the both users doesn't 
     * already have the license
     */
    @isTest
    static void shouldProvisionCPQLicenseToTwoUsersWhenTwoUsersDoesNotHaveCPQLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();

        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {
                USER_1_NO_CPQ_LICENSE,
                USER_5_NO_CPQ_LICENSE
            }, 
            CPQ_PERM_SET_LICENSE_DEV_NAME
        );
        Test.stopTest();

        List<PermissionSetLicenseAssign> cpqPermSetLicensesAssignedCreated = 
            permSetLicenseAssignDaoMock.recordsInserted;
        
        Boolean user1HasLicenseProvisioned = false;
        Boolean user5HasLicenseProvisioned = false;
        for (PermissionSetLicenseAssign license : cpqPermSetLicensesAssignedCreated) {
            if (USER_1_NO_CPQ_LICENSE.Id.equals(license.AssigneeId)) {
                user1HasLicenseProvisioned = true;
            }
            if (USER_5_NO_CPQ_LICENSE.Id.equals(license.AssigneeId)) {
                user5HasLicenseProvisioned = true;
            }
        }
        
        System.assertEquals(
            true, 
            user1HasLicenseProvisioned && user5HasLicenseProvisioned,
            'Expected both users to have the CPQ license provisioned'
        );
    }

    /**
     * @description Should create the license to only the user that doesn't 
     * already have it when two users licenses are requested
     */
    @isTest
    static void shouldProvisionCPQLicenseToOneUserWhenOneOfTwoUsersDoesNotHaveCPQLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();

        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {
                USER_2_WITH_CPQ_LICENSE,
                USER_5_NO_CPQ_LICENSE
            }, 
            CPQ_PERM_SET_LICENSE_DEV_NAME
        );
        Test.stopTest();

        List<PermissionSetLicenseAssign> cpqPermSetLicensesAssignedCreated = 
            permSetLicenseAssignDaoMock.recordsInserted;
        
        Boolean user2HasLicenseProvisioned = false;
        Boolean user5HasLicenseProvisioned = false;
        for (PermissionSetLicenseAssign license : cpqPermSetLicensesAssignedCreated) {
            if (USER_2_WITH_CPQ_LICENSE.Id.equals(license.AssigneeId)) {
                user2HasLicenseProvisioned = true;
            }
            if (USER_5_NO_CPQ_LICENSE.Id.equals(license.AssigneeId)) {
                user5HasLicenseProvisioned = true;
            }
        }
        
        System.assertEquals(true, user5HasLicenseProvisioned,
            'Expected user without CPQ license to have CPQ license provisioned'
        );
        System.assertEquals(false, user2HasLicenseProvisioned,
            'Expected a user that has license to not have CPQ license ' 
            + 'provisioned again'
        );
    }

    /**
     * @description Should not create a license when the user already has it
     */
    @isTest
    static void shouldNotProvisionCPQLicenseAgainIfUserAlreadyHasLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {USER_3_WITH_CPQ_LICENSE}, 
            CPQ_PERM_SET_LICENSE_DEV_NAME
        );

        Test.stopTest();

        System.assertEquals(
            true, 
            permSetLicenseAssignDaoMock.recordsInserted.isEmpty(), 
            'Expected no license to be created because user already has license'    
        );

    }

    /**
     * @description Should not create a license when the both users already 
     * have it
     */
    @isTest
    static void shouldNotProvisionCPQLicenseAgainIfBothUsersAlreadyHaveLicense() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {
                USER_3_WITH_CPQ_LICENSE,
                USER_4_WITH_CPQ_LICENSE
            }, 
            CPQ_PERM_SET_LICENSE_DEV_NAME
        );

        Test.stopTest();

        System.assertEquals(
            true, 
            permSetLicenseAssignDaoMock.recordsInserted.isEmpty(), 
            'Expected no license to be created because both users already have ' 
            + 'the license'    
        );

    }
    
    /**
     * @description There is only 1 free Einstein Agent license but two users
     * do not have the license and are requesting for the licenses. 
     * Expecting InsufficientPermSetLicenseException exception because we can't 
     * give more licenses then the system has free
     */
    @isTest
    static void shouldNotProvisionEinsteinAgentLicensesWhenThereIsNotEnoughLicensesRemaining() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        try {
            permissionSetLicenseService.provisionPermissionSetLicense(
                new Set<User> {
                    USER_6_NO_EIN_AGT_LICENSE,
                    USER_7_NO_EIN_AGT_LICENSE
                }, 
                EINSTEIN_AGENT_LICENSE_DEV_NAME
            );
            System.assert(false, 
                'Expected an InsufficientPermSetLicenseException because there ' 
                + 'is not enough free licenses for the number of users '
                + 'requested.'
            );
        } catch(InsufficientPermSetLicenseException e) {
            System.assert(true, 
                'Expected an InsufficientPermSetLicenseException because there ' 
                + 'is not enough free licenses for the number of users '
                + 'requested.'
            );
        } catch(Exception e) {
            System.assert(false, 
                'Expected InsufficientPermSetLicenseException instead of Exception'
            );
        }
        Test.stopTest();
    }

    /**
     * @description There is only 1 free Einstein Agent license but two users 
     * are requesting for the license. One of those users already have license 
     * so only the user without a license needs it and can use up the last free
     * license
     */
    @isTest
    static void shouldProvisionEinsteinAgentLicensesWhenUsesHasLicenseIsFactoredIn() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();

        permissionSetLicenseService.provisionPermissionSetLicense(
            new Set<User> {
                USER_6_NO_EIN_AGT_LICENSE,
                USER_8_WITH_EIN_AGT_LICENSE
            }, 
            EINSTEIN_AGENT_LICENSE_DEV_NAME
        );

        Test.stopTest();

        List<PermissionSetLicenseAssign> einAgtPermSetAssignedCreated = 
            permSetLicenseAssignDaoMock.recordsInserted;
        
        System.assertEquals(
            USER_6_NO_EIN_AGT_LICENSE.Id, 
            einAgtPermSetAssignedCreated[0].AssigneeId, 
            'Expected User 6 to be have a permission set assigned created'    
        );
    }

    /**
     * @description To check that a custom exception is thrown when the active 
     * license cannot be found
     */
    @isTest
    static void shouldThrowExceptionWhenCheckingUserAndActiveLicenseCannotBeFound() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        Dao permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();
        
        try {
            Map<User, Boolean> result = 
                permissionSetLicenseService.isLicenseAlreadyProvisioned(
                    new Set<User>{USER_2_WITH_CPQ_LICENSE}, 
                    'licensethatdoesnotexist'
                );
            System.assert(false, 
                'Expected NoPermSetLicenseFoundException because the license ' 
                + 'does not exist for the parameter provided'
            );
        } catch (NoPermSetLicenseFoundException e) {
            System.assert(true, 
                'Expected NoPermSetLicenseFoundException because the license ' 
                + 'does not exist for the parameter provided'
            );
        } catch (Exception e) {
            System.assert(false, 
                'Expected NoPermSetLicenseFoundException instead of Exception'
            );
        }
        
        Test.stopTest();
    }

    /**
     * @description Should throw a custom exception when trying to provision a 
     * license that doesn't exist or isn't active
     */
    @isTest
    static void shouldThrowExceptionWheProvisioningLicenseAndActiveLicenseCannotBeFound() {

        PermissionSetLicenseSelector permSetLicenseSelectorMock = 
            (PermissionSetLicenseSelector) Test.createStub(
                PermissionSetLicenseSelector.class, 
                new PermissionSetLicenseSelectorMock()
            );

        PermissionSetLicenseAssignSelector permSetLicenseAssignSelectorMock = 
            (PermissionSetLicenseAssignSelector) Test.createStub(
                PermissionSetLicenseAssignSelector.class, 
                new PermissionSetLicenseAssignSelectorMock()
            );
        SObjectDaoMock permSetLicenseAssignDaoMock = new SObjectDaoMock();

        PermissionSetLicenseService permissionSetLicenseService = 
            new PermissionSetLicenseService(
                permSetLicenseAssignDaoMock, 
                permSetLicenseSelectorMock, 
                permSetLicenseAssignSelectorMock
            );

        Test.startTest();

        try {
            permissionSetLicenseService.provisionPermissionSetLicense(
                new Set<User> {
                    USER_1_NO_CPQ_LICENSE,
                    USER_5_NO_CPQ_LICENSE
                }, 
                'zzz'
            );
            System.assert(false, 
                'Expected NoPermSetLicenseFoundException because the license ' 
                + 'does not exist for the parameter provided'
            );
        } catch(NoPermSetLicenseFoundException e) {
            System.assert(true, 
                'Expected NoPermSetLicenseFoundException because the license ' 
                + 'does not exist for the parameter provided'
            );
        } catch(Exception e) {
            System.assert(false, 
                'Expected NoPermSetLicenseFoundException instead of Exception'
            );
        }
        Test.stopTest();

    }


    private class PermissionSetLicenseSelectorMock 
            implements System.StubProvider {
        
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {

            if ('selectActivePermissionSetLicenseByDeveloperName'
                    .equals(stubbedMethodName) && listOfArgs.size() > 0) {
                if (CPQ_PERM_SET_LICENSE_DEV_NAME.equals(listOfArgs[0])) {
                    
                    PermissionSetLicenseType cpqLicense = new PermissionSetLicenseType();
                    cpqLicense.developerName = CPQ_PERM_SET_LICENSE_DEV_NAME;
                    cpqLicense.id = CPQ_PERMSET_LICENSE_ID;
                    cpqLicense.masterLabel = 'Salesforce CPQ License';
                    cpqLicense.usedLicenses = 50;
                    cpqLicense.totalLicenses = 20000;

                    PermissionSetLicense cpqPermissionSetLicense = 
                        permissionSetLicenseRecordGenerator(cpqLicense);
                    return new List<PermissionSetLicense> { 
                        cpqPermissionSetLicense
                    };
                } else if (EINSTEIN_AGENT_LICENSE_DEV_NAME.equals(listOfArgs[0])) {
                    PermissionSetLicenseType einsteinAgentLicense = 
                        new PermissionSetLicenseType();
                    einsteinAgentLicense.developerName = 
                        EINSTEIN_AGENT_LICENSE_DEV_NAME;
                    einsteinAgentLicense.id = EINSTEIN_AGENT_PERMSET_LICENSE_ID;
                    einsteinAgentLicense.masterLabel = 'Einstein Agent';
                    einsteinAgentLicense.usedLicenses = 0;
                    einsteinAgentLicense.totalLicenses = 1;

                    PermissionSetLicense einsteinAgentPermissionSetLicense = 
                        permissionSetLicenseRecordGenerator(einsteinAgentLicense);
                    return new List<PermissionSetLicense> { 
                        einsteinAgentPermissionSetLicense
                    };
                } else {
                    return new List<PermissionSetLicense>();
                }
            }
            return null;
        }

    }

    private static PermissionSetLicense permissionSetLicenseRecordGenerator(
            PermissionSetLicenseType license) {
        /* 
        Using JSON deserialize instead of directly creating 
        PermissionSetLicense because UsedLicenses field is not 
        writeable
        */
        String cpqPermissionSetLicenseRecord = 
            '{"attributes":{"type":"PermissionSetLicense"}, '
            + '"id":"' + license.id + '", '
            + '"DeveloperName": "' + license.developerName + '", '
            + '"MasterLabel":  "' + license.masterLabel + '", '
            + '"Status":"Active", '
            + '"UsedLicenses":"' + String.valueOf(license.usedLicenses) + '", '
            + '"TotalLicenses":"' + String.valueOf(license.totalLicenses) + '" '
            + '}';
        return (PermissionSetLicense) JSON.deserialize(
            cpqPermissionSetLicenseRecord, PermissionSetLicense.class
        );
    }

    private static User userRecordGenerator(Id userId, String userName) {
        /* 
        Using JSON deserialize instead of directly creating Users because we 
        need fake record Ids and don't want to touch the database because this  
        is unit testing
        */
        String userRecord = 
            '{"attributes":{"type":"User"}, '
            + '"id":"' + userId + '", '
            + '"Username":"' + userName + '"'
            + '}';
        /*
        We don't care about the rest of the fields as they are not required
        for unit testing this class
        */
        return (User) JSON.deserialize(userRecord, User.class);
    }

    private class PermissionSetLicenseAssignSelectorMock 
            implements System.StubProvider {

        private Set<Id> userIdsWithCpqLicense = new Set<Id> {
            USER_2_WITH_CPQ_LICENSE.Id, 
            USER_3_WITH_CPQ_LICENSE.Id,
            USER_4_WITH_CPQ_LICENSE.Id
        };
        
        private Set<Id> userIdsWithEinAgtLicense = new Set<Id> {
            USER_8_WITH_EIN_AGT_LICENSE.Id
        };
        

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
                List<Object> listOfArgs) {

            if ('selectPermissionSetLicenseAssignByUserIdsAndLicenseId'
                    .equals(stubbedMethodName)) {
                if (CPQ_PERMSET_LICENSE_ID == listOfArgs[1]) {
                    Set<Id> usersSetParameter =  (Set<Id>) listOfArgs[0];
                    List<PermissionSetLicenseAssign> cpqPermissionSetLicenseAssigns = 
                        new List<PermissionSetLicenseAssign>();

                    for (Id userId : usersSetParameter) {
                        if (userIdsWithCpqLicense.contains(userId)) {
                            PermissionSetLicenseAssign permissionSetLicenseAssign = 
                                new PermissionSetLicenseAssign();
                            permissionSetLicenseAssign.AssigneeId = userId;
                            permissionSetLicenseAssign.PermissionSetLicenseId = 
                                CPQ_PERMSET_LICENSE_ID;
                            cpqPermissionSetLicenseAssigns.add(
                                permissionSetLicenseAssign
                            );
                        }
                    }                
                    return cpqPermissionSetLicenseAssigns;
                } else if (EINSTEIN_AGENT_PERMSET_LICENSE_ID == listOfArgs[1]) {
                    Set<Id> usersSetParameter =  (Set<Id>) listOfArgs[0];
                    List<PermissionSetLicenseAssign> einAgtPermissionSetLicenseAssigns = 
                        new List<PermissionSetLicenseAssign>();

                    for (Id userId : usersSetParameter) {
                        if (userIdsWithEinAgtLicense.contains(userId)) {
                            PermissionSetLicenseAssign permissionSetLicenseAssign = 
                                new PermissionSetLicenseAssign();
                            permissionSetLicenseAssign.AssigneeId = userId;
                            permissionSetLicenseAssign.PermissionSetLicenseId = 
                                EINSTEIN_AGENT_PERMSET_LICENSE_ID;
                                einAgtPermissionSetLicenseAssigns.add(
                                    permissionSetLicenseAssign
                                );
                        }
                    }      
                    return einAgtPermissionSetLicenseAssigns;       
                }
            }
            return null;
        }

    }

    private class PermissionSetLicenseType {
        public String id;
        public String developerName;
        public String masterLabel;
        public Integer usedLicenses;
        public Integer totalLicenses;
    }
}