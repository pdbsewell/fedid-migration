/**
 * @description Class for Date calculations
 * @group Date
 */
public class DateUtil {

    /**
     * @description Calculates the date after years has been added to a date.
     * <p>
     * Unlike the the Date class'es addYears() method, this method can handle 
     * years where the input is a decimal. 
     * However, adding years where it results in adding partial days is not 
     * supported and throws an UnsupportedOperationException. 
     * Example:
     * years = 1.5 (GOOD - 1 year + 6 months)
     * years = 1.4 (NOT SUPPORTED because 0.4 x 12 = 4.8 = 4.8 months???)
     * </p>
     * @param initialDate The initial date for calculation
     * @param years The number of years to be added to the initial date
     * @return A Date with the years added to the initial date
     */
    public static Date addYears(Date initialDate, Decimal years) {
        
        Integer yearsRoundedDown = Integer.valueOf(Math.floor(years));
        Date result = initialDate.addYears(yearsRoundedDown);
        Decimal remainingPartYearToAdd = years - (Decimal) yearsRoundedDown;

        if (remainingPartYearToAdd != 0) {
            
            Decimal remainingMonthsToAddWithDecimal = 12 * remainingPartYearToAdd;
            
            // When required, this code can be updated so it can work with 
            // fractional months and this exception can be removed after that
            if (remainingMonthsToAddWithDecimal - 
                    Math.floor(remainingMonthsToAddWithDecimal) != 0) {
                throw new UnsupportedOperationException(
                    'Adding years where it results in partial months to be ' 
                    + 'added is not currently supported.');
            }

            Integer remainingMonthsToAdd = Integer.valueOf(
                Math.floor(remainingMonthsToAddWithDecimal)
            );
            
            result = result.addMonths(remainingMonthsToAdd);            
        }
        return result;
    }

}