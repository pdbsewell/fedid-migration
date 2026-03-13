/**
 * @author       : Ibrahim Rumi
 * @date         : 01-11-2022
 * @group        : Event Management
 * @description  : class to fetch the group ids based on mapping and the group type and helps to share the related attendees
 * @revision        
 *  2022-11-01 - Ibrahim Rumi - Added Other Department Faculty mapping to PUBLIC_GROUP_API_NAMES map
**/
public without sharing class BTEventGroupAccessMapping {

    private static BTEventGroupAccessMapping instance;

    public static final string BT_FACULTY = 'Faculty';
    public static final string BT_CAMPUS = 'Campus';
    
    //'group developer name' => new PublicGroupAccessMap('group type' ie. Faculty or Campus,
    //													 'source value' ie. Faculty of Arts/Clayton,
    //													 'group developer name')
    private final Map<String, PublicGroupAccessMap> PUBLIC_GROUP_API_NAMES = new Map<String, PublicGroupAccessMap> {
            'ACCESS_BT_Faculty_Arts' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Arts','ACCESS_BT_Faculty_Arts'),
            'ACCESS_BT_Faculty_Art_Design' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Art Design and Architecture','ACCESS_BT_Faculty_Art_Design'),
            'ACCESS_BT_Faculty_Business_Economics' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Business and Economics','ACCESS_BT_Faculty_Business_Economics'),
            'ACCESS_BT_Faculty_Education' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Education','ACCESS_BT_Faculty_Education'),
            'ACCESS_BT_Faculty_Engineering' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Engineering','ACCESS_BT_Faculty_Engineering'),
            'ACCESS_BT_Faculty_Faculty_of_Science' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Science','ACCESS_BT_Faculty_Faculty_of_Science'),
            'ACCESS_BT_Faculty_IT' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Information Technology','ACCESS_BT_Faculty_IT'),
            'ACCESS_BT_Faculty_Law' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Law','ACCESS_BT_Faculty_Law'),
            'ACCESS_BT_Faculty_MNHS' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Medicine, Nursing and Health Sciences','ACCESS_BT_Faculty_MNHS'),
            'ACCESS_BT_Faculty_Pharmacy' => new PublicGroupAccessMap(BT_FACULTY,'Faculty of Pharmacy and Pharmaceutical Sciences','ACCESS_BT_Faculty_Pharmacy'),
            'ACCESS_BT_Other_Department' => new PublicGroupAccessMap(BT_FACULTY,'Other Department','ACCESS_BT_Other_Department')
    	};
            
    private Map<String, Map<String, Id>> valueByGroupTypes;
    
    /**
    * @description constructor to instantiate the class to fetch the required data
    **/
    public BTEventGroupAccessMapping() {
        init();
        setvalueByGroupTypesMap();
    }

    /**
    * @description singleton method to instantiate the instance
    **/
    public static BTEventGroupAccessMapping getInstance() {
        if(instance == null) {
            instance = new BTEventGroupAccessMapping();
        }
        return instance;
    }

    /**
    * @description init method to fetch the required group data
    **/
    private void init() {
        Map<String, PublicGroupAccessMap> pgAccessMap = this.PUBLIC_GROUP_API_NAMES;
        for(group grp: [SELECT Id,Name,RelatedId,Type,developername 
                        FROM Group 
                        WHERE developername IN:pgAccessMap.keyset()])
        {                
            PublicGroupAccessMap grpMap = pgAccessMap?.get(grp.developername);
            if(grpMap != null){
                grpMap.pgId = grp.Id;
            }
        }
    }

    /**
    * @description method to process a list of PublicGroupAccessMap into a map of maps for easier processing of data
    **/
    private void setvalueByGroupTypesMap(){
        this.valueByGroupTypes = new Map<String, Map<String, Id>>();
        
        for(PublicGroupAccessMap grpmap: this.PUBLIC_GROUP_API_NAMES.values()){
            if(this.valueByGroupTypes.get(grpmap.groupType) == null)
            {
                this.valueByGroupTypes.put(grpmap.groupType, new Map<String, Id>{grpmap.sourceValue => grpmap.pgId});
            }
            else
            {
                this.valueByGroupTypes.get(grpmap.groupType).put(grpmap.sourceValue, grpmap.pgId);
            }
        }
    }

    /**
    * @description wrapper class to process the public group
    **/
    public class PublicGroupAccessMap {
        public String groupType;
        public String sourceValue;
        public String pgApiName;
        public Id pgId;

        /**
        * @description constructor to set the required variables to fetch the public group id
        **/
        public PublicGroupAccessMap(String groupType, String sourceValue, String pgApiName) {
			this.groupType = groupType;
            this.sourceValue = sourceValue;
            this.pgApiName = pgApiName;
        }
    }
    
    /**
    * @description returns the map of corresponding source value and public group ids based on group type
    **/
    public Map<String,Id> getGroupType(String groupType) {
        return this.valueByGroupTypes.get(groupType);
    }
 
	/**
    * @description static method to process the logic to return the related public group id and group type
    **/
    public static Result getPublicGroupId(Request req) {
        BTEventGroupAccessMapping mapping = BTEventGroupAccessMapping.getInstance();
        Result res = new Result();
        
        if(String.valueof(req.faculty)!= null){
            res.publicGroupId = mapping.getGroupType(BT_FACULTY)?.get(req.faculty);
            res.groupType = BT_FACULTY;
            
            if(res.publicGroupId == null && String.valueof(req.campus)!= null){
                res.publicGroupId = mapping.getGroupType(BT_CAMPUS)?.get(req.campus);
                res.groupType = BT_CAMPUS;
            }
            
        }else if(String.valueof(req.campus)!= null){
            res.publicGroupId = mapping.getGroupType(BT_CAMPUS)?.get(req.campus);
            res.groupType = BT_CAMPUS;
        }
        
        return res;
    }
    
    /**
    * @description external invocable method which accepts a list of requests and returns the responses
    **/
    @InvocableMethod (label = 'Get Public Group ids' description = 'returns the public group id and the group type ie Faculty or Campus')
    public static List<Result> getPublicGroupIds(List<Request> requests) {
        
        List<Result> resList = new List<Result>();
        for (Request req : requests) {
          resList.add(getPublicGroupId(req));
        }
        return resList;
    }
    
    /**
    * @description request class with invocable variables to pass the required faculty and campus details as input
    **/
    public class Request {
        @InvocableVariable(label='faculty' description='the faculty details of the parent event')
        public String faculty;
        @InvocableVariable(label='campus' description='the campus details of the parent event')
        public String campus;
    }
    
    /**
    * @description Result class with invocable variables to pass the public group id and group type as output
    **/
    public class Result {
        @InvocableVariable(label='public group id' description='returns the public group id')
        public id publicGroupId;
        @InvocableVariable(label='group Type' description='returns the group type of the public group ie campus/faculty')
        public String groupType;
    }
}