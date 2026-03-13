global class BatchFieldLabel implements Queueable , Database.AllowsCallouts{

    global final Course_Application_Answers__c caa{get;set;}

    global BatchFieldLabel(Course_Application_Answers__c caapar) {
        caa = caapar;
    }

    public void execute(QueueableContext context) {

        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescribe = sobjectSchemaMap.get('Course_Application_Answers__c').getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        List<String> fieldNames = new List<String>();
        Set<String> stdFldSet = new Set<String>{'Id','OwnerId','IsDeleted','Name','CreatedDate','CreatedById','LastModifiedDate','LastModifiedById','SystemModstamp'};

        for(Schema.SObjectField fieldDef : fieldMap.values())
        {
            Schema.Describefieldresult fieldDescResult = fieldDef.getDescribe();
            String name = fieldDescResult.getName();
            if(!stdFldSet.contains(name))
                fieldNames.add(name);
           Schema.DisplayType type = fieldDescResult.getType();

        }
       // System.debug('fieldNames=='+fieldNames);
        String submissionId = caa.SubmissionId__c;
        //System.debug('submissionId=='+submissionId);

        String respData = FieldLabelCallOut.getSubmissionData(submissionId);
        JSON2Apex_Submission subObj = (JSON2Apex_Submission)JSON.deserialize(respData, JSON2Apex_Submission.class);
        String formId = subObj.getFormId();
        Map<String, String> fldIDValMap = subObj.getFieldIDValueMap();
        //System.debug('formId=='+formId);
        String respFFData = FieldLabelCallOut.getFormData(formId);

        JSon2Apex_FormFields obj = (JSon2Apex_FormFields)JSON.deserialize(respFFData, JSon2Apex_FormFields.class);
        System.debug('objAbc__c=='+obj);
        Map<String, String> fldIDNameMap = new Map<String, String>();
        for(JSon2Apex_FormFields.Fields fld:obj.fields)
        {
            fldIDNameMap.put(fld.Id, fld.label);
        }
        System.debug('fieldNames=='+fieldNames);
        String soql = 'SELECT ';
        String flds = '';
        for (String field: fieldNames)
        {
           System.debug('flds=='+flds);
            flds = flds +  (field +',');
        }
        flds = flds.substringBefore(',');
        soql += flds+ ' FROM Course_Application_Answers__c WHERE ID=\''+caa.Id+'\'';
        System.debug('soql=='+soql);
        Course_Application_Answers__c cc = (Course_Application_Answers__c)Database.query(soql)[0];

        for (String field: fieldNames)
        {
            for(String key:fldIDValMap.keySet())
            {
                if(fldIDValMap.get(key) ==  caa.get(field))
                {
                    for(String key1:fldIDNameMap.keySet())
                    {
                            if(key1 ==  key)
                            {
                                if(field!='ACPLookup__c')
                                    cc.put(field, fldIDNameMap.get(key1)+'='+(String)caa.get(field) );
                            }
                    }
                }
            }
        }
        update cc;

    }


}