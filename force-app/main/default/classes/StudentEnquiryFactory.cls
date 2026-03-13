/**
 * @author              Kristian Vegerano
 * @description         Factory class for enquiries submitted by students - addressed to students
 * @History                     
 *      AUG.08.2018     Kristian Vegerano   -   Created
 */
public class StudentEnquiryFactory{
    
    /**
     * Related contact record for the enquiry to be created
     */
    private Contact relatedContact;
    
    /**
     * Related contact record for the enquiry to be created
     */
    private Lead relatedLead;
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Constructor
     *  @param          Contact relatedContact - contact person for the enquiry
     *                  Lead relatedLead - lead where the enquiry is addressed into 
     */
    public StudentEnquiryFactory(Contact relatedContact, Lead relatedLead){
        this.relatedContact = relatedContact;
        this.relatedLead = relatedLead;
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Method for creating student related enquiries
     */
    public Case createEnquiry(){
        //Initialize Enquiry
        Case studentEnquiry = new Case();
        
        //Assign the contact on the generated enquiry
        studentEnquiry.ContactId = relatedContact.Id;
        //Default the enquiry as standard enquiry (Tier 1)
        studentEnquiry.RecordTypeID = EnquiryUtil.CASE_RECTYPE_STANDARDENQUIRY;
        //Default the enquiry's student type as domestic
        studentEnquiry.Student_Type__c = Label.Student_Type_Domestic;
        //Default the enquiry's enquiry type as Current Course
        studentEnquiry.Enquiry_Type__c = Label.Current_Course;
        
        //Process lead related details
        //Check if the enquiry requested is related to a lead
        if(relatedLead != null){
            
            //Check if the related lead has a student type of domestic or international
            if(relatedLead.Student_type__c == Label.Student_Type_Domestic){
                
               studentEnquiry.Student_Type__c = Label.Student_Type_Domestic;
                
            }else if(relatedLead.Student_type__c == Label.Student_Type_International){
                
                //Set the enquiry to be created as future course
                studentEnquiry.Student_Type__c = Label.Student_Type_International;
                
                //Set the origin for the generic - pre-application international form
                studentEnquiry.Origin = Label.Web_Future_Students_International;
            }
            
            //Check if the lead related is a prospective student
            if(relatedLead.recordTypeId == StagedProspectiveStudentUtil.LEAD_RECTYPE_PROPECTIVESTUDENT){
                
                //Set the enquiry to be created as future course
                studentEnquiry.Enquiry_Type__c = Label.Future_Course;
                
            }
            
        }
        
        return studentEnquiry;
    }
}