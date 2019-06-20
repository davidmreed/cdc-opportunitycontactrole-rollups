trigger OpportunityContactRoleChangeEventTrigger on OpportunityContactRoleChangeEvent (after insert) {
    Map<Id, Shadow_Opportunity_Contact_Role__c> updateMap = new Map<Id, Shadow_Opportunity_Contact_Role__c>();
    Map<Id, Shadow_Opportunity_Contact_Role__c> createMap = new Map<Id, Shadow_Opportunity_Contact_Role__c>();
    Set<Id> deleteIds = new Set<Id>();

    for (OpportunityContactRoleChangeEvent evt : Trigger.new) {
        // For each change event, mirror updates to our shadow table.

        switch on (evt.ChangeEventHeader.getChangeType()) {
            when 'CREATE' {
                // This is guaranteed to be the first event for this record in this transaction.
                // Add all records to the createMap.
                for (Id recordId : evt.ChangeEventHeader.getRecordIds()) {
                    Shadow_Opportunity_Contact_Role__c shadowOCR = new Shadow_Opportunity_Contact_Role__c(
                        Opportunity_Contact_Role_Id__c = recordId,
                        Opportunity__c = evt.OpportunityId,
                        Role__c = evt.Role,
                        Contact__c = evt.ContactId
                    );
                    createMap.put(recordId, shadowOCR);
                }
            }
            when 'UPDATE' {
                // If we're creating this record in this transaction, update the create record.
                // Otherwise, add an update record.
                for (Id recordId : evt.ChangeEventHeader.getRecordIds()) {
                    Shadow_Opportunity_Contact_Role__c shadowOCR;

                    if (createMap.containsKey(recordId)) {
                        shadowOCR = createMap.get(recordId);
                    } else {
                        shadowOCR = new Shadow_Opportunity_Contact_Role__c(
                            Opportunity_Contact_Role_Id__c = recordId
                        );
                        updateMap.put(recordId, shadowOCR);
                    }
                    
                    if (evt.Role != null) shadowOCR.Role__c = evt.Role;
                    if (evt.ContactId != null) shadowOCR.Contact__c = evt.ContactId;
                    if (evt.OpportunityId != null) shadowOCR.Opportunity__c = evt.OpportunityId;

                    for (String s: evt.ChangeEventHeader.getNulledFields()) {
                        switch on (s) {
                            when 'Role' {
                                shadowOCR.Role__c = null;
                            }
                            when 'ContactId' {
                                shadowOCR.Contact__c = null;
                            }
                            when 'OpportunityId' {
                                shadowOCR.Opportunity__c = null;
                            }
                        }
                    }
                }
            }
            when 'DELETE' {
                // Mark our corresponding shadow records for deletion.
                List<String> deletes = evt.ChangeEventHeader.getRecordIds();

                // If we have any other events for these records, remove those shadow updates.
                for (Id thisId : deletes) {
                    deleteIds.add(thisId);
                    if (createMap.containsKey(thisId)) createMap.remove(thisId);
                    if (updateMap.containsKey(thisId)) updateMap.remove(thisId);
                }
            }
            when 'UNDELETE' {
                // Treat like a create?
            }
        }
         
    }

    insert createMap.values();
    upsert updateMap.values() Opportunity_Contact_Role_Id__c;
    delete [
        SELECT Id
        FROM Shadow_Opportunity_Contact_Role__c
        WHERE Opportunity_Contact_Role_Id__c IN :deleteIds
    ];
}