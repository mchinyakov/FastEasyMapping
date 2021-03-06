// For License please refer to LICENSE file in the root of FastEasyMapping project

#import "FEMSerializer.h"
#import "FEMAttributeMapping.h"
#import "FEMTypeIntrospection.h"
#import "FEMRelationshipMapping.h"

@implementation FEMSerializer

+ (NSDictionary *)_serializeObject:(id)object usingMapping:(FEMMapping *)mapping {
	NSMutableDictionary *representation = [NSMutableDictionary dictionary];

	for (FEMAttributeMapping *fieldMapping in mapping.attributeMappings) {
		[self setValueOnRepresentation:representation fromObject:object withFieldMapping:fieldMapping];
	}

	for (FEMRelationshipMapping *relationshipMapping in mapping.relationshipMappings) {
		[self setRelationshipObjectOn:representation usingMapping:relationshipMapping fromObject:object];
	}

	return representation;
}

+ (NSDictionary *)serializeObject:(id)object usingMapping:(FEMMapping *)mapping {
	NSDictionary *representation = [self _serializeObject:object usingMapping:mapping];

	return mapping.rootPath.length > 0 ? @{mapping.rootPath : representation} : representation;
}

+ (id)_serializeCollection:(NSArray *)collection usingMapping:(FEMMapping *)mapping {
	NSMutableArray *representation = [NSMutableArray new];

	for (id object in collection) {
		NSDictionary *objectRepresentation = [self _serializeObject:object usingMapping:mapping];
		[representation addObject:objectRepresentation];
	}

	return representation;
}

+ (id)serializeCollection:(NSArray *)collection usingMapping:(FEMMapping *)mapping {
	NSArray *representation = [self _serializeCollection:collection usingMapping:mapping];

	return mapping.rootPath.length > 0 ? @{mapping.rootPath: representation} : representation;
}

+ (void)setValueOnRepresentation:(NSMutableDictionary *)representation fromObject:(id)object withFieldMapping:(FEMAttributeMapping *)fieldMapping {
	id returnedValue = [object valueForKey:fieldMapping.property];
	if (returnedValue) {
		returnedValue = [fieldMapping reverseMapValue:returnedValue];

		[self setValue:returnedValue forKeyPath:fieldMapping.keyPath inRepresentation:representation];
	}
}

+ (void)setValue:(id)value forKeyPath:(NSString *)keyPath inRepresentation:(NSMutableDictionary *)representation {
	NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
	if ([keyPathComponents count] == 1) {
		[representation setObject:value forKey:keyPath];
	} else if ([keyPathComponents count] > 1) {
		NSString *attributeKey = [keyPathComponents lastObject];
		NSMutableArray *subPaths = [NSMutableArray arrayWithArray:keyPathComponents];
		[subPaths removeLastObject];

		id currentPath = representation;
		for (NSString *key in subPaths) {
			id subPath = [currentPath valueForKey:key];
			if (subPath == nil) {
				subPath = [NSMutableDictionary new];
				[currentPath setValue:subPath forKey:key];
			}
			currentPath = subPath;
		}
		[currentPath setValue:value forKey:attributeKey];
	}
}

+ (void)setRelationshipObjectOn:(NSMutableDictionary *)representation
                   usingMapping:(FEMRelationshipMapping *)relationshipMapping
			         fromObject:(id)object {
	id value = [object valueForKey:relationshipMapping.property];
	if (value) {
		id relationshipRepresentation = nil;
		if (relationshipMapping.isToMany) {
			relationshipRepresentation = [self _serializeCollection:value usingMapping:relationshipMapping.objectMapping];
		} else {
			relationshipRepresentation = [self _serializeObject:value usingMapping:relationshipMapping.objectMapping];
		}

		if (relationshipMapping.keyPath.length > 0) {
			[representation setObject:relationshipRepresentation forKey:relationshipMapping.keyPath];
		} else {
			NSParameterAssert([relationshipRepresentation isKindOfClass:NSDictionary.class]);
			[representation addEntriesFromDictionary:relationshipRepresentation];
		}
	}
}

@end