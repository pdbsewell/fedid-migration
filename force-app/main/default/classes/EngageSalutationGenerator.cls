/**
 * Revision 1/4/2022 Martin Cadman 
 * Changed (swapped) the priority of the prefix and salutation fields from the primary name when building the salutation records.
 * This was required due to the preferred first name field mapping changes to Contact.Salutation__c/Name__c.Prefix & Contact.Salution_erda__c/Name__c.salutation__c
 * 
 * This code assumes the ascend trigger for name is disabled.
 * 
 * To limit the individual changes required, the PFN overrides the FN after the primary names have been identified.
 */
public class EngageSalutationGenerator {

    public static final string FULLNAME_NAME_TYPE = 'Full Name';
    public static final string INDIVIDUAL = 'Individual_Salutation';
    public static final string JOINT = 'Joint_Salutation';
    public static final string FORMAL = 'Formal';
    public static final string INFORMAL = 'Informal';

    private EngageSalutationHelper.ContactPair contactPair;

	private Name__c contactName;
	private Name__c spouseName;
	private Contact contact;
	private Contact spouse;
	private Boolean isContactPrimary;
	private Boolean isSpousePrimary;

	private Map<String, Id> salutationRecordTypeMap = new Map<String, Id>();

	private List<Ucinn_ascendv2__Salutation__c> updatedSalutationList = new List<Ucinn_ascendv2__Salutation__c>();

	public EngageSalutationGenerator(EngageSalutationHelper.ContactPair contactPair) {

		this.contactPair = contactPair;

		if (!contactPair.contact.Names__r.isEmpty()) {
			contactName = correctPrefixSuffix(replaceNameNullValuesWithBlanks(contactPair.contact.Names__r[0].clone()));
			contact = contactPair.contact;
		}

		if (contactPair.spouse != null && !contactPair.spouse.Names__r.isEmpty()) {
			spouseName = correctPrefixSuffix(replaceNameNullValuesWithBlanks(contactPair.spouse.Names__r[0].clone()));
			spouse = contactPair.spouse;

    		isContactPrimary = contactPair.contact.Account.Ucinn_ascendv2__Primary_Contact__c == contactPair.contact.Id;
    		isSpousePrimary = contactPair.spouse.Account.Ucinn_ascendv2__Primary_Contact__c == contactPair.spouse.Id;
		}

    	populateSalutationRecordTypeMap();
	}

    public void populateSalutationRecordTypeMap() {
        //Record Type Developer Name to Record ID Map for Salutations.
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Ucinn_ascendv2__Salutation__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        for (String recordTypeKey : recordTypeMap.keySet()) {
            salutationRecordTypeMap.put(recordTypeMap.get(recordTypeKey).getDeveloperName(), recordTypeMap.get(recordTypeKey).getRecordTypeId());
        }
    }


	public EngageSalutationHelper.ContactPair generateNewSalutations() {
		contactPair = new EngageSalutationHelper.ContactPair();

		if (contactName == null) return contactPair;

		updatedSalutationList.addAll(createIndividualSalutations(contactName, contact));

		//If no spouse, bypass this logic
		if (spouseName != null) {
			updatedSalutationList.addAll(createIndividualSalutations(spouseName, spouse));
			updatedSalutationList.addAll(createJointInformalSalutations());

			updatedSalutationList.addAll(createJointFormalSalutations());

			contactPair.spouse = updateContactRecognitionName(spouse);
		}

		contactPair.contact = updateContactRecognitionName(contact);

		replaceExistingSalutations(contact, spouse, updatedSalutationList);

		contactPair.salutations = updatedSalutationList;

		return contactPair;
	}

