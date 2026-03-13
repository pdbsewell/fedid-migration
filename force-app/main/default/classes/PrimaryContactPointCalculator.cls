/**
 * @description       : Base class for calculating new primary of contact points.
 * @date              : 28-07-2023
 * @group             : Person 360
 * @author            : Nick Guia
 * @last modified on  : 12-09-2023
 * @last modified by  : Nick Guia
 * NOTE:
 *  - all the logic that implements calculatePrimary() has a heavy reliance on the ordering 
 *    of the records within the List. Ensure that the records are properly sorted (ORDER BY) if coming from
 *    a query, otherwise use their respective Comparable classes to sort them first in memory
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/289931356/Contact+Point+Primary+Calculator
 * @see https://monash-esol.atlassian.net/wiki/spaces/MCE/pages/287244919/Contact+Point+Comparable+Sorting
**/
public abstract inherited sharing class PrimaryContactPointCalculator {

    @TestVisible
    protected SObject primary;
    @TestVisible
    protected List<SObject> contactPoints;
    @TestVisible
    protected Boolean isStudent;
    @TestVisible
    protected Boolean isPrimarySetByUser = false;
    @TestVisible
    protected BaseClass bc;
    @TestVisible
    protected Boolean shouldSort = false;
    @TestVisible
    protected List<ContactPointComparable> comparableList; // for sorting based on various rules
    @TestVisible
    protected List<ContactPointRankComparable> rankComparableList; // for sorting purely based on roll up rank

    public PrimaryContactPointCalculator(List<SObject> cpList, Boolean isStudent) {
        if(cpList == null || cpList.isEmpty()) {
            throw new PrimaryContactPointCalculatorException('Contact point list cannot be null or empty');
        }
        this.contactPoints = cpList;
        this.isStudent = isStudent;
        this.rankComparableList = new List<ContactPointRankComparable>();
    }

    // perhaps the object has some prioritised attributes such as user-override on the primary
    protected abstract void maybeSetPrimaryByPrioritisedAttributes();

    // rules for calculating the primary contact point
    protected abstract void calculatePrimary();

    // instantiate a concrete implementation of the contact point's comparable class
    protected abstract ContactPointComparable createContactPointComparable(SObject contactPoint);

    /**
    * @description use this if your contact points are not yet ordered 
    *   i.e. records not from query, or created in-memory
    *   This will execute the contact point's sortable alogrithm in the execute() method.
    * @author Nick Guia | 31-07-2023 
    * @return PrimaryContactPointCalculator 
    **/
    public PrimaryContactPointCalculator shouldSortContactPoints(Boolean isSort) {
        this.shouldSort = isSort;
        return this;
    }

    /**
    * @description use this if you want to stage the record changes within the base class
    * @author Nick Guia | 31-07-2023 
    * @param BaseClass bClass 
    * @return PrimaryContactPointCalculator 
    **/
    public PrimaryContactPointCalculator setBaseClass(BaseClass bClass) {
        this.bc = bClass;
        return this;
    }

    /**
    * @description returns the instance of the base class
    * @author Nick Guia | 31-07-2023 
    * @return BaseClass 
    **/
    public BaseClass getBaseClass() {
        return this.bc;
    }

    /**
    * @description 
    * @author Nick Guia | 28-07-2023 
    * @return List<SObject> 
    **/
    @TestVisible
    public virtual List<SObject> execute() {

        // STEP 1 : sort the contact points
        if(this.shouldSort) {
            sortContactPoints();
        }

        // STEP 2 : set all primary to false
        setAllPrimaryToFalse();

        // STEP 3 : collect prioritised attributes such as user overridden primary
        maybeSetPrimaryByPrioritisedAttributes();

        // STEP 4 : calculate the new primary
        calculatePrimary();

        // STEP 5 : push the changes into the BaseClass
        pushChanges();

        return getContactPoints();
    }

    public List<SObject> getContactPoints() {
        return this.contactPoints;
    }

    public SObject getPrimary() {
        return this.primary;
    }

    /**
    * @description sets all contact points' primary flag to false
    * @author Nick Guia | 28-07-2023 
    **/
    @TestVisible
    private void setAllPrimaryToFalse() {
        for(SObject iSObject : this.contactPoints) {
            setPrimaryToFalse(iSObject);
        }
    }

    /**
    * @description default implementation of setting contact point primary to false.
    *   if the SObject (happen to) have another API name for Is_Primary__c, override this
    * @author Nick Guia | 28-07-2023 
    * @param SObject rec 
    **/
    @TestVisible
    protected virtual void setPrimaryToFalse(SObject rec) {
        rec.put('Is_Primary__c', false);
        this.bc?.push(rec);
    }

    /**
    * @description updates the is primary field of the new primary, and stores it within this class
    * @author Nick Guia | 22-08-2023 
    * @param SObject newPrimary 
    **/
    @TestVisible
    protected void setPrimary(SObject newPrimary) {
        newPrimary.put('Is_Primary__c', true);
        this.primary = newPrimary;
        // TODO : should we also set Primary_set_by__c = 'system'?
    }

    /**
    * @description sort the contact points based on the object's rules
    * @author Nick Guia | 31-07-2023 
    * @return virtual 
    **/
    @TestVisible
    protected virtual void sortContactPoints() {
        this.comparableList = createSortableList();
        if(!comparableList.isEmpty()) {
            this.comparableList.sort();
            this.contactPoints = getRecordsFromSortedList(this.comparableList);
        }
    }

    /**
    * @description create a sortable list based on the contact point records
    * @author Nick Guia | 31-07-2023 
    * @return List<ContactPointComparable> 
    * @throws ContactPointComparableException
    **/
    @TestVisible
    protected virtual List<ContactPointComparable> createSortableList() {
        List<ContactPointComparable> compareList = new List<ContactPointComparable>();

        for(SObject rec : this.contactPoints) {
            ContactPointComparable iComparable = createContactPointComparable(rec);
            if(iComparable != null) {
                compareList.add(iComparable);
            }
        }

        return compareList;
    }

    /**
    * @description if source is Callista, create a sortable list based on callista roll up rank
    * @author Nick Guia | 11-09-2023 
    * @return List<ContactPointComparable> 
    * @throws ContactPointRankComparableException
    * @throws ContactPointRankComparableDeveloperException
    **/
    @TestVisible
    protected virtual void addRollupRankSortableList(SObject rec) {
        String source = String.valueOf(rec.get('Source__c'));
        if(String.isNotBlank(source) && source.equalsIgnoreCase('Callista')) {
            this.rankComparableList.add(new ContactPointRankComparable(rec));
        }
    }

    /**
    * @description if there are any Contact Points with source == 'Callista', return the record with highest rank
    * @author Nick Guia | 11-09-2023 
    * @return SObject
    **/
    @TestVisible
    protected SObject getHighestRollupRank() {
        SObject returnVal;

        if(!this.rankComparableList.isEmpty()) {
            this.rankComparableList.sort();
            returnVal = this.rankComparableList[0].compareFrom;
        }

        return returnVal;
    }

    /**
    * @description extract the SObject records out of the sortable classes. This is useful when
    *   trying to get the actual sorted records rather than their comparable classes
    * @author Nick Guia | 31-07-2023 
    * @param List<ContactPointComparable> compareList 
    **/
    @TestVisible
    protected List<SObject> getRecordsFromSortedList(List<ContactPointComparable> compareList) {
        List<SObject> sortedList = new List<SObject>();
        for(ContactPointComparable iComparable : compareList) {
            sortedList.add(iComparable.compareFrom);
        }
        return sortedList;
    }

    /**
    * @description pushes the changes into the BaseClass. This method assumes that all records 
    *   within this instance must be updated since we blindly untoggled all records to isprimary = false
    *   in order to simplify the process. This method eliminates the risk of duplicating a push to the BaseClass
    *   of the same record, which will cause a DML error
    * @author Nick Guia | 22-08-2023 
    **/
    @TestVisible
    private void pushChanges() {
        if(this.bc != null && this.contactPoints != null) {
            for(SObject rec : this.contactPoints) {
                bc.push(rec);
            }
        }
    }

    public class PrimaryContactPointCalculatorException extends Exception { }
}