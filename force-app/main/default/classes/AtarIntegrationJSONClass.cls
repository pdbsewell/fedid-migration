/*******************************************************************************
* @author		Sethu Venna
* @date         12/03/2025 
* @description  Request structure for sending ATAR scores to MIX 
* @revision     12/03/2025  - Initial Version
*******************************************************************************/
public class AtarIntegrationJSONClass
{
    public Cls_qualifications qualifications;
    /*******************************************************************************
    * @author		Sethu Venna
    * @date         12/03/2025    
    * @description  Request structure for type
    * @revision     12/03/2025  - Initial Version
    *******************************************************************************/
    public class Cls_type{
        public String state;
        public String smsQualificationCode;
        public String type;
    }
    /*******************************************************************************
    * @author		Sethu Venna
    * @date         12/03/2025    
    * @description  Request structure for score
    * @revision     12/03/2025  - Initial Version
    *******************************************************************************/
    public class Cls_score{
        public Decimal value;
    }
    /*******************************************************************************
    * @author		Sethu Venna
    * @date         12/03/2025   
    * @description  Request structure for qualifications
    * @revision     12/03/2025  - Initial Version
    *******************************************************************************/
    public class  Cls_qualifications{
        public String verificationStatus;
        public Cls_score score;
        public Cls_institution institution;
        public String statusKey;
        public Integer conferredYear;
        public Cls_type type;
    }
    /*******************************************************************************
    * @author		Sethu Venna
    * @date         12/03/2025    
    * @description  Request structure for institution
    * @revision     12/03/2025  - Initial Version
    *******************************************************************************/
    public class Cls_institution{
        public String institutionCode;
        public String institutionName;
    }

    /*******************************************************************************
    * @author		Sethu Venna
    * @date         12/03/2025  
    * @param        json string 
    * @return       AtarIntegrationJSONClass
    * @description  parse request structure for additional details 
    * @revision     12/03/2025  - Initial Version
    *******************************************************************************/
    public static AtarIntegrationJSONClass parse(String json) {
		return (AtarIntegrationJSONClass) System.JSON.deserialize(json, AtarIntegrationJSONClass.class);
	}
}