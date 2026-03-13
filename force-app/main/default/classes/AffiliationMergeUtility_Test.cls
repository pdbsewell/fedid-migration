/**
 * @description       : Test class for AffiliationMergeUtility
 * @author            : Nick Guia
 * @last modified on  : 16-08-2023
 * @last modified by  : Nick Guia
**/
@isTest(isParallel=true)
private class AffiliationMergeUtility_Test {

    private static Affiliation__c getSurvivorAffiliation() {
        Affiliation__c rec = new Affiliation__c();
        rec = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            rec,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.Id => fflib_IDGenerator.generate(Affiliation__c.SObjectType),
                Affiliation__c.Account__c => fflib_IDGenerator.generate(Account.SObjectType),
                Affiliation__c.Account_Communications__c => 'Tax receipt',
                Affiliation__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Affiliation__c.Department__c => 'Test 1 Department',
                Affiliation__c.Description__c => 'survivor',
                Affiliation__c.Engagement_Scoring_Applied__c => true,
                Affiliation__c.isActive__c => true,
                Affiliation__c.Opportunity__c => fflib_IDGenerator.generate(Opportunity.SObjectType),
                Affiliation__c.Position__c => 'Staff',
                Affiliation__c.Position_Level__c => 'Alumni',
                Affiliation__c.Program__c => 'Test Program 1',
                Affiliation__c.Roles__c => 'Current Employee;Partner',
                Affiliation__c.Share_Contact_to_Account_Role__c => AffiliationTriggerHandler.NO_SHARE,
                Affiliation__c.Start_Date__c => Date.today(),
                Affiliation__c.RecordTypeId => Schema.SObjectType.Affiliation__c.getRecordtypeInfosByDeveloperName().get('Applicant').getRecordTypeId()
            }
        );
        rec.Sharing_Composite_Key__c = ''+rec.Contact__c + rec.Account__c;
        rec.Composite_Key__c = ContactPointUtility.getAffiliationKey(rec);
        return rec;
    }

    private static Affiliation__c getVictimAffiliation() {
        Affiliation__c rec = new Affiliation__c();
        rec = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            rec,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.Id => fflib_IDGenerator.generate(Affiliation__c.SObjectType),
                Affiliation__c.Account__c => fflib_IDGenerator.generate(Account.SObjectType),
                Affiliation__c.Account_Communications__c => 'Stewardship',
                Affiliation__c.Contact__c => fflib_IDGenerator.generate(Contact.SObjectType),
                Affiliation__c.Department__c => 'Test 2 Department',
                Affiliation__c.Description__c => 'victim',
                Affiliation__c.Engagement_Scoring_Applied__c => false,
                Affiliation__c.isActive__c => true,
                Affiliation__c.Opportunity__c => fflib_IDGenerator.generate(Opportunity.SObjectType),
                Affiliation__c.Position__c => 'Director',
                Affiliation__c.Position_Level__c => 'Alumni No Degree',
                Affiliation__c.Program__c => 'Test Program 2',
                Affiliation__c.Roles__c => 'Partner;Agent',
                Affiliation__c.Share_Contact_to_Account_Role__c => AffiliationTriggerHandler.NO_SHARE,
                Affiliation__c.Start_Date__c => Date.today().addDays(-1),
                Affiliation__c.RecordTypeId => Schema.SObjectType.Affiliation__c.getRecordtypeInfosByDeveloperName().get('Applicant').getRecordTypeId()
            }
        );
        rec.Sharing_Composite_Key__c = ''+rec.Contact__c + rec.Account__c;
        rec.Composite_Key__c = ContactPointUtility.getAffiliationKey(rec);
        return rec;
    }

    /**
     * @description should return an initialised instance of AffiliationMergeUtility
     * when getInstance() is called 
     */
    @isTest
    static void shouldGetInstance() {

        // GIVEN
        AffiliationMergeUtility util;

        Test.startTest();

        // WHEN
        util = AffiliationMergeUtility.getInstance();

        Test.stopTest();

        // THEN
        Assert.isNotNull(util, 'Unable to get an instance of AffiliationMergeUtility');
        Assert.isNotNull(AffiliationMergeUtility.myself, 'Unable to get an instance of AffiliationMergeUtility');
    }

    /**
     * @description test a basic merge. in this scenario the survivor would be the
     * newer record, and would win in most comparisons.
     */
    @isTest
    static void shouldMergeFields() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(10) // later end date (winning)
            }
        );

        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(9) // earlier end date (losing)
            }
        );
        
        // expected result from combined Roles
        Set<String> rolesSet = new Set<String>();
        rolesSet.addAll(survivor.Roles__c.split(';'));
        rolesSet.addAll(victim.Roles__c.split(';'));
        String expectedRoles = String.join(new List<String>(rolesSet), ';');

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();
        Affiliation__c result;

        Test.startTest();

        // WHEN
        result = util.mergeFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null result');
        Assert.areEqual(survivor.Id, result.Id, 'Unexpected winning field value');
        Assert.areEqual(survivor.Account_Communications__c, result.Account_Communications__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Department__c, result.Department__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Description__c, result.Description__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.End_Date__c, result.End_Date__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Position__c, result.Position__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Position_Level__c, result.Position_Level__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Program__c, result.Program__c, 'Unexpected winning field value');
        Assert.areEqual(expectedRoles, result.Roles__c, 'Unexpected winning field value');
        Assert.areEqual(AffiliationTriggerHandler.NO_SHARE, result.Share_Contact_to_Account_Role__c, 'Unexpected winning field value');
        Assert.areEqual(''+survivor.Contact__c + survivor.Account__c, result.Sharing_Composite_Key__c, 'Unexpected winning field value');
        Assert.areEqual(survivor.Start_Date__c, result.Start_Date__c, 'Unexpected winning field value');
    }

    /**
     * @description pick the value from the newest start date when both records have a non-null value on the field
     * in this test we will use the Program__c field
     */
    @isTest
    static void shouldPickValueFromNewestStartDate() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        Affiliation__c victim = getVictimAffiliation();
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expectedProgram = survivor.Program__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.pickNewestStartDateOrNotNull(Affiliation__c.Program__c, survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expectedProgram, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description pick the value from the newest start date when both records have a non-null value on the field
     * in this test we will use the Program__c field
     */
    @isTest
    static void shouldPickValueFromSurvivorIfStartDatesAreEqual() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        Affiliation__c victim = getVictimAffiliation();
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expectedProgram = survivor.Program__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.pickNewestStartDateOrNotNull(Affiliation__c.Program__c, survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expectedProgram, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description pick the non-null value from the survivor if the value on the victim field is null
     * in this test we will use the Program__c field
     */
    @isTest
    static void shouldPickValueFromSurvivorNonNull() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        Affiliation__c victim = getVictimAffiliation();
        victim.Program__c = null;

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expectedProgram = survivor.Program__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.pickNewestStartDateOrNotNull(Affiliation__c.Program__c, survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expectedProgram, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description pick the non-null value from the victim if the value on the survivor field is null
     * in this test we will use the Program__c field
     */
    @isTest
    static void shouldPickValueFromVictimNonNull() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        Affiliation__c victim = getVictimAffiliation();
        survivor.Program__c = null;
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expectedProgram = victim.Program__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.pickNewestStartDateOrNotNull(Affiliation__c.Program__c, survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expectedProgram, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description pick the newest start date between the two records
     * Assumption : Start dates cannot be null
     */
    @isTest
    static void shouldMergeStartDateFields() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation(); // newest
        Affiliation__c victim = getVictimAffiliation();
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Date expected = survivor.Start_date__c;
        Date result;

        Test.startTest();

        // WHEN
        result = (Date) util.mergeStartDateFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description should pick the latest end date if both fields are not null
     */
    @isTest
    static void shouldMergeEndDateFieldsBothActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor.End_Date__c = Date.today().addDays(5);
        Affiliation__c victim = getVictimAffiliation();
        victim.End_Date__c = Date.today().addDays(4);
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Date expected = survivor.End_Date__c;
        Date result;

        Test.startTest();

        // WHEN
        result = (Date) util.mergeEndDateFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description should pick the latest end date if both fields are not null
     */
    @isTest
    static void shouldMergeEndDateFieldsBothInactive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-4),
                Affiliation__c.isActive__c => false
            }
        );

        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Date expected = survivor.End_Date__c;
        Date result;

        Test.startTest();

        // WHEN
        result = (Date) util.mergeEndDateFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description should pick survivor end date when the victim is inactive
     */
    @isTest
    static void shouldMergeEndDateFieldsWhenOnlySurvivorIsActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(5)
            }
        );

        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Date expected = survivor.End_Date__c;
        Date result;

        Test.startTest();

        // WHEN
        result = (Date) util.mergeEndDateFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description should pick victim end date when the survivor is inactive
     */
    @isTest
    static void shouldMergeEndDateFieldsWhenOnlyVictimIsActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );

        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(5),
                Affiliation__c.isActive__c => false
            }
        );
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Date expected = victim.End_Date__c;
        Date result;

        Test.startTest();

        // WHEN
        result = (Date) util.mergeEndDateFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if both affiliations are active, combine their multi-picklist roles
     */
    @isTest
    static void shouldMergeRoleFieldsFromBothActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        Affiliation__c victim = getVictimAffiliation();
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Set<String> rolesSet = new Set<String>();
        rolesSet.addAll(survivor.Roles__c.split(';'));
        rolesSet.addAll(victim.Roles__c.split(';'));

        String expected = String.join(new List<String>(rolesSet), ';');
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeRolesFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if both are inactive - combine the two sets
     * this way we won't lose any data as opposed to not merging anything if both are inactive
     */
    @isTest
    static void shouldMergeRoleFieldsFromBothInActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );
        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        Set<String> rolesSet = new Set<String>();
        rolesSet.addAll(survivor.Roles__c.split(';'));
        rolesSet.addAll(victim.Roles__c.split(';'));

        String expected = String.join(new List<String>(rolesSet), ';');
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeRolesFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if only the survivor affiliation is active, do not combine the role from the victim
     */
    @isTest
    static void shouldMergeRoleFieldsFromOnlySurvivorActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();

        Affiliation__c victim = getVictimAffiliation();
        victim = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            victim,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );
        
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected = survivor.Roles__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeRolesFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if only the victim affiliation is active, do not combine the role from the survivor
     */
    @isTest
    static void shouldMergeRoleFieldsFromOnlyVictimActive() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor = (Affiliation__c) fflib_ApexMocksUtils.setReadOnlyFields(
            survivor,
            Affiliation__c.class,
            new Map<SObjectField, Object> {
                Affiliation__c.End_Date__c => Date.today().addDays(-5),
                Affiliation__c.isActive__c => false
            }
        );

        Affiliation__c victim = getVictimAffiliation();
        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected = victim.Roles__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeRolesFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if both Share_Contact_to_Account_Role__c are equal, simply return that value
     */
    @isTest
    static void shouldReturnSharingFieldsWhenEqual() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;

        Affiliation__c victim = getVictimAffiliation();
        victim.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected = survivor.Share_Contact_to_Account_Role__c;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeSharingFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if any of the two is null, return no share
     */
    @isTest
    static void shouldMergeSharingFieldsWhenOneIsNull() {

        // GIVEN
        Affiliation__c survivor1 = getSurvivorAffiliation();
        survivor1.Share_Contact_to_Account_Role__c = null;
        Affiliation__c victim1 = getVictimAffiliation();
        victim1.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.READ_SHARE;

        Affiliation__c survivor2 = getSurvivorAffiliation();
        survivor2.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;
        Affiliation__c victim2 = getVictimAffiliation();
        victim2.Share_Contact_to_Account_Role__c = null;

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected1 = AffiliationTriggerHandler.NO_SHARE;
        String result1;

        String expected2 = AffiliationTriggerHandler.NO_SHARE;
        String result2;

        Test.startTest();

        // WHEN
        result1 = (String) util.mergeSharingFields(survivor1, victim1);
        result2 = (String) util.mergeSharingFields(survivor2, victim2);

        Test.stopTest();

        // THEN
        Assert.areEqual(expected1, result1, 'Unable to pick the correct surviving field');
        Assert.areEqual(expected2, result2, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if any of the two is equal to No Share, return no share
     */
    @isTest
    static void shouldMergeSharingFieldsWhenOneHasNoSharing() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;

        Affiliation__c victim = getVictimAffiliation();
        victim.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.NO_SHARE;

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected = AffiliationTriggerHandler.NO_SHARE;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeSharingFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

    /**
     * @description if none of the records are equal to no sharing, 
     * and one of them has read, return read
     */
    @isTest
    static void shouldMergeSharingFieldsWhenOneHasRead() {

        // GIVEN
        Affiliation__c survivor = getSurvivorAffiliation();
        survivor.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.READ_SHARE;

        Affiliation__c victim = getVictimAffiliation();
        victim.Share_Contact_to_Account_Role__c = AffiliationTriggerHandler.EDIT_SHARE;

        AffiliationMergeUtility util = AffiliationMergeUtility.getInstance();

        String expected = AffiliationTriggerHandler.READ_SHARE;
        String result;

        Test.startTest();

        // WHEN
        result = (String) util.mergeSharingFields(survivor, victim);

        Test.stopTest();

        // THEN
        Assert.isNotNull(result, 'Unexpected null object result');
        Assert.areEqual(expected, result, 'Unable to pick the correct surviving field');
    }

}