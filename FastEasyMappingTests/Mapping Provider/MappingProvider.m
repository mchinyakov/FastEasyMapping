// For License please refer to LICENSE file in the root of FastEasyMapping project

#import "MappingProvider.h"
#import "Car.h"
#import "Phone.h"
#import "Person.h"
#import "FEMObjectMapping.h"
#import "FEMManagedObjectMapping.h"
#import "FEMAttributeMapping.h"
#import "FEMRelationshipMapping.h"

@implementation MappingProvider

+ (FEMManagedObjectMapping *)carMappingWithPrimaryKey {
	FEMManagedObjectMapping *mapping = [self carMapping];
	[mapping setPrimaryKey:@"carID"];
	[mapping addAttributeMappingDictionary:@{@"carID" : @"id"}];

	return mapping;
}

+ (FEMManagedObjectMapping *)carMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Car" configuration:^(FEMManagedObjectMapping *mapping) {
		[mapping addAttributeMappingFromArray:@[@"model", @"year"]];
	}];
}

+ (FEMManagedObjectMapping *)carWithRootKeyMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Car"
	                                            rootPath:@"car"
			                               configuration:^(FEMManagedObjectMapping *mapping) {
//       [mapping setPrimaryKey:@"carID"];
				                               [mapping addAttributeMappingDictionary:@{@"carID" : @"id"}];
				                               [mapping addAttributeMappingFromArray:@[@"model", @"year"]];
			                               }];
}

+ (FEMManagedObjectMapping *)carNestedAttributesMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Car" configuration:^(FEMManagedObjectMapping *mapping) {
//		[mapping setPrimaryKey:@"carID"];
		[mapping addAttributeMappingDictionary:@{@"carID" : @"id", @"year" : @"information.year"}];
		[mapping addAttributeMappingFromArray:@[@"model"]];
	}];
}

+ (FEMManagedObjectMapping *)carWithDateMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Car" configuration:^(FEMManagedObjectMapping *mapping) {
//		[mapping setPrimaryKey:@"carID"];
		[mapping addAttributeMappingDictionary:@{@"carID" : @"id"}];
		[mapping addAttributeMappingFromArray:@[@"model", @"year"]];
		[mapping addAttributeMapping:[FEMAttributeMapping mappingOfProperty:@"createdAt"
                                                                  toKeyPath:@"created_at"
                                                                 dateFormat:@"yyyy-MM-dd"]];
	}];
}

+ (FEMManagedObjectMapping *)phoneMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Phone" configuration:^(FEMManagedObjectMapping *mapping) {
//		[mapping setPrimaryKey:@"phoneID"];
		[mapping addAttributeMappingDictionary:@{@"phoneID" : @"id"}];
		[mapping addAttributeMappingFromArray:@[@"number", @"ddd", @"ddi"]];
	}];
}

+ (FEMManagedObjectMapping *)personMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Person" configuration:^(FEMManagedObjectMapping *mapping) {
//		[mapping setPrimaryKey:@"personID"];
		[mapping addAttributeMappingDictionary:@{@"personID" : @"id"}];
		[mapping addAttributeMappingFromArray:@[@"name", @"email", @"gender"]];
		[mapping addRelationshipMapping:[FEMRelationshipMapping mappingOfProperty:@"car"
		                                                            configuration:^(FEMRelationshipMapping *relationshipMapping) {
            [relationshipMapping setObjectMapping:[self carMapping]
                                       forKeyPath:@"car"];
        }]];

		[mapping addRelationshipMapping:[FEMRelationshipMapping mappingOfProperty:@"phones"
		                                                            configuration:^(FEMRelationshipMapping *relationshipMapping) {
            [relationshipMapping setToMany:YES];
            [relationshipMapping setObjectMapping:[self phoneMapping] forKeyPath:@"phones"];
        }]];
	}];
}

+ (FEMManagedObjectMapping *)personWithPhoneMapping {
    return [FEMManagedObjectMapping mappingForEntityName:@"Person" configuration:^(FEMManagedObjectMapping *mapping) {
		[mapping setPrimaryKey:@"personID"];
        [mapping addAttributeMappingDictionary:@{@"personID" : @"id"}];
        [mapping addAttributeMappingFromArray:@[@"name", @"email", @"gender"]];

        [mapping addRelationshipMapping:[FEMRelationshipMapping mappingOfProperty:@"phones"
                                                                    configuration:^(FEMRelationshipMapping *relationshipMapping) {
            FEMManagedObjectMapping *phoneMapping = [self phoneMapping];
            [phoneMapping setPrimaryKey:@"phoneID"];

            [relationshipMapping setToMany:YES];
            [relationshipMapping setObjectMapping:phoneMapping forKeyPath:@"phones"];
        }]];
    }];
}

+ (FEMManagedObjectMapping *)personWithCarMapping {
	return [FEMManagedObjectMapping mappingForEntityName:@"Person" configuration:^(FEMManagedObjectMapping *mapping) {
		[mapping setPrimaryKey:@"personID"];
		[mapping addAttributeMappingDictionary:@{@"personID" : @"id"}];
		[mapping addAttributeMappingFromArray:@[@"name", @"email"]];
		[mapping addRelationshipMapping:[FEMRelationshipMapping mappingOfProperty:@"car"
		                                                            configuration:^(FEMRelationshipMapping *relationshipMapping) {
            [relationshipMapping setObjectMapping:[self carMappingWithPrimaryKey] forKeyPath:@"car"];
        }]];
	}];
}

@end
