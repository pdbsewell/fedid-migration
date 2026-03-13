/**
 * @author              Kristian Vegerano
 * @description         Factory class for creating enquiries
 * @History                     
 *      AUG.08.2018     Kristian Vegerano   -   Created
 */
public class EnquiryFactory{
    
    /**
     * Purpose of the enquiry to be created
     */
    private EnquiryUtil.EnquiryPurpose enquiryPurpose;
    
    /**
     * Related contact record for the enquiry to be created
     */
    private Contact relatedContact;
    
    /**
     * Related contact record for the enquiry to be created
     */
    private Lead relatedLead;
    
    /**
     * Enquiry managed by the factory
     */
    public Case caseInstance;
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Factory Constructor
     *  @param          EnquiryPurpose purpose - defines what type of enquiry should be created
     */
    public EnquiryFactory(EnquiryUtil.EnquiryPurpose enquiryPurpose){
        this.enquiryPurpose = enquiryPurpose;
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Factory Constructor
     *  @param          EnquiryPurpose purpose - defines what type of enquiry should be created
     *                  Contact relatedContact - contact person for the enquiry
     */
    public EnquiryFactory(EnquiryUtil.EnquiryPurpose enquiryPurpose, Contact relatedContact){
        this.enquiryPurpose = enquiryPurpose;
        this.relatedContact = relatedContact;
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Factory Constructor
     *  @param          EnquiryPurpose purpose - defines what type of enquiry should be created
     *                  Contact relatedContact - contact person for the enquiry
     *                  Lead relatedLead - lead where the enquiry is addressed into
     */
    public EnquiryFactory(EnquiryUtil.EnquiryPurpose enquiryPurpose, Contact relatedContact, Lead relatedLead){
        this.enquiryPurpose = enquiryPurpose;
        this.relatedContact = relatedContact;
        this.relatedLead = relatedLead;
    }
    
    /**
     *  @author         Kristian Vegerano
     *  @description    Method for dynamic creation of enquiries depending on what purpose and related records on the enquiry
     */
    public Case createEnquiry(){
        //Instantiate the relevant type of enquiry
        if(enquiryPurpose == EnquiryUtil.EnquiryPurpose.GENERAL){
            
            //Create a generic enquiry record
            caseInstance = new Case();
            
        }else if(enquiryPurpose == EnquiryUtil.EnquiryPurpose.STUDENT){
            
            //Create an enquiry record asked by a student
            StudentEnquiryFactory studentEnquiry = new StudentEnquiryFactory(relatedContact, relatedLead);
            caseInstance = studentEnquiry.createEnquiry();
            
        }else if(enquiryPurpose == EnquiryUtil.EnquiryPurpose.STAFF){
            
            //Create an enquiry record asked by a staff
            caseInstance = new Case();
            
        }else if(enquiryPurpose == EnquiryUtil.EnquiryPurpose.AGENT){
            
            //Create an enquiry record asked by an agent
            caseInstance = new Case();
            
        }
        
        return caseInstance;
    }
}