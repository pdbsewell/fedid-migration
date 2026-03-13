/**
 * @description 
 * Services class for all thing course group (which are in fact still not utilised in UniCRM)
 * 
 * Code introduced to allow removal of a process builder flow
 **/
public class CourseGroupServices {
    
   /**
    * @description Supports before context only
    * Align the record name with the course group name (from Callista)
    * Collect the org units and course groups that require a managing faculty lookup for later processing
    **/
    public class updateFields extends TriggerAbstract {
        list<String> orgUnitCds = new list<String>();
        list<course_group__c> groups = new list<course_group__c>();
        
        /**
         * @description Insert 
         * Align the record name with the course group name (from Callista)
         * Collect the org units and course groups that require a managing faculty lookup for later processing
         **/
        public override void process(sObject rec){
            Course_Group__c cg = (Course_Group__c)rec;
            cg.Name = cg.Course_Group__c;
            
            if (cg.Responsible_Org_Unit_Code__c != null) {
                orgUnitCds.add(cg.Responsible_Org_Unit_Code__c);
				groups.add(cg);
            } else {
                cg.Managing_Faculty__c = null;
            }
        } 
    
        /**
         * @description Update
         * Collect the org units and course groups that require a managing faculty lookup for later processing
         **/
        public override void process(sObject rec, sObject oldRec){
			Course_Group__c cg = (Course_Group__c)rec;
            Course_Group__c ocg = (Course_Group__c)oldRec;

            cg.Name = cg.Course_Group__c;
			if ((commonUtilities.fieldHasChanged('Responsible_Org_Unit_Code__c', cg, ocg)) ||
                (commonUtilities.fieldHasChanged('Managing_Faculty__c', cg, ocg))) {
                if (cg.Responsible_Org_Unit_Code__c != null) {
                    orgUnitCds.add(cg.Responsible_Org_Unit_Code__c);
                    groups.add(cg);
                } else {
                    cg.Managing_Faculty__c = null;
                }
            }
        } 
    
        /**
         * @description 
         * For any course groups with an Org Unit Code, lookup and assign the faculty account record
         **/
        public override void execute() {
            if (groups.size() > 0) {
	            
                map<String, Id> ouMap = new map<String, Id>();
                for (Account a : [select id, callista_org_unit_code__c from account where callista_org_unit_code__c in :orgUnitCds]) {
                    ouMap.put(a.callista_org_unit_code__c, a.id);
                }

                for (course_group__c cg : groups) {
                    cg.managing_faculty__c = ouMap.get(cg.Responsible_Org_Unit_Code__c);
                }
            }
        }
    }
}