	private Contact updateContactRecognitionName(Contact contactToUpdate) {
		if (contactToUpdate.Ucinn_ascendv2__Is_Recognition_Name_Overridden__c) return contactToUpdate;

		for (Ucinn_ascendv2__Salutation__c updatedSalutation : updatedSalutationList) {
			if (updatedSalutation.Ucinn_ascendv2__Contact__c == contactToUpdate.Id) {
				if (contactToUpdate.Ucinn_ascendv2__Salutation_Preference__c == 'Individual' && updatedSalutation.RecordTypeId == salutationRecordTypeMap.get(INDIVIDUAL) && updatedSalutation.Ucinn_ascendv2__Salutation_Type__c == FORMAL) {
					contactToUpdate.Ucinn_ascendv2__Recognition_Name__c = updatedSalutation.Ucinn_ascendv2__Addressee_Line_1__c;
				} else if (contactToUpdate.Ucinn_ascendv2__Salutation_Preference__c == 'Joint' && updatedSalutation.RecordTypeId == salutationRecordTypeMap.get(JOINT) && updatedSalutation.Ucinn_ascendv2__Salutation_Type__c == FORMAL) {
					String jointRecognitionName = '';

					jointRecognitionName = updatedSalutation.Ucinn_ascendv2__Addressee_Line_1__c;
					if (updatedSalutation.Ucinn_ascendv2__Addressee_Line_2__c != null) {
						jointRecognitionName += '\\n' + updatedSalutation.Ucinn_ascendv2__Addressee_Line_2__c;
					}

					contactToUpdate.Ucinn_ascendv2__Recognition_Name__c = jointRecognitionName;
				}
			}
		}

		return contactToUpdate;
	}


	private Name__c replaceNameNullValuesWithBlanks(Name__c contactName) {
        if (contactName == null) {return contactName;}
        
        if (contactName.Prefix__c == null) {contactName.Prefix__c = '';} 
        if (contactName.Salutation__c == null) {contactName.Salutation__c = '';} 
        if (contactName.First_Name__c == null) {contactName.First_Name__c = '';}
        if (contactName.Last_Name__c == null) {contactName.Last_Name__c = '';}
        if (contactName.Middle_Name__c == null) {contactName.Middle_Name__c = '';}
        if (contactName.Suffix__c == null) {contactName.Suffix__c = '';}
        
        // PFN changes
        // If the PFN is present, use that for any first name calculations/formula
        if (contactName.preferred_first_name__c!=null) {
            contactName.first_name__c = contactName.preferred_first_name__c;
        } else {
			contactName.Preferred_First_Name__c = '';
        }
        
        return contactName;
	}

    /*Adjust professional prefix and suffixes
    ** 1.   If the prefix is any type of Professor, drop any type of doctor suffix.
    ** 2.   If the prefix is any type of Doctor, drop any type of doctor suffix.
    ** 3.   If the prefix is not a doctor and the suffix is a doctor drop the suffix and change the prefix to Dr.
    ** 4.   If the prefix is a Judge, drop any type of judge suffix.
    */
    public Name__c correctPrefixSuffix(Name__c name) {
		String prefix = name.Salutation__c; // The salutation field on name contains the extended saluation list
        String suffix = name.Suffix__c;

        if (String.isBlank(prefix) || String.isBlank(suffix)) {
            return name;
        }

        //List of custom setting values that determine if we should not append certain prefixes or the professional designations
        List<Ucinn_ascendv2__Salutation_Correction_Mapping__c> salutationCorrectionMappings = Ucinn_ascendv2__Salutation_Correction_Mapping__c.getAll().values();

        List<String> suffixList = suffix.split(';');
        List<String> newSuffixList = new List<String>();
        Set<String> suffixesToRemove = new Set<String>();

        for (Ucinn_ascendv2__Salutation_Correction_Mapping__c mapping : salutationCorrectionMappings) {

            if (String.isBlank(mapping.Ucinn_ascendv2__Prefixes__c) || String.isBlank(mapping.Ucinn_ascendv2__Professional_Designations__c)) {
                continue;
            }

            List<String> prefixes = mapping.Ucinn_ascendv2__Prefixes__c.split(';');
            List<String> professionalDesignations = mapping.Ucinn_ascendv2__Professional_Designations__c.split(';');

            if (mapping.Ucinn_ascendv2__Prefix_Replaces_Prof_Designation__c == true) {

                //PREFIX REPLACES PROF DESIGNATION
                for (String singularProfessionalDesignation : suffixList) {
                    if (prefixes.contains(prefix) && professionalDesignations.contains(singularProfessionalDesignation)) {
                        suffixesToRemove.add(singularProfessionalDesignation);
                    }
                }
            } else {

                //PROF DESIGNATION REPLACES PREFIX
                for (String singularProfessionalDesignation : suffixList) {
                    if (prefixes.contains(prefix) && professionalDesignations.contains(singularProfessionalDesignation)) {
                        // name.Prefix__c = '';
                        name.Salutation__c = '';
                    }
                }
            }
        }

        for (String profDes : suffixList) {
            if (!suffixesToRemove.contains(profDes)) {
                newSuffixList.add(profDes);
            }
        }

        name.Suffix__c = String.join(newSuffixList, ';');

        return name;
    }

