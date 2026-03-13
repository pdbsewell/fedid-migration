/*******************************************************************************
* @author		Sethu Venna
* @date         04/10/2024   
* @description  Request structure for sending Graduate Research documents to MIX 
* @revision     05/10/2024 - Initial Version
*******************************************************************************/
public class GRSendDocumentJSONClass {

  public Cls_document document;

	/*******************************************************************************
    * @author		Sethu Venna
    * @date         04/10/2024   
    * @description  Request structure for document
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
  public class Cls_document {
		public String type;	
		public String contentType;	
		public String filename;
		public String binaryString;	
		public String comment;
		public Cls_additionalDetails[] additionalDetails;
	}

	/*******************************************************************************
    * @author		Sethu Venna
    * @date         04/10/2024   
    * @description  Request structure for additional details 
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
    public class Cls_additionalDetails {
		public String name;
		public String value;
	}

    /*******************************************************************************
    * @author		    Sethu Venna
    * @date         04/10/2024  
    * @param        json string 
    * @return       GRSendDocumentJSONClass
    * @description  parse request structure for additional details 
    * @revision     05/10/2024 - Initial Version
    *******************************************************************************/
    public static GRSendDocumentJSONClass parse(String json) {
		return (GRSendDocumentJSONClass) System.JSON.deserialize(json, GRSendDocumentJSONClass.class);
	}
}