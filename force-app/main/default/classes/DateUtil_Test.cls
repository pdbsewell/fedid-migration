/**
 * @description Test class for DateUtil
 */
@isTest(isParallel=true)
public class DateUtil_Test {

    @isTest
    static void shouldReturnInputDateWhenYearsToAddIsZeroAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2017, 1, 1);
        Date result = DateUtil.addYears(initialDate, 0);
        System.assertEquals(initialDate, result, 
            'Expected the input date to be returned because number of years to ' 
            + 'add is zero.'
        );
    }

    @isTest
    static void shouldReturnInputDateWhenYearsToAddIsZeroAndInputIsNotStartOfYear() {
        Date initialDate = Date.newInstance(2017, 8, 21);
        Date result = DateUtil.addYears(initialDate, 0);
        System.assertEquals(initialDate, result, 
            'Expected the input date to be returned because number of years to ' 
            + 'add is zero.'
        );
    }

    @isTest
    static void shouldReturnInputDateWhenYearsToAddIsZeroAndInputIsLeapYear() {
        Date initialDate = Date.newInstance(2016, 8, 21);
        Date result = DateUtil.addYears(initialDate, 0);
        System.assertEquals(initialDate, result, 
            'Expected the input date to be returned because number of years to ' 
            + 'add is zero.'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenYearIsNotLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2017, 1, 1);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2018, 1, 1), result,
            'Expected 1 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenYearIsNotLeapYearAndInputIsEndOfYear() {
        Date initialDate = Date.newInstance(2017, 12, 31);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2018, 12, 31), result,
            'Expected 1 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenYearIsNotLeapYear() {
        Date initialDate = Date.newInstance(2017, 3, 12);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2018, 3, 12), result,
            'Expected 1 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenYearIsLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2020, 1, 1);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2021, 1, 1), result,
            'Expected 1 year to be added correctly when the year is a leap year ' 
            + ' and year to add is 1.'
        );
    }

    @isTest
    static void shouldAddThreeYearCorrectlyWhenYearIsNotLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2017, 1, 1);
        Date result = DateUtil.addYears(initialDate, 3);
        System.assertEquals(Date.newInstance(2020, 1, 1), result,
            'Expected 3 years to be added correctly when the year is not a leap ' 
            + ' year and year to add is 3.'
        );
    }

    @isTest
    static void shouldAddThreeYearCorrectlyWhenYearIsNotLeapYearAndInputIsEndOfYear() {
        Date initialDate = Date.newInstance(2017, 12, 31);
        Date result = DateUtil.addYears(initialDate, 3);
        System.assertEquals(Date.newInstance(2020, 12, 31), result,
            'Expected 3 years to be added correctly when the year is not a leap ' 
            + ' year and year to add is 3.'
        );
    }

    @isTest
    static void shouldAddThreeYearCorrectlyWhenYearIsNotLeapYear() {
        Date initialDate = Date.newInstance(2017, 7, 3);
        Date result = DateUtil.addYears(initialDate, 3);
        System.assertEquals(Date.newInstance(2020, 7, 3), result,
            'Expected 3 years to be added correctly when the year is not a leap ' 
            + ' year and year to add is 3.'
        );
    }

    @isTest
    static void shouldAddNineYearCorrectlyWhenYearIsNotLeapYear() {
        Date initialDate = Date.newInstance(2017, 7, 3);
        Date result = DateUtil.addYears(initialDate, 9);
        System.assertEquals(Date.newInstance(2026, 7, 3), result,
            'Expected 9 years to be added correctly when the year is not a leap ' 
            + ' year and year to add is 9.'
        );
    }

    @isTest
    static void shouldAddThreeYearCorrectlyWhenYearIsLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2020, 1, 1);
        Date result = DateUtil.addYears(initialDate, 3);
        System.assertEquals(Date.newInstance(2023, 1, 1), result, 
            'Expected 3 years to be added correctly when the year is a leap ' 
            + ' year and year to add is 3.'
        );
    }

    @isTest
    static void shouldAddNineYearCorrectlyWhenYearIsLeapYear() {
        Date initialDate = Date.newInstance(2020, 1, 1);
        Date result = DateUtil.addYears(initialDate, 9);
        System.assertEquals(Date.newInstance(2029, 1, 1), result, 
            'Expected 9 years to be added correctly when the year is a leap ' 
            + ' year and year to add is 9.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenYearIsNotLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2017, 1, 1);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2018, 7, 1), result,
            'Expected 1.5 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenYearIsNotLeapYear() {
        Date initialDate = Date.newInstance(2017, 4, 13);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2018, 10, 13), result,
            'Expected 1.5 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenYearIsNotLeapYearAndInputIsEndOfYear() {
        Date initialDate = Date.newInstance(2017, 12, 31);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2019, 6, 30), result,
            'Expected 1.5 year to be added correctly when the year is not a leap ' 
            + ' year and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenYearIsLeapYearAndInputIsStartOfYear() {
        Date initialDate = Date.newInstance(2016, 1, 1);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2017, 7, 1), result,
            'Expected 1.5 year to be added correctly when the year is a leap ' 
            + ' year and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddTwoPointFiveYearCorrectlyWhenSecondYearIsLeapYear() {
        Date initialDate = Date.newInstance(2019, 9, 15);
        Date result = DateUtil.addYears(initialDate, 2.5);
        System.assertEquals(Date.newInstance(2022, 3, 15), result,
            'Expected 2.5 year to be added correctly when the year timespan ' 
            + ' contains a leap year and year to add is 2.5.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenCalculatedDateEndsOnLeapYearDay() {
        Date initialDate = Date.newInstance(2018, 8, 29);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2020, 2, 29), result,
            'Expected 1.5 year to be added correctly when the year timespan ' 
            + ' ends on a leap year day (Feb 29) and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddOnePointFiveYearCorrectlyWhenCalculatedDateEndsOnLeapYearButBeforeLeapDay() {
        Date initialDate = Date.newInstance(2018, 8, 26);
        Date result = DateUtil.addYears(initialDate, 1.5);
        System.assertEquals(Date.newInstance(2020, 2, 26), result,
            'Expected 1.5 year to be added correctly when the year timespan ' 
            + ' ends on a leap year but before Feb 29 and year to add is 1.5.'
        );
    }

    @isTest
    static void shouldAddNinePointFiveYearCorrectly() {
        Date initialDate = Date.newInstance(2013, 8, 29);
        Date result = DateUtil.addYears(initialDate, 9.5);
        System.assertEquals(Date.newInstance(2023, 2, 28), result,
            'Expected 9.5 year to be added correctly when the year timespan ' 
            + ' contains two leap years and year to add is 9.5.'
        );
    }

    @isTest
    static void shouldAddPointTwoFiveYearCorrectly() {
        Date initialDate = Date.newInstance(2009, 12, 3);
        Date result = DateUtil.addYears(initialDate, 0.25);
        System.assertEquals(Date.newInstance(2010, 3, 3), result,
            'Expected 0.25 year to be added correctly'
        );
    }

    @isTest
    static void shouldAddHalfYearCorrectlyWhenStartingOnALeapDay() {
        Date initialDate = Date.newInstance(2020, 2, 29);
        Date result = DateUtil.addYears(initialDate, 0.5);
        System.assertEquals(Date.newInstance(2020, 8, 29), result,
            'Expected 0.5 years to be added correctly when the initial date is ' 
            + '29 Feb'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenStartingOnALeapDay() {
        Date initialDate = Date.newInstance(2020, 2, 29);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2021, 2, 28), result,
            'Expected 1 years to be added correctly when the initial date is ' 
            + '29 Feb'
        );
    }

    @isTest
    static void shouldAddFourYearCorrectlyWhenStartingOnALeapDay() {
        Date initialDate = Date.newInstance(2020, 2, 29);
        Date result = DateUtil.addYears(initialDate, 4);
        System.assertEquals(Date.newInstance(2024, 2, 29), result,
            'Expected 4 years to be added correctly when the initial date is ' 
            + '29 Feb'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenDayIsThirtyFirst() {
        Date initialDate = Date.newInstance(2020, 10, 31);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2021, 10, 31), result,
            'Expected 1 years to be added correctly when the initial day is ' 
            + '31'
        );
    }

    @isTest
    static void shouldAddOneYearCorrectlyWhenDayIsThirty() {
        Date initialDate = Date.newInstance(2020, 11, 30);
        Date result = DateUtil.addYears(initialDate, 1);
        System.assertEquals(Date.newInstance(2021, 11, 30), result,
            'Expected 1 years to be added correctly when the initial day is ' 
            + '30'
        );
    }

    @isTest
    static void shouldThrowUnsupportedOperationIfYearsToAddResultsInPartialMonths() {
        Date initialDate = Date.newInstance(2009, 12, 3);
        try {
            Date result = DateUtil.addYears(initialDate, 1.4);
            System.assert(false, 'Expected an unsupported operation exception '
                + 'because 1.4 years results in partial months where partial ' 
                + ' month calculation has not been implmented'
            );
        } catch (UnsupportedOperationException e) {
            System.assert(true, 'Expected an unsupported operation exception '
                + 'because 1.4 years results in partial months where partial ' 
                + ' month calculation has not been implmented'
            );
        } catch (Exception e) {
            System.assert(false, 
                'Expected Unsuppported Exception instead of Exception'
            );
        }
    }

}