    private String generateAddresseeLine(Name__c nameRecord) {
    	String addressee = '';
		// Changed for PFN handling
        if (String.isBlank(nameRecord.Salutation__c)) {
    		addressee += nameRecord.Prefix__c + ' ';
    	} else {
    		addressee += nameRecord.Salutation__c + ' ';
    	}

    	addressee += 	nameRecord.First_Name__c + ' ' +
        				// nameRecord.Middle_Name__c + ' ' + 
        				nameRecord.Last_Name__c + ' ' +
        				nameRecord.Suffix__c;

        addressee = addressee.normalizeSpace();

        return addressee;
    }


    public list<Ucinn_ascendv2__Salutation__c> createIndividualSalutations(Name__c nameRecord, Contact contactToCheckForSalutations) {
        List<Ucinn_ascendv2__Salutation__c> newSalutations = new List<Ucinn_ascendv2__Salutation__c>();

        // Changed for PFN handling
		// Individual Formal Addressee format is salutation, first name, middle, last name, suffix.
        String addressee = generateAddresseeLine(nameRecord);

        String formalInsideSalutation = getFormalInsideSalutation(nameRecord);
        String informalInsideSalutation = getInformalInsideSalutation(nameRecord);

        //Individual Formal Salutation
        Ucinn_ascendv2__Salutation__c individualFormalSalutation = new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = FORMAL,
        																								RecordTypeId = salutationRecordTypeMap.get(INDIVIDUAL),
        																								Ucinn_ascendv2__Contact__c = nameRecord.Contact__c,
        																								Ucinn_ascendv2__Inside_Salutation__c = formalInsideSalutation,
        																								Ucinn_ascendv2__Addressee_Line_1__c = addressee,
        																								Ucinn_ascendv2__Salutation_Author__c = 'Standard');

