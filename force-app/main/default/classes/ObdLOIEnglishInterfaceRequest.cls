/*******************************************************************************
* @author:      Shalini Mendu
* @date:        11.Feb.2020
* @description: SFTN-455-Admission Test Result: Language of Instruction/ Country of schooling pass to Callista
* @revision: 
*******************************************************************************/
public class ObdLOIEnglishInterfaceRequest{
    public String resultType{get;set;}
    public Boolean completed{get;set;}
    public String verificationStatus{get;set;}
    public list<applications> applications{get;set;}
    public String testType{get;set;}
    public list<subscores> subscores{get;set;}
    public String type{get;set;}
    public class subscores{
        public String scoreType{get;set;}
        public String score{get;set;}
        public String type{get;set;}
    }
    public class coursePreferences{
        public String type{get;set;}
        public String courseCode{get;set;}
        public Integer admissionApplNumber{get;set;}
    }
    public class applications{
        public String type{get;set;}
        public list<coursePreferences> coursePreferences{get;set;}

    }
}