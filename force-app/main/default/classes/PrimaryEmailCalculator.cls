/**
 * @description       : For calculating the Primary Email record
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 22-08-2023
 * @last modified by  : Nick Guia
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
 * TODO : we must work towards implementing the same rules on PrimaryAddressCalculator to utilise Callista_rollup_rank__c
**/
public inherited sharing class PrimaryEmailCalculator extends PrimaryContactPointCalculator {

    @TestVisible
    private List<Email__c> monashEmails;
    @TestVisible
    private List<Email__c> nonMonashEmails;

    public PrimaryEmailCalculator(List<Email__c> records, Boolean isStudent) {
        super(records, isStudent);
        this.monashEmails = new List<Email__c>();
        this.nonMonashEmails = new List<Email__c>();
    }

    /**
    * @description instantiate the concrete implementation of email sorting
    * @author Nick Guia | 11-09-2023 
    **/
    protected override ContactPointComparable createContactPointComparable(SObject contactPoint) {
        return new EmailComparable((Email__c) contactPoint);
    }

    /**
    * @description checks if there are any user-overriden primary
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void maybeSetPrimaryByPrioritisedAttributes() {

        for(Email__c emailRec : (List<Email__c>) super.contactPoints) {

            // collect monash emails by classification
            if(emailRec.Classification__c == EmailServices.EMAIL_CLASSIFICATION_MONASH) {
                this.monashEmails.add(emailRec);
            } else {
                this.nonMonashEmails.add(emailRec);
            }

            // CONDITION 1 : if there is any "user override" primary, re-tag it as primary
            if(emailRec.Primary_set_by__c == 'user') {
                setPrimary(emailRec);
                super.isPrimarySetByUser = true;
                break;
            }
        }
    }

    /**
    * @description rules for calculating a primary email.
    * @author Nick Guia | 28-07-2023 
    **/
    protected override void calculatePrimary() {

        if(!super.isPrimarySetByUser) {

            Email__c primary;
            
            if(super.isStudent && !this.monashEmails.isEmpty()) {
                // CONDITION 2 : if the contact is a student, make their Monash email as primary
                primary = this.monashEmails[0];
            }
            
            if(primary == null) {
                // CONDITION 3: if a non-student, pick the latest non-monash email as primary
                if(!this.nonMonashEmails.isEmpty()){
                    primary = this.nonMonashEmails[0];
                // CONDITION 4 : if a non-student but without a non-monash email, pick the latest monash email as fallback
                } else if(!this.monashEmails.isEmpty()) {
                    primary = this.monashEmails[0];
                }
            }
            
            if(primary != null) {
                setPrimary(primary);
            }
        }
    }
}