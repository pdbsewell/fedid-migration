/**
 * @author          mac.domingo@monash.edu
 * @description		EPCP-2899 - Enquiry Archiving Framework. Class that will return an instance of the CustomIterable
 * @date            15-08-2023
 * @group			Platforms
 * @revision
 *     2023-15-08 Mac Domingo Created
*/
public class IterateGenericSobject implements Iterable<IterableWrapper>{
    public Iterator<IterableWrapper> Iterator(){
       return new CustomIterable();
    }
 }