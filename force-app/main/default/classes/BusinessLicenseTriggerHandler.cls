/**
 * @author			Russell Cadapan
 * @description		Trigger Handler for Business License Trigger
 * @revision		10/06/2019 - Russell Cadapan - Created
 */
public class BusinessLicenseTriggerHandler {
	/**
	 * @author			Russell Cadapan
	 * @description		Class to share the newly inserted Business Unit to the users with roles that reports to it based from the custom metadata License_Mapping__mdt
	 * @revision		10/06/2019 - Russell Cadapan - Created
	 */
	public class ShareRecordManually implements Triggers.Handler{
		public void run(){
			// a map of Business License Id with Name as identifier
			Map<String, Id> mapBusinessLicense = new Map<String, Id>();

			for(Business_License__c bl: (List<Business_License__c>) Trigger.new){
				mapBusinessLicense.put(bl.Name, bl.Id);
			}
			// map of role in the system
			Map<Id, UserRole> mapUserRole = new Map<Id, UserRole>([SELECT Id, Name FROM UserRole]);
			// a map of Role and Business Unit
			Map<String, String> mapRoleToBusinessUnit = new Map<String, String>();
			// set of User Role
			Set<String> setUserRoles = new Set<String>();

			// for each license mapping, store each pair in a map
			for(License_Mapping__mdt lm: [SELECT Id, MasterLabel, Business_Unit__c FROM License_Mapping__mdt WHERE Business_Unit__c IN: mapBusinessLicense.keySet()]){
				if(lm.MasterLabel != mapUserRole.get(UserInfo.getUserRoleId()).Name && lm.Business_Unit__c != 'Monash Connect'){
					mapRoleToBusinessUnit.put(lm.MasterLabel, lm.Business_Unit__c);
					setUserRoles.add(lm.MasterLabel);
				}
			}

			// list of object share to be inserted
			List<Business_License__Share> listObjectShare = new List<Business_License__Share>();

			// get all users that are assigned to the roles under the newly inserted Business Unit
			for(User u: [SELECT Id, UserRole.Name FROM User WHERE IsActive = TRUE AND UserRole.Name IN: setUserRoles]){
				// if the role is existing in the mapping
				if(mapRoleToBusinessUnit.containsKey(u.UserRole.Name)){
					// get the business unit name
					String strParentRole = mapRoleToBusinessUnit.get(u.UserRole.Name);
					// if the user role reports to the newly inserted business unit
					if(mapBusinessLicense.containsKey(strParentRole)){
						// share the business unit record manually via object share
						Id businessLicenseId = mapBusinessLicense.get(strParentRole);
						Business_License__Share businessLicenseShare = new Business_License__Share();
						businessLicenseShare.ParentId = businessLicenseId;
						businessLicenseShare.UserOrGroupId  = u.Id;
						businessLicenseShare.AccessLevel  = 'Read';
						businessLicenseShare.RowCause = Schema.Business_License__Share.RowCause.Manual;
						listObjectShare.add(businessLicenseShare);			
					}
				}
			}

			// dml of object share
			if(!listObjectShare.isEmpty()){
				insert listObjectShare;
			}
		}
	}
}