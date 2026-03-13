/**
 * @author Ryan Wilson (OAKTON)
 * @date 13.AUG.2017
 * @group API Message
 * @description Request wrapper class for Admissions_AgentPortalCommsService
 */
global without sharing class ObdAgentPortalCommsRequest {
	/**
	 * @author Trent De Laney
	 * @date 13 Dec 2019 at 3:15:42 pm
	 * @group Test Class
	 * @description Used as a wrapper for the request
	 */
	global class CommsWrapper {
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String enquiryRecordId {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String callistaPersonId {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String agentOrgUnitId {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String agencyName {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String staffName {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String phoneNumber {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String messageSubject {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String messageBody {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String category {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String subCategory {get; set;}
		/**
		* @author Trent De Laney
		* @description Getter and Setter
		* @date 13 Dec 2019 at 3:16:06 pm
		* @param String
		* @return String
		*/
		public String applicantId {get; set;}
	}
}