public inherited sharing class CriteriaEvaluator {
    private CriteriaEvaluator() {}

    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Evaluate all alert criteria for a specified record
    * @param crteria alert criteria to evaluate
    * @param record instance of an sobject
    * @param aggregateResults map of aggregation
    * @return true if crtieria was evaluate successfully otherwise false
    */
    public static Boolean isMeetingCriteria(SObject record, String field, String filterValue, String operator){
        Object objectValue = getFieldValue(record, field.split('\\.'), 0); 
        
        switch on operator {
            when 'equals' {
                return isequals(objectValue,filterValue);
            }when 'not equals' {
                return isnotequals(objectValue,filterValue);
            }when 'contains' {
                return objectValue != null && filterValue.contains((String)objectValue);
            }when 'greater' {
                return isgreaterthan(objectValue,filterValue);
            }when 'greater or equals' {
                return isgreaterorequalsthan(objectValue,filterValue);
            }when 'less' {
                return issmallerthan(objectValue,filterValue);
            }when 'less or equals' {
                return issmallerorequalsthan(objectValue,filterValue);
            }when else {
                return false;
            }
        }
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Recursive method that retrieve object value of a specified field name, this handle cross object such as Opportunity.Account.Custom_Number__c
    * @param record instance of an sobject
    * @param fieldNames apiname of fields starting from direct parent(Opportunity) to field name(Customer_Number__c)
    * @param index current index of the field name list
    * @return untyped value of a field 
    */
    public static Object getFieldValue(SObject record, String[] fieldNames, Integer index){
        if (index == fieldNames.size() - 1){
            return record.get(fieldNames[index]);
        }
        if(record.getSObject(fieldNames[index]) != null){
            return getFieldValue(record.getSObject(fieldNames[index]),fieldNames, index + 1);
        }else {return null;}
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is not equals than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is not equals than right entity 
    */
    public static Boolean isnotequals(Object o, String p){
        system.debug('***instance of not equals'+o+'-'+p);
        if(o instanceof Date)               return (Date) o != (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o != (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o != (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o != (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o != (p != null ? Double.valueOf(p) : null);
        if(o instanceof Boolean)             return (Boolean) o != (p != null ? Boolean.valueOf(p) : null);
        return (String) o != p;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is equals than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is equals than right entity 
    */
    public static Boolean isequals(Object o, String p){
        system.debug('***instance equals'+o+'-'+p);
        if(o instanceof Date)               return (Date) o == (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o == (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o == (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o == (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o == (p != null ? Double.valueOf(p) : null);
        if(o instanceof Boolean)             return (Boolean) o == (p != null ? Boolean.valueOf(p) : null);
        return (String) o == p;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is smaller than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is smaller than right entity 
    */
    public static Boolean issmallerthan(Object o, String p){
        if(o instanceof Date)               return (Date) o < (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o < (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o < (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o < (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o < (p != null ? Double.valueOf(p) : null);
        return false;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is smaller than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is smaller or equals than right entity 
    */
    public static Boolean issmallerorequalsthan(Object o, String p){
        if(o instanceof Date)               return (Date) o <= (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o <= (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o <= (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o <= (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o <= (p != null ? Double.valueOf(p) : null);
        return false;
    }/**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is greater or equals than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is greater or equals than right entity 
    */
    public static Boolean isgreaterorequalsthan(Object o, String p){
        if(o instanceof Date)               return (Date) o >= (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o >= (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o >= (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o >= (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o >= (p != null ? Double.valueOf(p) : null);
        return false;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description Compare if an entity is greater than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is greater than right entity 
    */
    public static Boolean isgreaterthan(Object o, String p){
        if(o instanceof Date)               return (Date) o > (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o > (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o > (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o > Double.valueOf(p);
        if(o instanceof Double)             return (Double) o > Double.valueOf(p);
        return false;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description This method parse a date string formula into a date based on well defined syntax. 
    * @usage 
    * Date mydate1 = parseDate('TODAY|y+2');
    * Date mydate2 = parseDate('TODAY|m-2');
    * Date mydate3 = parseDate('THIS_WEEK|d-2');
    * Date mydate4 = parseDate('THIS_MONTH|m+2');
    * @param s string date
    * @return converted date
    */
    public static Date parseDate(String s){
        Date targetDate;
        try {   //try to parse string to a specific date
            targetDate = Date.valueOf(s);
        }catch(TypeException e) {
            switch on s.substring(0,s.indexOf('|') >= 0 ? s.indexOf('|') : s.length()){
                when 'TODAY' {
                    targetDate = Date.today();
                } when 'THIS_MONTH' {
                    targetDate = Date.today().toStartOfMonth();
                } when 'THIS_WEEK'{
                    targetDate = Date.today().toStartOfWeek();
                } when else{
                    System.debug('Unsupported Date Format');
                }
            }
            if (targetDate != null && s.indexOf('|') >= 0){
                String offset = s.substring(s.indexOf('|') + 1);
                switch on offset.substring(0,1) {
                    when 'd' {
                        offset = offset.removeStart('d'); 
                        targetDate = targetDate.addDays(Integer.valueOf(offset));
                    } when 'm' {
                        offset = offset.removeStart('m'); 
                        targetDate = targetDate.addMonths(Integer.valueOf(offset));
                    } when 'y' {
                        offset = offset.removeStart('y'); 
                        targetDate = targetDate.addDays(Integer.valueOf(offset));
                    } when else {
                        targetDate = null;
                        System.debug('Unsupported Date Format');
                    }
                } 
            }
        }
        return targetDate;
    }
    /**
    * @author davidbrowaeys
    * @date 11/11/2019
    * @description This method parse a datetime string formula into a datetime based on well defined syntax. 
    * @usage 
    * Datetime mydate1 = parseDatetime('NOW|H+2');
    * Datetime mydate2 = parseDatetime('NOW|M-30');
    * @param s string datetime
    * @return converted datetime
    */
    public static Datetime parseDatetime(String s){
        Datetime targetDate;
        try {   //try to parse string to a specific date
            targetDate = Datetime.valueOf(s);
        }catch(TypeException e) {   //doesn't seem to be a datetime, let's try to evaluate bit further
            switch on s.substring(0,s.indexOf('|') >= 0 ? s.indexOf('|') : s.length()){
                when 'NOW' {
                    targetDate = Datetime.now();
                } when else{    //date format not found
                    return null;
                }
            }
            if (targetDate != null && s.indexOf('|') >= 0){
                String offset = s.substring(s.indexOf('|') + 1);
                switch on offset.substring(0,1) {
                    when 'd' {
                        offset = offset.removeStart('d'); 
                        targetDate = targetDate.addDays(Integer.valueOf(offset));
                    } when 'm' {
                        offset = offset.removeStart('m'); 
                        targetDate = targetDate.addMonths(Integer.valueOf(offset));
                    } when 'y' {
                        offset = offset.removeStart('y'); 
                        targetDate = targetDate.addDays(Integer.valueOf(offset));
                    } when 'H' {
                        offset = offset.removeStart('H'); 
                        targetDate = targetDate.addHours(Integer.valueOf(offset));
                    } when 'M' {
                        offset = offset.removeStart('M'); 
                        targetDate = targetDate.addMinutes(Integer.valueOf(offset));
                    } when else {
                        System.debug('Unsupported Datetime Format');
                        targetDate = null;
                    }
                } 
            }
        }
        return targetDate;
    }
}