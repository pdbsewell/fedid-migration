/**
 * @author Nick Guia
 * @description Data Acccess Object for Prospective Lead model
 * @group Lead Management
 */
public virtual inherited sharing class ProspectiveStudentLeadDAO implements IProspectiveStudentLead {
    
    public Lead prospectiveLead {get; set;}
    public List<Lead_Course_Association__c> lcaList {get; set;}

    public ProspectiveStudentLeadDAO(Lead leadRec) {
        this.prospectiveLead = leadRec;
        this.lcaList = new List<Lead_Course_Association__c>();
    }

    /**
     * @description retrieves all Lead Course Association records related 
     *   with this Prospective Student in a map format
     * @return Map<Id, Lead_Course_Association__c>
     */
    public Map<Id, Lead_Course_Association__c> getCourseInterestsMap() {
        Map<Id, Lead_Course_Association__c> lcaMap = new Map<Id, Lead_Course_Association__c>();
        for(Lead_Course_Association__c iLCA : this.lcaList) {
            lcaMap.put(iLCA.Course_Master__c, iLCA);
        }
        return lcaMap;
    }

    /**
    * @description resolves dependencies and object relationships of all associated
    *   records within the Data Access Object
    * @param BaseClass bc : an instance of BaseClass with a defined commit order
    * @param Contact con : parent Contact of Prospective Student Lead record
    * @return void
    */
    public void resolveDependencies(BaseClass bc, Contact con) {
        bc.push(this.prospectiveLead, Lead.Contact__c, con);
        for(Lead_Course_Association__c iLca : this.lcaList) {
            bc.push(iLca, Lead_Course_Association__c.Lead__c, this.prospectiveLead);
        }
    }

    /**
     * @description creates a map of LCA for both the Course Master ID and Course Code
     * TO BE DEPRECATED AFTER MOVING TO V2 as we are not supporting course master ID anymore
     */
    public Map<String, Lead_Course_Association__c> getCourseInterestsMapStr() {
        Map<String, Lead_Course_Association__c> lcaMap = new Map<String, Lead_Course_Association__c>();
        for(Lead_Course_Association__c iLCA : this.lcaList) {
            lcaMap.put(iLCA.Course_Master__c, iLCA);
            lcaMap.put(iLCA.Course_Code__c, iLCA);
        }
        return lcaMap;
    }

    /**
     * @description retrieve the Lead record related with this Prospective Student
     * TO BE DEPRECATED AFTER MOVING TO V2
     */
    public Lead getLead() {
        return this.prospectiveLead;
    }

    /**
    * @description replaces the existing List of Lead Course Association 
    *   records related witht this Prospective Student
    * @param List<Lead_Course_Association__c> listLca : new List of Lead Course Association records
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public void setCourseInterest(List<Lead_Course_Association__c> listLca) {
        this.lcaList = listLca;
    }

    /**
    * @description adds a Lead Course Association record for this Prospective Student 
    * @param Lead_Course_Association__c lca : Lead Course Association record to be added
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public void addCourseInterest(Lead_Course_Association__c lca) {
        this.lcaList.add(lca);
    }

    /**
    * @description assign a Lead record for this Prospective Student
    * @param Lead leadRec
    * @return void
    * TO BE DEPRECATED AFTER MOVING TO V2
    */
    public void setLead(Lead leadRec) {
        this.prospectiveLead = leadRec;
    }

    /**
     * @description retrieves all Lead Course Association records related with this Prospective Student 
     * @return List<Lead_Course_Association__c>
     * TO BE DEPRECATED AFTER MOVING TO V2
     */
    public List<Lead_Course_Association__c> getCourseInterests() {
        return this.lcaList;
    }
}