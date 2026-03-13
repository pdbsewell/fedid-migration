/**
 * @description       : wrapper class for a Contact and it's existing duplicate values
 * @author            : Nick Guia
 * @date              : 14-09-2020
 * @group             : Common
 * @last modified on  : 03-07-2023
 * @last modified by  : Nick Guia
**/
public virtual inherited sharing class DuplicateContact {
    
    public Contact con {get; set;}
    public List<Contact> matchedContactRecords {get; set;}

    public DuplicateContact(Contact con) {
        this.con = con;
        init();
    }

    public DuplicateContact() {
        init();
    }

    /**
     * @description checks if the class has existing duplicate records
     * @return Boolean if wrapper class has duplicate Contact records
     */
    public Boolean hasDuplicates() {
        Boolean hasDupe = false;
        if(this.matchedContactRecords.size() > 0) {
            hasDupe = true;
        }
        return hasDupe;
    }

    private void init() {
        this.matchedContactRecords = new List<Contact>();
    }
}