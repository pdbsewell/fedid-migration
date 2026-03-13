/**
 * @description       : Comparable class for Contact Points for sorting records based on their Callista Roll up rank.
 *                      This is primarily used for finding the new primary contact point of student contacts
 * @author            : Nick Guia
 * @group             : Person 360
 * @last modified on  : 01-08-2023
 * @last modified by  : Nick Guia
**/
public virtual inherited sharing class ContactPointRankComparable implements Comparable {

    public final SObject compareFrom;
    public final Integer rollupRank;

    /**
     * @throws ContactPointRankComparableException
     */
    public ContactPointRankComparable(SObject contactPoint) {
       
        // first do a null check
        if(contactPoint == null) {
            throw new ContactPointRankComparableException('Invalid null argument on constructor');
        }

        String callistaRank = (String) contactPoint.get('Callista_rollup_rank__c');

        if(String.isNotBlank(callistaRank)) {
            try {
                this.rollupRank = Integer.valueOf(callistaRank);
            } catch(System.TypeException e) {
                throw new ContactPointRankComparableException('Unable to convert roll up rank to Integer : ' + e.getMessage());
            } catch(Exception e) {
                throw new ContactPointRankComparableException(e);
            }
        }

        this.compareFrom = contactPoint;
    }

    /**
    * @description main method to execute the rule chain
    * @author Nick Guia | 11-09-2023 
    * @param Object compareObj 
    * @return Integer 
    *   -1 – The current value is greater than the compared value
    *   0 –  The current value is equal to the compared value
    *   1 –  The current value is less than the compared value
    * @throws ContactPointRankComparableDeveloperException
    **/
    public Integer compareTo(Object compareObj) {
        
        ContactPointRankComparable newComparable =  (ContactPointRankComparable) compareObj;

        Schema.SObjectType compareFromType = this.compareFrom.getSObjectType();
        Schema.SObjectType compareWithType = newComparable.compareFrom.getSObjectType();

        // ensure that we are comparing similar SObjectTypes
        if(compareFromType != compareWithType) {
            throw new ContactPointRankComparableDeveloperException('Invalid comparison of different SObject Types : ' + compareFromType + ' and ' + compareWithType);
        }

        Integer compareWithRank = newComparable.rollupRank;

        /**
         * Chaining of rule evaluation. If an additional rule is needed by a
         * different implementation, override rule 3 and chain the additional rule(s)
         */
        return runRuleChain(this.rollupRank, compareWithRank);
    }

    /**
    * @description main method to start the execution of rule chaining. This enables
    *   each specific rule to be overriden by subclasses
    * @author Nick Guia | 11-09-2023 
    * @param Integer compareFrom 
    * @param Integer compareWith 
    * @return Integer 
    **/
    @TestVisible
    private Integer runRuleChain(Integer compareFromRank, Integer compareWithRank) {
        return rule1(compareFromRank, compareWithRank);
    }

    /**
    * @description RULE 1 : null checks, non-null goes lower in the stack
    * @author Nick Guia | 11-09-2023 
    * @param Integer compareFrom 
    * @param Integer compareWith 
    * @return Integer 
    **/
    @TestVisible
    protected virtual Integer rule1(Integer compareFromRank, Integer compareWithRank) {
        if(compareFromRank != null && compareWithRank == null) return -1;
        if(compareFromRank == null && compareWithRank != null) return 1;
        if(compareFromRank == null && compareWithRank == null) return 0;
        return rule2(compareFromRank, compareWithRank); // both not null
    }

    /**
    * @description RULE 2 : greater rank wins
    * @author Nick Guia | 11-09-2023 
    * @param Integer compareFrom 
    * @param Integer compareWith 
    * @return Integer 
    **/
    @TestVisible
    protected virtual Integer rule2(Integer compareFromRank, Integer compareWithRank) {
        if(compareFromRank == compareWithRank) return 0;
        return (compareFromRank > compareWithRank) ? -1 : 1;
    }

    public class ContactPointRankComparableException extends Exception { }

    public class ContactPointRankComparableDeveloperException extends Exception { }
}