/**
 * @author          Steffi Narang
 * @description     This class is used to store the harcoded values used in dynamicRowsController and 
 * @revision        12/Jan/2020  - Created
 * 1.1	12-01-2020		Vinothraja		Added Constants related to Partners' Account Team Member roles // SFTG-2170
 * 2.1	17-08-2025		Sachin Shetty	Added Constructor
 **/
public with sharing class AccountTeamConstants {

    public static final String EDIT = 'Edit';
    public static final String READ = 'Read';
    public static final String PRM = 'PRM (Philanthropy)';
    public static final String CASE_PRIVATE = 'NONE';  
    /* Roles for Partner Users  - START */ // SFTG-2170
    public static final String PARTNER_ROLE_PRIMARY_ACCOUNT_HOLDER = 'Primary Account Holder';
    public static final String PARTNER_ROLE_DELEGATED_ADMIN = 'Delegated Admin User';
    public static final String PARTNER_ROLE_STANDARD_USER = 'Standard Partner User';
    /* Roles for Partner Users  - END */
    
    // Private constructor to prevent instantiation
    public AccountTeamConstants() { //NOPMD
        // This class is not meant to be instantiated
    }
}