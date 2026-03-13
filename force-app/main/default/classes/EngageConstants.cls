/**
 * @author          Mark Johnson: UC Innovation
 * @description     Holds various constants for ENGAGE project
 * @revision        10/09/2019 - Mark Johnson - Initial version
 */

public class EngageConstants {

    public static final List<RecordType> INTERIM_RECORDTYPES {
        get {
            if (INTERIM_RECORDTYPES == null) {
                INTERIM_RECORDTYPES = [SELECT Id, Name, DeveloperName, SobjectType, Namespaceprefix FROM RecordType WHERE SobjectType = 'ucinn_ascendv2__Interim__c'];
            }
            return INTERIM_RECORDTYPES;
        }
        private set;
    }

    public static final String RAISERS_EDGE = 'Raisers Edge';
}