global class EngageRelatedListExternalOverride extends ucinn_ascendv2.ascend_UI_TableControllerGlobalExtension {
	
    global override Integer queryRelatedListCount(Map<String, Object> params) {
        return Database.countQuery((String)params.get('query'));
    }
    global override List<SObject> queryRelatedListSOQL(Map<String, Object> params) {
        return Database.query((String)params.get('query'));
        
    }
    global override List<List<SObject>> queryRelatedListSOSL(Map<String, Object> params){
        return Search.query((String)params.get('query'));
    }
}