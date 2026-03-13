/*******************************************************************************
* @author       Russell Cadapan
* @date         20/11/2020
* @description  Wrapper class for ContactMergeWizard LWC
* @revision
*               05.05.22 P.Victoriano - Fixed Ask Monash Defaulting [EPCP-1200]
*               19.05.22 P.Victoriano - FedId defaulting [EPCP-1298]
*               30.03.2022 P.Victoriano - Fixed Formatting
*******************************************************************************/
public class ContactMergeData implements Comparable {
    @AuraEnabled
    public Contact contactRecord;
    //Move to Private set to force to use the linkUser method
    @AuraEnabled
    public User userRecord {
        get;
        private set;
    }
    @AuraEnabled
    public Account accountRecord;
    @AuraEnabled
    public Boolean isPrimary = false;
    //This is defaulted to false and included based on Match Confidence
    @AuraEnabled
    public Boolean isIncluded = false;
    @AuraEnabled
    public String matchConfidence;
    @AuraEnabled
    public String matchDescription;
    @AuraEnabled
    public String includeClass;
    @AuraEnabled
    public String primaryClass;
    @AuraEnabled
    public String birthDateString;
    @AuraEnabled
    public String lastModifiedDateString;
    @AuraEnabled
    public String lastLoginDateString;
    @AuraEnabled
    public String excludedFromMerge;
    @AuraEnabled
    public List<String> communityAccesses;
    @AuraEnabled
    public Boolean hasCommunityAccess = false;
    @AuraEnabled
    public Boolean isMyAppUser = false;
    @AuraEnabled
    public List<Id> permissionSetIds;
    @AuraEnabled
    public String contactLink;
    @AuraEnabled
    public String userLink;
    @AuraEnabled
    public DuplicateFieldInfo dupFieldInfo;
    public ContactMergeData(Contact contactRecord, User userRecord, DuplicateFieldInfo dupFInfo) {
        this.contactRecord = contactRecord;
        this.accountRecord = contactRecord.Account;
        this.matchDescription = 'Determines if duplicate records exist for your criteria';
        if (dupFInfo != null) {
            this.dupFieldInfo = dupFInfo;
            String ruleType = this.dupFieldInfo.dupRuleName;
            if (matchDescripMAp.containsKey(ruleType)) {
                this.matchDescription = matchDescripMAp.get(ruleType);
            }
            this.matchConfidence = this.dupFieldInfo.matchDescription;
            if (this.dupFieldInfo.matchConfidence != null) {
                Decimal dconfDec = Decimal.valueOf(this.dupFieldInfo.matchConfidence);
                if (dconfDec > 50) {
                    this.isIncluded = true;
                    this.includeClass = 'success';
                }
            }
        }
        this.birthDateString = ContactMergeHelper.dateFormatter(contactRecord.Birthdate);
        this.lastModifiedDateString = ContactMergeHelper.dateFormatter(contactRecord.LastModifiedDate, true);
        this.contactLink = '/' + contactRecord.Id;
        this.excludedFromMerge = contactRecord.Exclude_From_Merge__c ? 'Yes' : 'No';
        linkUser(userRecord);
    }

