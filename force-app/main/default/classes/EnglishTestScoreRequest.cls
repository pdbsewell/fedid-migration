/**
 * Created by smen0015 on 12/09/2018.
 */
public class EnglishTestScoreRequest{
    public String resultType{get;set;}
    public String grade{get;set;}
    public String comments{get;set;}
    public Integer overallScore{get;set;}
    public String achievedDate{get;set;}
    public String expiryDate{get;set;}
    public String plannedDate{get;set;}
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