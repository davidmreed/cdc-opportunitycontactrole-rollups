@isTest
private without sharing class OpportunityContactRoleChangeEvent_TEST {
    @testSetup
    private static void testSetup() {
        Account a = new Account(Name = 'Test');
        insert a;

        Contact c = new Contact(LastName = 'Test1', AccountId = a.Id);
        Contact c2 = new Contact(LastName = 'Test2', AccountId = a.Id);
        insert c;
        insert c2;

        Opportunity o = new Opportunity(Name = 'Test', AccountId = a.Id, StageName = 'New', CloseDate = Date.today());
        insert o;

        
        Test.enableChangeDataCapture();
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = o.Id,
            ContactId = c.Id,
            Role = 'Base'
        );
        insert ocr;
        Test.getEventBus().deliver();
    }

    @isTest
    private static void testAddOCRCreatesShadow() {
        Opportunity o = [SELECT Id FROM Opportunity];
        Contact c1 = [SELECT Id FROM Contact WHERE LastName = 'Test1'];
        Contact c2 = [SELECT Id FROM Contact WHERE LastName = 'Test2'];

        Test.enableChangeDataCapture();
        Test.startTest();

        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = o.Id,
                ContactId = c1.Id,
                Role = 'Test1'
            ),
            new OpportunityContactRole(
                OpportunityId = o.Id,
                ContactId = c2.Id,
                Role = 'Test2'
            )
        };
        Test.stopTest();

        System.assertEquals(3, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');
        System.assertEquals(1, [SELECT count() 
                                FROM Shadow_Opportunity_Contact_Role__c 
                                WHERE Opportunity__c = :o.Id AND Contact__c = :c1.Id AND Role__c = 'Test1'], 'first OCR');
        System.assertEquals(1, [SELECT count() 
                                FROM Shadow_Opportunity_Contact_Role__c 
                                WHERE Opportunity__c = :o.Id AND Contact__c = :c2.Id AND Role__c = 'Test2'], 'second OCR');
    }

    @isTest
    private static void testUpdateOCRUpdatesShadow() {
        Test.enableChangeDataCapture();
        System.assertEquals(1, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');

        Test.startTest();
        OpportunityContactRole ocr = [SELECT Id FROM OpportunityContactRole];
        ocr.Role = null;
        update ocr;
        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c WHERE Role__c = null], 'total count');
    }

    @isTest
    private static void testCreateUpdateOCRUpdatesShadow() {
        Opportunity o = [SELECT Id FROM Opportunity];
        Contact c1 = [SELECT Id FROM Contact WHERE LastName = 'Test1'];
        Contact c2 = [SELECT Id FROM Contact WHERE LastName = 'Test2'];

        Test.enableChangeDataCapture();
        Test.startTest();

        OpportunityContactRole ocr = [SELECT Id FROM OpportunityContactRole];
        ocr.Role = 'Base2';
        ocr.ContactId = c2.Id;
        update ocr;
        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');
        System.assertEquals(1, [SELECT count() 
                                FROM Shadow_Opportunity_Contact_Role__c 
                                WHERE Opportunity__c = :o.Id AND Contact__c = :c2.Id AND Role__c = 'Base2'], 'first OCR');
    }

    @isTest
    private static void testDeleteOCRDeletesShadow() {
        Test.enableChangeDataCapture();
        System.assertEquals(1, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');

        Test.startTest();
        delete [SELECT Id FROM OpportunityContactRole];
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');
    }

    @isTest
    private static void testCreateUpdateDeleteOCRDeletesShadow() {
        Opportunity o = [SELECT Id FROM Opportunity];
        Contact c1 = [SELECT Id FROM Contact WHERE LastName = 'Test1'];
        Contact c2 = [SELECT Id FROM Contact WHERE LastName = 'Test2'];

        Test.enableChangeDataCapture();
        Test.startTest();

        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = o.Id,
                ContactId = c1.Id,
                Role = 'Test1'
            ),
            new OpportunityContactRole(
                OpportunityId = o.Id,
                ContactId = c2.Id,
                Role = 'Test2'
            )
        };
        insert ocrs;
        ocrs[0].Role = 'Test3';
        ocrs[1].Role = 'Test4';
        update ocrs;
        delete ocrs;

        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM Shadow_Opportunity_Contact_Role__c], 'total count');
        System.assertEquals(0, [SELECT count() 
                                FROM Shadow_Opportunity_Contact_Role__c 
                                WHERE Opportunity__c = :o.Id AND Contact__c = :c1.Id AND Role__c != 'Base'], 'first OCR');
        System.assertEquals(0, [SELECT count() 
                                FROM Shadow_Opportunity_Contact_Role__c 
                                WHERE Opportunity__c = :o.Id AND Contact__c = :c2.Id], 'second OCR');
    }
}