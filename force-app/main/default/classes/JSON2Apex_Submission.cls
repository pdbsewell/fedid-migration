/***********************************************************************
** Author: Shalini Mendu
** Created Date: 6.SEP.2018
** Description: JSON file for submission  data
***********************************************************************/
public class JSON2Apex_Submission {
    public String form{get;set;}
    public String timestamp{get;set;}
    public list<data> data{get;set;}
    public String id{get;set;}
    public class data{
        public String field{get;set;}
        public String value{get;set;}
    }

    public Map<String, String> getFieldIDValueMap(){
        Map<String, String> fldIdValMap = new Map<String, String>();
        List<Data> dataList = data;
        for(Data dd: dataList)
        {
            fldIdValMap.put(dd.field, dd.value);
        }
        return fldIdValMap;
    }

    public String getFormId()
    {
        return form;
    }


}