/**
 * @description       : Person 360 Toggle IsActive helper class
 * @author            : J.Mapanao
 * @group             : Person 360
 * @last modified on  : 2021-12-01
 * @last modified by  : Stefan Scheit
 * @revision
 *  2019-03-21 - J.Mapanao - Initial version    
 *  2019-06-06 - P.Victoriano - Updated Toggling to accomodate for backdated
 *  2020-02-06 - P.Victoriano - Add IsActive sticking
 *  2021-12-01 - Stefan Scheit - Added logic for 'unreachalbe__c' field (on Email__c records)
**/
public class Person360ToggleIsActiveHelper extends BaseClass {
    public List<SObject> records {get; set;}
    public List<SObject> recordsToUpdate {get; set;}
    public Person360ToggleIsActiveHelper() {
        super(new List<Schema.sObjectType> {
            Name__c.sObjectType,
            Email__c.sObjectType,
            Phone__c.sObjectType,
            Address__c.sObjectType,
            Social__c.sObjectType
        });
        records = new List<SObject>();
        recordsToUpdate = new List<SObject>();
    }

    public virtual void init(SObject record) {
        this.records.add(record);
    }

    public virtual void init(List<SObject> records) {
        this.records = records;
    }

    public virtual void startMapping() {
        if (records != null) {
            for (SObject sObj : records) {
                evaluateIsActiveFieldValue(sObj);
                recordsToUpdate.add(sObj);
            }
        }
    }
    /**
     * evaluateIsActiveFieldValue Checks if IsActive is toggled and let it stick
     */
    public SObject evaluateIsActiveFieldValue(SObject sObj, SOBJect oldSObj) {
        Boolean isActiveVal = (Boolean)sObj.get('Is_Active__c');
        Boolean oldisActiveVal = (Boolean)oldSObj.get('Is_Active__c');
        //IS Active flag is toggled
        if(isActiveVal == false && (isActiveVal != oldisActiveVal)) {
            // do nothing
            nebula.logger.fine('Manual Change End date auto populated');
        } else {
            //Other fields toggled compute for IsActive Flag
            evaluateIsActiveFieldValue(sObj);
        }
        return sObj;
    }
    /**
    * evaluateIsActiveFieldValue Defaults IsActive Flag
    */
    public SObject evaluateIsActiveFieldValue(SObject sObj) {
        Date startDateVal = (Date)sObj.get('Start_Date__c');
        Date endDateVal = (Date)sObj.get('End_Date__c');
        Boolean isActiveVal = (Boolean)sObj.get('Is_Active__c');
        Boolean isDeleted = false; // default as it does not apply to all contact points
        Boolean isUnreachable = false; // default as only Email__c defines this field

        // set 'isDeleted' flags from record(s), only applicable to Address__c, Email__c, and Phone__c
        SobjectType sobjType = sObj.getSObjectType();
        if(sobjType == Schema.Address__c.getSObjectType() || sobjType == Schema.Email__c.getSObjectType() || sobjType == Schema.Phone__c.getSObjectType() ) {
            // update isDeleted if it is set
            isDeleted = (null != sObj.get('Is_Deleted__c')) ? (Boolean)sObj.get('Is_Deleted__c') : false;
        }
        
        // set 'isUnreachable' flag from record(s), only applicable for Email__c
        if(sobjType == Schema.Email__c.getSObjectType()) {
            // update isUnreachable if it is set
            isUnreachable = (null != sObj.get('Unreachable__c')) ? (Boolean)sObj.get('Unreachable__c') : false;
        }
        
        // evaluate whether to set record as active
        if(isDeleted || isUnreachable) {
            // set active field to false if the record is flagged as (logically) deleted or unreachable
            Person360Helper.addFieldValue(sObj, 'Is_Active__c', false);
        } else {
            // Inactive: start date > today
            if ((startDateVal != null &&startDateVal > Date.today()) && (isActiveVal != null && isActiveVal)) {
                Person360Helper.addFieldValue(sObj,'Is_Active__c', false);
            }
            // Inactive: end date <= today
            else if ((endDateVal != null && endDateVal <= Date.today()) && (isActiveVal != null && isActiveVal)) {
                Person360Helper.addFieldValue(sObj,'Is_Active__c', false);
            }
            // Active: start date <= today AND end date > today or blank
            else if ((startDateVal != null && startDateVal <= Date.today()) && (endDateVal == null || endDateVal > Date.today()) && (isActiveVal != null && !isActiveVal)) {
                Person360Helper.addFieldValue(sObj,'Is_Active__c', true);
            } 
        }
        return sObj;
    }

    public void processRecords() {
        if (recordsToUpdate != null && !recordsToUpdate.isEmpty()) {
            for (SObject sObj : recordsToUpdate) {
                push(sObj);
            }
            BaseClass.ResultSet lResultSet = commitRecordsPartial();
        }
    }
}