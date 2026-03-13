/**
* @author Angelo Rivera
* @date 09.Jan.2020
* @group Enquiry Management
* @description  Person Notes Wrapper class
* @revision     APRivera, 09.Jan.2020 - Created <br/>
*/

public class MIXAPI_StudentPersonNote {
    public clslinks pnlinks;
    public cls_notes[] notes;

    public class clslinks {
        public clsself pnself;
    }
    public class clsself {
        public String href = '';
    }

    public class cls_notes {
        public String type = '';
        public String admissionApplicationId = '';
        public String noteType = '';
        public String typeDescription = '';
        public String updateBy = '';
        public String updateOn = '';
        public String text = '';
        public String portalApplicationID = '';
    }
}