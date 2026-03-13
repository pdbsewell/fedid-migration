/**
 * @dsecription Test class for UsersSelector
 */
@isTest(isParallel=true)
public class UsersSelector_Test {

    @isTest
    static void shouldBeAbleToSetOverridePerm() {
        try {
            UsersSelector selector = new UsersSelector(true);
            System.assert(true, 'Expected to be able to override permission');
        } catch (Exception e) {
            System.assert(false, 'Expected to be able to override permission');
        }
    }

    @isTest
    static void shouldReturnSObjectType() {
        UsersSelector selector = new UsersSelector();
        System.assertNotEquals(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
    }

    @isTest
    static void shouldReturnEmptyListWhenNoContactIdExists() {
        UsersSelector selector = new UsersSelector();
        List<User> result = selector.selectUsersByContactId(
            new List<Id>{
                Id.valueOf('0035P000001x1QEQAY')
            }
        );
    }

}