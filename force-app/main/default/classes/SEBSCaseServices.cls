/**
 * @author Angelo Rivera
 * @description Service class of Case object for SEBS related functionality.
 * @revision    APRivera, 24.May.2019 - Created SEBS Service Class.
 */
public class SEBSCaseServices {

    public static Id SEBS_RECTYPEID {
        get {
            if(SEBS_RECTYPEID == null){
                SEBS_RECTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('SEBS').getRecordTypeId();
            }
            return SEBS_RECTYPEID;
        }
        set;
    }

    public static Boolean bIsCategory3OnlyPopulated(Case caseRecord){
        Boolean isCategory3OnlyPopulated = (caseRecord.Category_1__c == null && caseRecord.Category_2__c == null
                && caseRecord.Category_3__c != '' && caseRecord.Category_3__c != null);
        return isCategory3OnlyPopulated;
    }

    /**
     * @author       Anterey Custodio
     * @date         29.Sept.2016
     * @description  Private method that populates the categories according to the
     *                   value on category 3
     * @revision     Anterey Custodio - 27.Feb.2017 - Updated code to ignore cases
     *                    so that it acccepts Categories regardless of case
     */
    public static void populateCategoryByReasonForChange(List<Case> lstCaseToInsert) {
        Set<String> noImpactSet = new Set<String>{'location change', 'delivery model change', 'add class - non compulsory'};
        Set<String> notAcceptableSet = new Set<String>{'day/time change', 'duration change - compulsory', 'weeks offered change', 'add class - compulsory', 'make up class', 'staff - unavailable', 'other'};
        Set<String> acceptableSet = new Set<String>{'enrolment number change', 'staff - unexpected turnover', 'staff - special needs'};

        for (Case caseRecord: lstCaseToInsert) {
            //Set category 1 to post publication
            caseRecord.Category_1__c = 'Post Publication';

            //populate category 2 according to the retrieved category 3
            if (noImpactSet.contains(caseRecord.Category_3__c.toLowerCase())) {
                caseRecord.Category_2__c = 'No Impact';

            } else if (notAcceptableSet.contains(caseRecord.Category_3__c.toLowerCase())) {
                caseRecord.Category_2__c = 'Impact - Not Acceptable';

            } else if (acceptableSet.contains(caseRecord.Category_3__c.toLowerCase())) {
                caseRecord.Category_2__c = 'Impact - Acceptable';

            }
        }
    }
}