        // Individual Informal Salutation
        Ucinn_ascendv2__Salutation__c individualInformalSalutation = new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = INFORMAL,
        																								RecordTypeId = salutationRecordTypeMap.get(INDIVIDUAL),
        																								Ucinn_ascendv2__Contact__c = nameRecord.Contact__c,
        																								Ucinn_ascendv2__Inside_Salutation__c = informalInsideSalutation,
        																								Ucinn_ascendv2__Salutation_Author__c = 'Standard');

        newSalutations.add(individualFormalSalutation);
        newSalutations.add(individualInformalSalutation);

        return newSalutations;
    }

    public void replaceExistingSalutations(Contact contactToCheckForSalutations, Contact spouseToCheckForSalutations, List<Ucinn_ascendv2__Salutation__c> newSalutations) {
    	List<Ucinn_ascendv2__Salutation__c> existingSalutationsToCheck = new List<Ucinn_ascendv2__Salutation__c>();

    	if (contactToCheckForSalutations != null) existingSalutationsToCheck.addAll(contactToCheckForSalutations.Ucinn_ascendv2__Salutations_Contact__r);
    	if (spouseToCheckForSalutations != null) existingSalutationsToCheck.addAll(spouseToCheckForSalutations.Ucinn_ascendv2__Salutations_Contact__r);

    	for (Ucinn_ascendv2__Salutation__c newSalutation : newSalutations) {
	    	for (Ucinn_ascendv2__Salutation__c salutation : existingSalutationsToCheck) {

	    		if (salutation.Ucinn_ascendv2__Salutation_Type__c == newSalutation.Ucinn_ascendv2__Salutation_Type__c &&
	    			salutation.RecordTypeId == newSalutation.RecordTypeId &&
	    			salutation.Ucinn_ascendv2__Contact__c == newSalutation.Ucinn_ascendv2__Contact__c) {

	    			newSalutation.Id = salutation.Id;
	    		}
	    	}
    	}
    }

    public List<Ucinn_ascendv2__Salutation__c> createJointInformalSalutations() {
    	List<Ucinn_ascendv2__Salutation__c> newSalutations = new List<Ucinn_ascendv2__Salutation__c>();

        String names = contactName.first_name__c + ' and ' + spouseName.first_name__c;
        String namesReversed =  spouseName.first_name__c + ' and ' + contactName.first_name__c;

        if (isSpousePrimary && !isContactPrimary) {
            //If spouse is primary then put them first
            newSalutations.addAll(generateJointInformalSalutations(namesReversed, namesReversed));

        } else if (isContactPrimary && !isSpousePrimary) {
            //If contact is primary then put them first
            newSalutations.addAll(generateJointInformalSalutations(names, names));
        } else {
            //Otherwise the first constituent on the salutation will be whichever profile we are on.
            newSalutations.addAll(generateJointInformalSalutations(names, namesReversed));
        }

        return newSalutations;
    }

    private List<Ucinn_ascendv2__Salutation__c> generateJointInformalSalutations(String insideSalutation, String spouseInsideSalutation) {
    	List<Ucinn_ascendv2__Salutation__c> newSalutations = new List<Ucinn_ascendv2__Salutation__c>();

        newSalutations.add(
        	new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = INFORMAL,
        										RecordTypeId = salutationRecordTypeMap.get(JOINT),
        										Ucinn_ascendv2__Contact__c = contactName.Contact__c,
        										Ucinn_ascendv2__Contact_2__c = spouseName.Contact__c,
        										Ucinn_ascendv2__Inside_Salutation__c = insideSalutation,
        										Ucinn_ascendv2__Salutation_Author__c = 'Standard')
        );

        newSalutations.add(
        	new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = INFORMAL,
        										RecordTypeId = salutationRecordTypeMap.get(JOINT),
        										Ucinn_ascendv2__Contact__c = spouseName.Contact__c,
        										Ucinn_ascendv2__Contact_2__c = contactName.Contact__c,
        										Ucinn_ascendv2__Inside_Salutation__c = spouseInsideSalutation,
        										Ucinn_ascendv2__Salutation_Author__c = 'Standard')
        );

        return newSalutations;
    }

	// MJC
	// Individual Formal Salutation format is Saluation, last name. If prefix is not populated, use FirstName.
    private String getFormalInsideSalutation(Name__c nameRecord) {
        // Changed for PFN handling
    	if (!String.isBlank(nameRecord.Salutation__c)) {
    		return nameRecord.Salutation__c + ' ' + nameRecord.Last_Name__c;
    	} else if (!String.isBlank(nameRecord.Prefix__c)) {
    		return nameRecord.Prefix__c + ' ' + nameRecord.Last_Name__c;
    	} else {
    		return nameRecord.First_Name__c;
    	}
    }

	// If first and middle names are both initials use them, otherwise use first name.
    private String getInformalInsideSalutation(Name__c nameRecord) {
    	if (isAnInitial(nameRecord.First_Name__c) && isAnInitial(nameRecord.Middle_Name__c)) {
    		return nameRecord.First_Name__c + ' ' + nameRecord.Middle_Name__c;
    	} else {
    		return nameRecord.First_Name__c;
    	}
    }

    // Checks to see if a persons name is an initial
    public Boolean isAnInitial(String name){
        if (name.length() == 1 || (name.length() == 2 && name.mid(1,1) == '.')) {
        	return true;
        }
        return false;
    }

   	private String getPrefixOrSalutation (Name__c name) {
        // Changed for PFN handling
   		if (String.isBlank(name.Salutation__c)) {
   			return name.Prefix__c;
   		} else {
   			return name.Salutation__c;
   		}
   	}


    public List<Ucinn_ascendv2__Salutation__c> createJointFormalSalutations() {
    	String contactAdd = generateAddresseeLine(contactName);
    	String spouseAdd = generateAddresseeLine(spouseName);
    	String contactSal = getFormalInsideSalutation(contactName);
    	String spouseSal = getFormalInsideSalutation(spouseName);
    	String contactPrefix = getPrefixOrSalutation(contactName);
    	String spousePrefix = getPrefixOrSalutation(spouseName);
    	String jointAddContact = '';
    	String jointAddSpouse = '';
    	String jointSalContact = '';
    	String jointSalSpouse = '';
    	String jointAddContactLine2 = '';
    	String jointAddSpouseLine2 = '';

        //Case: No prefixes and last name is NOT the same, and there is no suffix
        //We put both names on the same line (Peter Moes and Daysha Jones)
        if (String.isBlank(contactPrefix) && String.isBlank(spousePrefix) && contactName.last_name__c != spouseName.last_name__c && (String.isBlank(contactName.Suffix__c) && String.isBlank(spouseName.Suffix__c))) {
            if (isSpousePrimary && !isContactPrimary) {
                jointAddContact = spouseAdd + ' and ' + contactAdd;
                jointAddSpouse = spouseAdd + ' and ' + contactAdd;
                jointSalContact = spouseSal + ' and ' + contactSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }
            else if (isContactPrimary && !isSpousePrimary) {
                jointAddContact = contactAdd + ' and ' + spouseAdd;
                jointAddSpouse = contactAdd + ' and ' + spouseAdd;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = contactSal + ' and ' + spouseSal;
            }
            else {
                // For other pairs switch the names so the contact you are viewing comes first
                jointAddContact = contactAdd + ' and ' + spouseAdd;
                jointAddSpouse = spouseAdd + ' and ' + contactAdd;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }
        //Case: No prefixes and last name IS the same, and there is no professional designation
        //Here we combine the first names, and append a last name for example (Peter and Daysha Moes)
        } else if (String.isBlank(contactPrefix) && String.isBlank(spousePrefix) && contactName.last_name__c == spouseName.last_name__c && (String.isBlank(contactName.Suffix__c) && String.isBlank(spouseName.Suffix__c))) {
            if (isSpousePrimary && !isContactPrimary) {
                jointAddContact = spouseName.First_Name__c + ' and ' + contactName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointAddSpouse = spouseName.First_Name__c + ' and ' + contactName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointSalContact = spouseSal + ' and ' + contactSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }
            else if (isContactPrimary && !isSpousePrimary) {
                jointAddContact = contactName.First_Name__c + ' and ' + spouseName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointAddSpouse = contactName.First_Name__c + ' and ' + spouseName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = contactSal + ' and ' + spouseSal;
            }
            else {
                jointAddContact = contactName.First_Name__c + ' and ' + spouseName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointAddSpouse = spouseName.First_Name__c + ' and ' + contactName.First_Name__c + ' ' + contactName.Last_Name__c;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }
        //Case: Has a professional designation or last name IS NOT the same
        //Here we separate the salutation into two lines.
        } else if (!String.isBlank(contactName.Suffix__c) || !String.isBlank(spouseName.Suffix__c) || contactName.last_name__c != spouseName.last_name__c) {
            if (isSpousePrimary && !isContactPrimary) {
                jointAddContact = spouseAdd;
                jointAddContactLine2 = contactAdd;
                jointAddSpouse = spouseAdd;
                jointAddSpouseLine2 = contactAdd;
                jointSalContact = spouseSal + ' and ' + contactSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }
            else if (isContactPrimary && !isSpousePrimary) {
                jointAddContact = contactAdd;
                jointAddContactLine2 = spouseAdd;
                jointAddSpouse = contactAdd;
                jointAddSpouseLine2 = spouseAdd;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = contactSal + ' and ' + spouseSal;
            }
            else {
                jointAddContact = contactAdd;
                jointAddContactLine2 = spouseAdd;
                jointAddSpouse = spouseAdd;
                jointAddSpouseLine2 = contactAdd;
                jointSalContact = contactSal + ' and ' + spouseSal;
                jointSalSpouse = spouseSal + ' and ' + contactSal;
            }

        // Same last name, with prefix, no professional designation
        } else if (contactName.last_name__c == spouseName.last_name__c) {
            String doctorOrProfessorPlural = '';

            if (isSpousePrimary && !isContactPrimary) {

                if (spousePrefix == 'Mrs.' && !String.isBlank(contactPrefix)) {
                    jointAddContact = 'Mrs. ' + spouseName.first_name__c + ' ' + spouseName.last_name__c + ' and ' + contactPrefix + ' ' + contactName.first_name__c + ' ' + contactName.last_name__c;
                    jointAddSpouse = jointAddContact;
                    jointSalContact = 'Mrs. ' + spouseName.last_name__c + ' and ' +  contactPrefix + ' ' + contactName.last_name__c;
                    jointSalSpouse = jointSalContact;
                } else if (contactPrefix == 'Mrs.' && !String.isBlank(spousePrefix)) {
                    jointAddContact = spousePrefix + ' and Mrs. ' + spouseName.first_name__c + ' ' + spouseName.last_name__c;
                    jointAddSpouse = jointAddContact;
                    jointSalContact = spousePrefix + ' and Mrs. ' + spouseName.last_name__c;
                    jointSalSpouse = jointSalContact;
                } else {
                    jointAddContact = spouseAdd + ' and ' + contactAdd;
                    jointAddSpouse = spouseAdd + ' and ' + contactAdd;
                    jointSalContact = spouseSal + ' and ' + contactSal;
                    jointSalSpouse = spouseSal + ' and ' + contactSal;
                }
            } else if (isContactPrimary && !isSpousePrimary) {
                if (spousePrefix == 'Mrs.' && !String.isBlank(contactPrefix)) {
                    jointAddContact = contactPrefix + ' and Mrs. ' + contactName.first_name__c + ' ' + contactName.last_name__c;
                    jointAddSpouse = jointAddContact;
                    jointSalContact = contactPrefix + ' and Mrs. ' + contactName.last_name__c;
                    jointSalSpouse = jointSalContact;
                } else if (contactPrefix == 'Mrs.' && !String.isBlank(spousePrefix)) {
                    jointAddContact = 'Mrs. ' + contactName.first_name__c + ' ' + contactName.last_name__c + ' and ' + spousePrefix + ' ' + spouseName.first_name__c + ' ' + spouseName.last_name__c;
                    jointAddSpouse = jointAddContact;
                    jointSalContact = 'Mrs. ' + contactName.last_name__c + ' and ' +  spousePrefix + ' ' + spouseName.last_name__c;
                    jointSalSpouse = jointSalContact;
                } else {
                    jointAddContact = contactAdd + ' and ' + spouseAdd;
                    jointAddSpouse = contactAdd + ' and ' + spouseAdd;
                    jointSalContact = contactSal + ' and ' + spouseSal;
                    jointSalSpouse = contactSal + ' and ' + spouseSal;
                }
            } else {
                if (spousePrefix == 'Mrs.' && !String.isBlank(contactPrefix)) {
                    jointAddContact = contactPrefix + ' and Mrs. ' + contactName.first_name__c + ' ' + contactName.last_name__c;
                    jointAddSpouse = 'Mrs. ' + spouseName.first_name__c + ' ' + spouseName.last_name__c + ' and '  + contactPrefix + ' ' + contactName.first_name__c + ' ' + contactName.last_name__c;
                    jointSalContact = contactPrefix + ' and Mrs. ' + contactName.last_name__c;
                    jointSalSpouse = 'Mrs. ' + spouseName.last_name__c + ' and ' +  contactPrefix + ' ' + contactName.last_name__c;
                } else if (contactPrefix == 'Mrs.' && !String.isBlank(spousePrefix)) {
                    jointAddContact = 'Mrs. ' + contactName.first_name__c + ' ' + contactName.last_name__c + ' and '  + spousePrefix + ' ' + spouseName.first_name__c + ' ' + spouseName.last_name__c;
                    jointAddSpouse = spousePrefix + ' and Mrs. ' + spouseName.first_name__c + ' ' + spouseName.last_name__c;
                    jointSalContact = 'Mrs. ' + contactName.last_name__c + ' and ' +  spousePrefix + ' ' + spouseName.last_name__c;
                    jointSalSpouse = spousePrefix + ' and Mrs. ' + spouseName.last_name__c;
                } else {
                    jointAddContact = contactAdd + ' and ' + spouseAdd;
                    jointAddSpouse = spouseAdd + ' and ' + contactAdd;
                    jointSalContact = contactSal + ' and ' + spouseSal;
                    jointSalSpouse = spouseSal + ' and ' + contactSal;
                }
            }
        }


    	List<Ucinn_ascendv2__Salutation__c> newSalutations = new List<Ucinn_ascendv2__Salutation__c>();

        newSalutations.add(
        	new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = FORMAL,
        										RecordTypeId = salutationRecordTypeMap.get(JOINT),
        										Ucinn_ascendv2__Contact__c = contactName.Contact__c,
        										Ucinn_ascendv2__Contact_2__c = spouseName.Contact__c,
        										Ucinn_ascendv2__Inside_Salutation__c = jointSalContact.normalizeSpace(),
        										Ucinn_ascendv2__Salutation_Author__c = 'Standard',
        										Ucinn_ascendv2__Addressee_Line_1__c = correctSpacingBeforeComma(jointAddContact.normalizeSpace()),
        										Ucinn_ascendv2__Addressee_Line_2__c = correctSpacingBeforeComma(jointAddContactLine2.normalizeSpace())
        ));

        newSalutations.add(
        	new Ucinn_ascendv2__Salutation__c(	Ucinn_ascendv2__Salutation_Type__c = FORMAL,
        										RecordTypeId = salutationRecordTypeMap.get(JOINT),
        										Ucinn_ascendv2__Contact__c = spouseName.Contact__c,
        										Ucinn_ascendv2__Contact_2__c = contactName.Contact__c,
        										Ucinn_ascendv2__Inside_Salutation__c = jointSalSpouse.normalizeSpace(),
        										Ucinn_ascendv2__Salutation_Author__c = 'Standard',
        	        							Ucinn_ascendv2__Addressee_Line_1__c = correctSpacingBeforeComma(jointAddSpouse.normalizeSpace()),
        										Ucinn_ascendv2__Addressee_Line_2__c = correctSpacingBeforeComma(jointAddSpouseLine2.normalizeSpace())
        ));

        return newSalutations;
    }

    private String correctSpacingBeforeComma(String addresseeString) {
        return addresseeString.replace(' ,', ',');
    }
}