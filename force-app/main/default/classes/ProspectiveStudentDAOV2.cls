/**
 * @description       : Data Acccess Object for Prospective Student model
 * @author            : Nick Guia
 * @date              : 22-09-2020
 * @group             : Lead Management
 * @last modified on  : 04-07-2023
 * @last modified by  : Nick Guia
 * @revision
 *  04-07-2023  Nick Guia   - stopped creating CPAs for prospective students
**/
public virtual inherited sharing class ProspectiveStudentDAOV2 {

    public Person360 p360;
    public ProspectiveStudentLeadDAO leadDao;
    public ProspectiveStudentCampaignDAO campaignDAO;
    public List<Contact_Qualification__c> contactQualificationList;
    public Person360.Person360Builder p360Builder;

    protected ProspectiveStudentDAOV2() {
        init();
    }

    public ProspectiveStudentDAOV2(Contact con) {
        this.p360Builder = new Person360.Person360Builder(con).createContactPointAffiliations(false);
        init();
    }

    /**
     * @description Run the build process of the Person360 class
     * @return a built Person360 class
     */
    public Person360 buildPerson360() {
        this.p360 = this.p360Builder.build();
        return this.p360;
    }

    private void init() {
        this.contactQualificationList = new List<Contact_Qualification__c>();
        this.campaignDAO = new ProspectiveStudentCampaignDAO();
    }
}