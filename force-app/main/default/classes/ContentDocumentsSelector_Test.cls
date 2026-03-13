/**
 * @desription Test class for ContentDocumentsSelector
 */
@isTest(isParallel=true)
public class ContentDocumentsSelector_Test {

    @isTest
    static void shouldReturnSObjectType() {
        ContentDocumentsSelector selector = new ContentDocumentsSelector();
        System.assertNotEquals(null, selector.getSObjectType(), 
            'Expected getSObjectType to return a value');
    }

    @isTest
    static void shouldReturnEmptyListWhenIdsDoesNotExistInSystem() {
        Id idThatDoesNotExist = Id.valueOf('0695P0000002WgMQAU');

        ContentDocumentsSelector selector = new ContentDocumentsSelector();
        List<ContentDocument> result = selector.selectById(
            new Set<Id>{idThatDoesNotExist}
        );
        System.assertEquals(new List<ContentDocument>(), result, 
            'Expected an empty');
    }
}