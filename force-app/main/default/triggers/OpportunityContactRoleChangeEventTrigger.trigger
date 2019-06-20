trigger OpportunityContactRoleChangeEventTrigger on OpportunityContactRoleChangeEvent (after insert) {
    Map<Id, Shadow_Opportunity_Contact_Role__c> createUpdateMap = new Map<Id, Shadow_Opportunity_Contact_Role__c>();
    Set<Id> deleteIds = new Set<Id>();

    for (OpportunityContactRoleChangeEvent evt : Trigger.new) {
        // For each change event, mirror updates to our shadow table.
        // 
    	System.debug(JSON.serialize(evt));
		System.debug(evt.ChangeEventHeader.getChangeType());
        switch on (evt.ChangeEventHeader.getChangeType()) {
            when 'CREATE' {
                // This is guaranteed to be the first event for this record in this transaction.
                // Add all records to the createUpdateMap.
                for (Id recordId : evt.ChangeEventHeader.getRecordIds()) {
                    Shadow_Opportunity_Contact_Role__c shadowOCR = new Shadow_Opportunity_Contact_Role__c(
                        Opportunity_Contact_Role_Id__c = recordId,
                        Opportunity__c = evt.OpportunityId,
                        Role__c = evt.Role,
                        Contact__c = evt.ContactId
                    );
                    createUpdateMap.put(recordId, shadowOCR);
                }
            }
            when 'UPDATE' {
                // If we're creating this record in this transaction, update the create record.
                // Otherwise, add an update record.
                for (Id recordId : evt.ChangeEventHeader.getRecordIds()) {
                    Shadow_Opportunity_Contact_Role__c shadowOCR;

                    if (!createUpdateMap.containsKey(recordId)) {
                        createUpdateMap.put(
                            recordId, 
                            new Shadow_Opportunity_Contact_Role__c(
                                Opportunity_Contact_Role_Id__c = recordId
                            )
                        );
                    }

                    shadowOCR = createUpdateMap.get(recordId);
                    
                    if (evt.Role != null) shadowOCR.Role__c = evt.Role;
                    if (evt.ContactId != null) shadowOCR.Contact__c = evt.ContactId;
                    // OpportunityContactRole is reparentable for Contact, but not Opportunity

                    if (evt.ChangeEventHeader.getNulledFields().contains('Role')) {
                        // Fields other than Role can't be nulled.
                        shadowOCR.Role__c = null;
                    }
                }
            }
            when 'DELETE' {
                // Mark our corresponding shadow records for deletion.
                List<String> deletes = evt.ChangeEventHeader.getRecordIds();
                for (Id thisId : deletes) {
                    deleteIds.add(thisId);
                    // Remove it from our map.
                    createUpdateMap.remove(thisId);
                }
            }
            // OpportunityContactRole does not support undelete.
        }
    }

    upsert createUpdateMap.values() Opportunity_Contact_Role_Id__c;
    delete [
        SELECT Id
        FROM Shadow_Opportunity_Contact_Role__c
        WHERE Opportunity_Contact_Role_Id__c IN :deleteIds
    ];
}