/**
 * @description		Handle icon display
 * @date            Apr.2024
 * @group			MOnash Connect
 * @revision
 *     2024-06 - Inderpal Dhanoa - PENGAGE-2758 Enhancement to handle Bequestor
*/
public class EngageServiceIndicatorAlertsCC {

	/**
     * Method to retrieve the CUstom Metadata mapping for the Alert indicators
     */
	@AuraEnabled
	public static String getCustomMetadataItems(Id recordId) {
		String sObjDeveloperName = recordId.getSObjectType().getDescribe().getName(), contentAsset = 'ContentAsset';
		Set<String> s_DevName = new Set<String>();
		Map<String, String> m_contAsstByImageURL = new Map<String, String>();
		List<AlertIndicatorWrapper> wrapperList = new List<AlertIndicatorWrapper>();
		AlertIndicatorWrapper obj; 
		List<Engage_Service_Indicator_Alerts__mdt> serviceIndicatorAlertCustomMetadata = new List<Engage_Service_Indicator_Alerts__mdt>();
 		for(Engage_Service_Indicator_Alerts__mdt metaData : [SELECT Field_API_Name__c, Label, Text_Background_Color__c,Tooltip__c, 
															Icon_Variant__c, Icon__c, Type__c, SObject_Name__c 
															FROM Engage_Service_Indicator_Alerts__mdt 
															WHERE SObject_Name__c =: sObjDeveloperName]){
			obj = new AlertIndicatorWrapper();
			obj.fieldAPIName = metaData.Field_API_Name__c;
			obj.label = metaData.Label;
			obj.textBkgColor = metaData.Text_Background_Color__c;
			obj.iconVariant = metaData.Icon_Variant__c;
			obj.icon = metaData.Icon__c;
			obj.type = metaData.Type__c;
			obj.toolTip = metaData.Tooltip__c;
			if(metaData.Type__c == contentAsset){
				s_DevName.add(metaData.Icon__c);
			}
			wrapperList.add(obj);
		}
		if(!s_DevName.isEmpty()){
			for(ContentVersion ca : [SELECT Title,Field_Image_URL__c FROM ContentVersion WHERE IsLatest = true AND Title IN :s_DevName]){
				m_contAsstByImageURL.put(ca.Title, ca.Field_Image_URL__c);
			}
			for(AlertIndicatorWrapper objct : wrapperList){
				if(objct.type == contentAsset && m_contAsstByImageURL.containsKey(objct.icon)){
					objct.imageURL = m_contAsstByImageURL.get(objct.icon);
				}
			}
		}
 		return JSON.serialize(wrapperList);
	}

	public class AlertIndicatorWrapper{
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String textBkgColor;
        @AuraEnabled
        public String iconVariant;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String type;
		@AuraEnabled
        public String imageURL; 
		@AuraEnabled
        public String toolTip;
    }
}