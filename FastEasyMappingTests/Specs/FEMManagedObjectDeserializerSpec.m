// For License please refer to LICENSE file in the root of FastEasyMapping project

#import <Kiwi/Kiwi.h>
#import <CMFactory/CMFixture.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>

#import "MappingProvider.h"
#import "Person.h"
#import "Car.h"
#import "FEMManagedObjectDeserializer.h"
#import "FEMRelationshipMapping.h"
#import "FEMMapping.h"
#import "FEMManagedObjectMapping.h"
#import "Phone.h"

SPEC_BEGIN(FEMManagedObjectDeserializerSpec)

describe(@"FEMManagedObjectDeserializer", ^{
    __block NSManagedObjectContext *moc;

    beforeEach(^{
        [MagicalRecord setDefaultModelFromClass:[self class]];
        [MagicalRecord setupCoreDataStackWithInMemoryStore];

        moc = [NSManagedObjectContext MR_defaultContext];
    });

    afterEach(^{
        moc = nil;

        [MagicalRecord cleanUp];
    });

    describe(@".objectFromExternalRepresentation:usingMapping:", ^{

        context(@"a simple object", ^{

            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                externalRepresentation = [CMFixture buildUsingFixture:@"Car"];
                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carMapping]
                                                                                    context:moc];
            });

            specify(^{
                [car shouldNotBeNil];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:[externalRepresentation objectForKey:@"year"]];
            });

        });

        context(@"with existing object", ^{
            __block Car *oldCar;
            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                oldCar = [NSEntityDescription insertNewObjectForEntityForName:@"Car" inManagedObjectContext:moc];
                oldCar.carID = @(1);
                oldCar.year = @"1980";
                oldCar.model = @"";
                [moc MR_saveToPersistentStoreAndWait];

                externalRepresentation = @{
                        @"id" : @(1),
                        @"model" : @"i30",
                        @"year" : @"2013"
                };

                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carMappingWithPrimaryKey]
                                                                                    context:moc];
            });

            specify(^{
                [car shouldNotBeNil];
            });

            specify(^{
                [[car should] equal:oldCar];
            });

            specify(^{
                [[car.carID should] equal:oldCar.carID];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:[externalRepresentation objectForKey:@"year"]];
            });

            specify(^{
                [[[Car MR_findAll] should] haveCountOf:1];
            });
        });

        context(@"don't clear missing values", ^{
            __block Car *oldCar;
            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                oldCar = [NSEntityDescription insertNewObjectForEntityForName:@"Car" inManagedObjectContext:moc];
                oldCar.carID = @(1);
                oldCar.year = @"1980";
                oldCar.model = @"";

                externalRepresentation = @{@"id" : @(1), @"model" : @"i30",};
                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carMappingWithPrimaryKey]
                                                                                    context:moc];
            });

            specify(^{
                [[car.carID should] equal:oldCar.carID];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:oldCar.year];
            });

            specify(^{
                [[[Car MR_findAll] should] haveCountOf:1];
            });

        });

        context(@"with root key", ^{
            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                externalRepresentation = [CMFixture buildUsingFixture:@"CarWithRoot"];
                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carWithRootKeyMapping]
                                                                                    context:moc];
                externalRepresentation = [externalRepresentation objectForKey:@"car"];
            });

            specify(^{
                [car shouldNotBeNil];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:[externalRepresentation objectForKey:@"year"]];
            });

        });

        context(@"with nested information", ^{
            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                externalRepresentation = [CMFixture buildUsingFixture:@"CarWithNestedAttributes"];
                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carNestedAttributesMapping]
                                                                                    context:moc];
            });

            specify(^{
                [car shouldNotBeNil];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:[[externalRepresentation objectForKey:@"information"] objectForKey:@"year"]];
            });

        });

        context(@"with dateformat", ^{
            __block Car *car;
            __block NSDictionary *externalRepresentation;

            beforeEach(^{
                moc = [NSManagedObjectContext MR_defaultContext];
                externalRepresentation = [CMFixture buildUsingFixture:@"CarWithDate"];
                car = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                               usingMapping:[MappingProvider carWithDateMapping]
                                                                                    context:moc];
            });

            specify(^{
                [car shouldNotBeNil];
            });

            specify(^{
                [[car.model should] equal:[externalRepresentation objectForKey:@"model"]];
            });

            specify(^{
                [[car.year should] equal:[externalRepresentation objectForKey:@"year"]];
            });

            it(@"should populate createdAt property with a NSDate", ^{

                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                format.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
                format.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                format.dateFormat = @"yyyy-MM-dd";
                NSDate *expectedDate = [format dateFromString:[externalRepresentation objectForKey:@"created_at"]];
                [[car.createdAt should] equal:expectedDate];

            });

        });

        context(@"with hasOne objectMapping", ^{
            __block Person *person;
            __block Car *expectedCar;

            beforeEach(^{
                expectedCar = [Car MR_createEntity];
                expectedCar.model = @"i30";
                expectedCar.year = @"2013";

                NSDictionary *externalRepresentation = [CMFixture buildUsingFixture:@"Person"];
                person = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                                  usingMapping:[MappingProvider personMapping]
                                                                                       context:moc];
            });

            specify(^{
                [person.car shouldNotBeNil];
            });

            specify(^{
                [[person.car.model should] equal:expectedCar.model];
            });

            specify(^{
                [[person.car.year should] equal:expectedCar.year];
            });

        });

        context(@"with hasMany objectMapping", ^{
            __block Person *person;

            beforeEach(^{
                moc = [NSManagedObjectContext MR_defaultContext];
                NSDictionary *externalRepresentation = [CMFixture buildUsingFixture:@"Person"];
                person = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation
                                                                                  usingMapping:[MappingProvider personMapping]
                                                                                       context:moc];
            });

            specify(^{
                [person.phones shouldNotBeNil];
            });

            specify(^{
                [[person.phones should] haveCountOf:2];
            });

        });

    });

    describe(@".deserializeCollectionExternalRepresentation:usingMapping:", ^{
        __block NSArray *carsArray;
        __block NSArray *externalRepresentation;

        beforeEach(^{
            externalRepresentation = [CMFixture buildUsingFixture:@"Cars"];
            carsArray = [FEMManagedObjectDeserializer deserializeCollectionExternalRepresentation:externalRepresentation
                                                                                     usingMapping:[MappingProvider carMapping]
                                                                                          context:moc];
        });

        specify(^{
            [carsArray shouldNotBeNil];
        });

        specify(^{
            [[carsArray should] haveCountOf:[externalRepresentation count]];
        });

    });

    describe(@"null relationship", ^{
        __block Person *person = nil;

        beforeAll(^{
            NSDictionary *externalRepresentation = [CMFixture buildUsingFixture:@"PersonWithMissingRelationships"];
            FEMManagedObjectMapping *mapping = [MappingProvider personMapping];
            person = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation usingMapping:mapping context:moc];
        });
        
        context(@"to-one", ^{
            it(@"it should be nil", ^{
                [[person.car should] beNil];
            });
        });

        context(@"to-many", ^{
            it(@"it should be empty", ^{
                [[person.phones should] beNil];
            });
        });
    });

    describe(@"relationship assignment policy", ^{
        __block NSDictionary *externalRepresentation_v1 = nil;
        __block NSDictionary *externalRepresentation_v2 = nil;
        __block FEMManagedObjectMapping *mapping = nil;
        __block FEMRelationshipMapping *relationshipMapping = nil;
        
        context(@"to-one", ^{
            beforeEach(^{
                externalRepresentation_v1 = [CMFixture buildUsingFixture:@"PersonWithCar_1"];
                externalRepresentation_v2 = [CMFixture buildUsingFixture:@"PersonWithCar_2"];
                mapping = [MappingProvider personWithCarMapping];
                relationshipMapping = [mapping relationshipMappingForProperty:@"car"];
            });
            
            afterEach(^{
                externalRepresentation_v1 = nil;
                externalRepresentation_v2 = nil;
                mapping = nil;
                relationshipMapping = nil;
            });
            
            context(@"assign", ^{
                it(@"should assign new value", ^{
                    relationshipMapping.assignmentPolicy = FEMAssignmentPolicyAssign;
                    
                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] beZero];
                    Person *person_v1 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v1
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];
                    
                    Car *car_v1 = person_v1.car;
                    [[car_v1 should] equal:[Car MR_findFirstInContext:moc]];
                    
                    Person *person_v2 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v2
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    
                    [[person_v1 should] equal:person_v2];
                    Car *car_v2 = person_v1.car;
                    
                    [[car_v1 shouldNot] equal:car_v2];
                    [[car_v1.person should] beNil];
                });
            });
            
            context(@"merge", ^{
                it(@"should act as assign", ^{
                    relationshipMapping.assignmentPolicy = FEMAssignmentPolicyObjectMerge;
                    
                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] beZero];
                    Person *person_v1 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v1
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];
                    
                    Car *car_v1 = person_v1.car;
                    [[car_v1 should] equal:[Car MR_findFirstInContext:moc]];
                    
                    Person *person_v2 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v2
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[person_v1 should] equal:person_v2];
                    Car *car_v2 = person_v1.car;
                    
                    [[car_v1 shouldNot] equal:car_v2];
                    [[car_v1.person should] beNil];
                });
            });

            context(@"replace", ^{
                it(@"should not replace equal object", ^{
                    relationshipMapping.assignmentPolicy = FEMAssignmentPolicyObjectReplace;

                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] beZero];
                    Person *person_v1 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v1
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    Car *car_v1 = person_v1.car;

                    [moc MR_saveToPersistentStoreAndWait];

                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];

                    [FEMManagedObjectDeserializer fillObject:person_v1
                                  fromExternalRepresentation:externalRepresentation_v1
                                                usingMapping:mapping];
                    [moc MR_saveToPersistentStoreAndWait];
                    [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];

                    [[person_v1.car should] equal:car_v1];
                });
            });
        });
        context(@"to-many", ^{
            beforeEach(^{
                externalRepresentation_v1 = [CMFixture buildUsingFixture:@"Person_1"];
                externalRepresentation_v2 = [CMFixture buildUsingFixture:@"Person_2"];
                mapping = [MappingProvider personWithPhoneMapping];
                relationshipMapping = [mapping relationshipMappingForProperty:@"phones"];
            });
            
            afterEach(^{
                externalRepresentation_v1 = nil;
                externalRepresentation_v2 = nil;
                mapping = nil;
                relationshipMapping = nil;
            });
            
            context(@"merge", ^{
                it(@"should merge existing and new objects", ^{
                    relationshipMapping.assignmentPolicy = FEMAssignmentPolicyCollectionMerge;
                    
                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] beZero];
                    Person *person_v1 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v1
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] equal:@2];
                    
                    NSSet *phones_1 = person_v1.phones;
                    [[@([phones_1 isEqualToSet:[NSSet setWithArray:[Phone MR_findAllInContext:moc]]]) should] beTrue];
                    
                    [FEMManagedObjectDeserializer fillObject:person_v1
                                  fromExternalRepresentation:externalRepresentation_v2
                                                usingMapping:mapping];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] equal:@3];

                    [[@([phones_1 isSubsetOfSet:person_v1.phones]) should] beTrue];
                });
            });
            
            context(@"replace", ^{
                it(@"should delete existing and assign new objects", ^{
                    relationshipMapping.assignmentPolicy = FEMAssignmentPolicyCollectionReplace;
                    
                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] beZero];
                    Person *person_v1 = [FEMManagedObjectDeserializer deserializeObjectExternalRepresentation:externalRepresentation_v1
                                                                                                 usingMapping:mapping
                                                                                                      context:moc];
                    [moc MR_saveToPersistentStoreAndWait];
                    
                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] equal:@2];
                    
                    NSSet *phones_1 = person_v1.phones;
                    [[@([phones_1 isEqualToSet:[NSSet setWithArray:[Phone MR_findAllInContext:moc]]]) should] beTrue];
                    
                    [FEMManagedObjectDeserializer fillObject:person_v1
                                  fromExternalRepresentation:externalRepresentation_v2
                                                usingMapping:mapping];
                    [moc MR_saveToPersistentStoreAndWait];

                    [[@([Phone MR_countOfEntitiesWithContext:moc]) should] equal:@2];
                });
            });
        });
    });

    describe(@"synchronization", ^{
        __block Car *car;
        __block NSDictionary *externalRepresentation;
        __block FEMManagedObjectMapping *mapping;

        beforeEach(^{
            externalRepresentation = @{
                @"id": @2,
                @"model": @"i30",
                @"year": @"2014"
            };

            car = [Car MR_createInContext:moc];
            [car setCarID:@1];

            mapping = [MappingProvider carMappingWithPrimaryKey];
        });

        context(@"without predicate", ^{
            it(@"should replace all existing objects", ^{
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];

                [FEMManagedObjectDeserializer synchronizeCollectionExternalRepresentation:@[externalRepresentation]
                                                                             usingMapping:mapping
                                                                                predicate:nil
                                                                                  context:moc];
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];
                Car *existingCar = [Car MR_findFirstInContext:moc];
                [[existingCar.carID should] equal:@2];
            });
        });

        context(@"with predicate", ^{
            it(@"should replace objects specified by predicate", ^{
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];

                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carID == 1"];
                [FEMManagedObjectDeserializer synchronizeCollectionExternalRepresentation:@[externalRepresentation]
                                                                             usingMapping:mapping
                                                                                predicate:predicate
                                                                                  context:moc];
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];
                Car *existingCar = [Car MR_findFirstInContext:moc];
                [[existingCar.carID should] equal:@2];
            });

            it(@"should not replace objects not specified by predicate", ^{
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@1];

                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"carID != 1"];
                [FEMManagedObjectDeserializer synchronizeCollectionExternalRepresentation:@[externalRepresentation]
                                                                             usingMapping:mapping
                                                                                predicate:predicate
                                                                                  context:moc];
                [[@([Car MR_countOfEntitiesWithContext:moc]) should] equal:@2];
            });
        });
    });
});

SPEC_END