    public void linkUser(User usr) {
        this.userRecord = usr;
        if (this.userRecord != null) {
            this.communityAccesses = new List<String>();
            this.permissionSetIds = new List<Id>();
            this.userLink = '/' + this.userRecord.Id;
            if (this.userRecord.PermissionSetAssignments != null) {
                for (PermissionSetAssignment passignment: this.userRecord.PermissionSetAssignments) {
                    if (passignment.PermissionSet != null &&
                        passignment.PermissionSet.Type != 'Profile') {
                        this.permissionSetIds.add(passignment.PermissionSetId);
                        if (permissionSetToCommunityMap.containsKey(passignment.PermissionSet.Name)) {
                            this.communityAccesses.add(permissionSetToCommunityMap.get(passignment.PermissionSet.Name));
                        }
                    }
                }
            }
            if (!this.communityAccesses.isEmpty()) {
                this.hasCommunityAccess = true;
                this.isMyAppUser = this.communityAccesses.contains('my.app');
            }
            if (this.userRecord.LastLoginDate != null) {
                this.lastLoginDateString = ContactMergeHelper.dateFormatter(userRecord.LastLoginDate, true);
            }
        }
    }
    /**
     * @description Checks for User SSO
     * @author pvic0002
     * @return   return Boolean
     */ 
    public Boolean isNonSSOUser {
        get {
            Boolean isB = true;
            if (this.userRecord != null &&
                (String.isNotBlank(this.userRecord.FederationIdentifier)) ||
                (this.communityAccesses.size() == 1 && this.communityAccesses.contains('Ask Monash'))
                ) {
                isB = false;
            }
            return isB;
        } private set;
    }
    /**
     * compareTo for List Sorting
     * @param  compareTo Object to compare
     * @return           return posx
     */
    public Integer compareTo(Object compareTo) {
        try {
            //List Order in ASC - cConMd is the previous record used to compare with current record
            ContactMergeData cConMD = (ContactMergeData)compareTo;
            if (userRecord == null) {
                //Current Record has no User
                if (cConMD.userRecord != null) {
                    //Previous Record Has User Record
                    return 1;
                } else {
                    //Current and Previous Records dont have User records
                    if (String.isNotBlank(contactRecord.Person_ID__c) && String.isBlank(cConMD.contactRecord.Person_ID__c)) {
                        //Current Record Contact Has Person Id and Previous Record Contact Has No Person Id
                        return -1;
                    }
                }
            } else {
                //Current Record has no User
                if (cConMD.userRecord != null) {
                    //Previous Record Has User Record
                    if (hasCommunityAccess == true && cConMD.hasCommunityAccess == true &&
                        isNonSSOUser && cConMD.isNonSSOUser) {
                        //Move Latest Login Date User
                        if ((userRecord.LastLoginDate < cConMD.userRecord.LastLoginDate) ||
                            (userRecord.LastLoginDate == null && cConMD.userRecord.LastLoginDate != null)) {
                            //If Current Record LoggedIn the latest
                            return 1;
                        } else if ((userRecord.LastLoginDate > cConMD.userRecord.LastLoginDate) ||
                                   (userRecord.LastLoginDate != null && cConMD.userRecord.LastLoginDate == null)) {
                            //If Current Record LoggedIn the latest
                            return -1;
                        }
                    } else if (hasCommunityAccess == true && cConMD.hasCommunityAccess == true &&
                               isNonSSOUser && cConMD.isNonSSOUser == false) {
                        //Previous Record is Non-SSO and Current Record Is SSO
                        return -1;
                    } else if (hasCommunityAccess == true && cConMD.hasCommunityAccess == true &&
                               isNonSSOUser == false && cConMD.isNonSSOUser) {
                        //Current Record Is Non-SSO and Previous Record is SSO
                        if (userRecord.LastLoginDate != null && cConMD.userRecord.LastLoginDate == null) {
                            return -1;
                        }
                        return 1;
                    } else if (hasCommunityAccess == false && cConMD.hasCommunityAccess == true) {
                        return 1;
                    } else if (hasCommunityAccess == true && cConMD.hasCommunityAccess == true &&
                               isNonSSOUser == false && cConMD.isNonSSOUser == false) {
                        if ((userRecord.LastLoginDate > cConMD.userRecord.LastLoginDate) ||
                            (userRecord.LastLoginDate != null && cConMD.userRecord.LastLoginDate == null) ||
                            (userRecord.FederationIdentifier != null && cConMD.userRecord.FederationIdentifier == null)) {
                            //If Current Record LoggedIn the latest
                            return -1;
                        }
                        return 1;
                    }
                } else if (cConMD.userRecord == null) {
                    return -1;
                }
            }
        } catch (Exception e) {}
        //Default no Change in Order
        return 0;
    }

    private Map<String, String> permissionSetToCommunityMap = new Map<String, String> {
        'Customer_Community_Ask_Monash_Student' => 'Ask Monash',
        'Customer_Community_My_Application' => 'my.app',
        'SteelBrickCPQCustomerUser' => 'Offers',
        'Alumni_Portal_Permission_Set' => 'Alumni'
    };
    private Map<String, String> matchDescripMAp = new Map<String, String> {
        'Contact_Perfect_Match' => 'Strong match of Contact which can be auto-merged. This excludes records which contain a SAP staff id (i.e. they are not being merged).',
        'Contact_Potential_Match' => 'A 2nd tier matching/duplicate rule to allow non-perfect matches to be merged',
        'Contact_Loose_Match' => 'A loose match on contact by First Name, Last Name, and Email(s) - Email, Personal Email, Monash Email.'
    };
}