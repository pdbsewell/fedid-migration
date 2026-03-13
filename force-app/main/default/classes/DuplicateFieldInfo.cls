/**
* @description Stores Duplicate Match Field Info
*
* @author P. Victoriano
* @date 22/02/2021
*
* @group Common
* @revision
*
**/
public inherited sharing class DuplicateFieldInfo {
    @AuraEnabled
    public String recordId;
    @AuraEnabled
    public String dupRuleName;
    @AuraEnabled
    public String matchDescription;
    @AuraEnabled
    public String matchConfidence;
    //Difference Values = [Same,Different,Null]
    @AuraEnabled
    public String emailDifference;
    @AuraEnabled
    public String firstNameDifference;
    @AuraEnabled
    public String lastNameDifference;
    @AuraEnabled
    public String personalEmailDifference;
    @AuraEnabled
    public String monashEmailDifference;
    @AuraEnabled
    public String sapStaffIdDifference;
    @AuraEnabled
    public String mobilePhoneDifference;
    @AuraEnabled
    public String birthdateDifference;

    public DuplicateFieldInfo() {}
    public DuplicateFieldInfo(List<Datacloud.FieldDiff> fdiff, String drule, Decimal confd) {
        this.dupRuleName = drule;
        if(confd != null) {
            this.matchConfidence = String.valueOf(confd);
            if(drule != 'Contact_Perfect_Match') {
                if(drule == 'Contact_Potential_Match') {
                    //Reduce Match Confidence to 80% as Mathcing is potential
                    this.matchConfidence = String.valueOf((confd*.8));
                } else if(drule != 'Contact_Potential_Match') {
                    //Reduce Match Confidence to 50% as Mathcing is too loose
                    this.matchConfidence = String.valueOf((confd*.5));
                }
            }
            this.matchDescription = String.format('{0} {1}', new List<String> {
                this.dupRuleName,
                ''+this.matchConfidence
            });
        }
        if(fdiff != null) {
            for(Datacloud.FieldDiff fd:fdiff) {
                if(fd.getName() == 'Email') {
                    this.emailDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'Personal_Email__c') {
                    this.personalEmailDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'Monash_Email_Address__c') {
                    this.monashEmailDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'LastName') {
                    this.lastNameDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'FirstName') {
                    this.firstNameDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'Birthdate_Dup__c') {
                    this.birthdateDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'MobilePhone') {
                    this.mobilePhoneDifference = (fd.getDifference()+'CSS').toLowerCase();
                } else if(fd.getName() == 'SAP_Staff_Id__c') {
                    this.sapStaffIdDifference = (fd.getDifference()+'CSS').toLowerCase();
                }
            }
        }
    }
}