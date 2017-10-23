#import <objc/runtime.h>
#import <objc/message.h>

#import "lobjc.h"
#import "Value.h"
#import "Class.h"
#import "Object.h"
#import "Method.h"
#import "Selector.h"

#include "lemon.h"
#include "lkarg.h"
#include "lclass.h"
#include "larray.h"
#include "lstring.h"
#include "lnumber.h"
#include "linteger.h"
#include "linstance.h"

void *kLemonObjectKey;


static BOOL
lobjc_Class_respondsToSelector(struct lemon *lemon, struct lclass *clazz, id self, SEL selector)
{
	NSString *string;
	struct lobject *name;
	struct objc_super super = {
		.receiver = self,
		.super_class = class_getSuperclass([self class])
	};
	BOOL (*objc_msgSendSuper_stret_typed)(struct objc_super *, SEL, SEL) = (void *)&objc_msgSendSuper;
	if (objc_msgSendSuper_stret_typed(&super, @selector(respondsToSelector:), selector)) {
		return YES;
	}
	string = NSStringFromSelector(selector);
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];
	name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
	if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
		return YES;
	}

	return NO;
}

static id
lobjc_Class_methodSignatureForSelector(struct lemon *lemon, struct lclass *clazz, id self, SEL selector)
{
	NSString *string;
	struct lobject *name;
	struct objc_super super = {
		.receiver = self,
		.super_class = class_getSuperclass([self class])
	};
	id (*objc_msgSendSuper_stret_typed)(struct objc_super *, SEL, SEL) = (void *)&objc_msgSendSuper;

	id signature = objc_msgSendSuper_stret_typed(&super, @selector(methodSignatureForSelector:), selector);
	if (signature) {
		return signature;
	}

	string = NSStringFromSelector(selector);
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];
	name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));

	if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
		NSArray *components = [string componentsSeparatedByString:@"_"];
		int i;
		char type[256];
		int len;
		len = 0;
		type[len++] = '@';
		type[len++] = '@';
		type[len++] = ':';
		for (i = 0; i < components.count - 1; i++) {
			type[len++] = '@';
		}
		type[len++] = '\0';
		signature = [NSMethodSignature signatureWithObjCTypes:type];

		return signature;
	}

	return nil;
}

void
lobjc_Class_forwardInvocation(struct lemon *lemon, struct lclass *clazz, id self, NSInvocation *invocation)
{
	int i;
	int argc;
	const char *type;
	struct lobject *name;
	struct lobject *object;
	struct lobject *argv[256];
	NSString *string;
	NSException* exception;
	NSMethodSignature *signature;

	argc = 0;
	signature = [invocation methodSignature];
	for (i = 2; i < [signature numberOfArguments]; i++) {
		type = [signature getArgumentTypeAtIndex:i];
		object = NULL;
		if (strcmp(type, @encode(char)) == 0 ||
		    strcmp(type, @encode(int)) == 0 ||
		    strcmp(type, @encode(short)) == 0 ||
		    strcmp(type, @encode(long)) == 0 ||
		    strcmp(type, @encode(long long)) == 0)
		{
			long long value;

			[invocation getArgument:&value atIndex:i];

			object = linteger_create_from_long(lemon, value);
		} else if (strcmp(type, @encode(unsigned char)) == 0 ||
		           strcmp(type, @encode(unsigned int)) == 0 ||
		           strcmp(type, @encode(unsigned short)) == 0 ||
		           strcmp(type, @encode(unsigned long)) == 0 ||
		           strcmp(type, @encode(unsigned long long)) == 0)
		{
			unsigned long long value;

			[invocation getArgument:&value atIndex:i];

			object = linteger_create_from_long(lemon, value);
		} else if (strcmp(type, @encode(float)) == 0) {
			float value;
			char buffer[256];

			[invocation getArgument:&value atIndex:i];
			sprintf(buffer, "%g", value);

			object = lnumber_create_from_cstr(lemon, buffer);
		} else if (strcmp(type, @encode(double)) == 0) {
			double value;
			char buffer[256];

			[invocation getArgument:&value atIndex:i];
			sprintf(buffer, "%g", value);

			object = lnumber_create_from_cstr(lemon, buffer);
		} else if (strcmp(type, @encode(char *)) == 0) {
			char *value;

			[invocation getArgument:&value atIndex:i];

			object = lstring_create(lemon, value, strlen(value));
		} else if (strcmp(type, @encode(Class)) == 0) {
			Class value;

			[invocation getArgument:&value atIndex:i];

			object = lobjc_Class_create(lemon, value);
		} else if (strcmp(type, @encode(SEL)) == 0) {
			SEL value;

			[invocation getArgument:&value atIndex:i];

			object = lobjc_Selector_create(lemon, value);
		} else if (strcmp(type, @encode(id)) == 0) {
			id value;

			[invocation getArgument:&value atIndex:i];

			if ([value isKindOfClass:[NSNumber class]]) {
				object = lnumber_create_from_cstr(lemon, [[value stringValue] UTF8String]);
			} else if ([value isKindOfClass:[NSString class]]) {
				object = lstring_create(lemon, [value UTF8String], strlen([value UTF8String]));
			} else {
				object = lobjc_Object_create(lemon, value);
			}

		} else if (strcmp(type, @encode(CGRect)) == 0) {
			CGRect value;
			struct lobjc_Value *objc_Value;

			[invocation getArgument:&value atIndex:i];

			objc_Value = lobjc_Value_create(lemon, @encode(CGRect));
			objc_Value->u.rect = value;

			object = (struct lobject *)objc_Value;
		} else if (strcmp(type, @encode(CGSize)) == 0) {
			CGSize value;
			struct lobjc_Value *objc_Value;

			[invocation getArgument:&value atIndex:i];

			objc_Value = lobjc_Value_create(lemon, @encode(CGSize));
			objc_Value->u.size = value;

			object = (struct lobject *)objc_Value;
		} else if (strcmp(type, @encode(CGPoint)) == 0) {
			CGPoint value;
			struct lobjc_Value *objc_Value;

			[invocation getArgument:&value atIndex:i];

			objc_Value = lobjc_Value_create(lemon, @encode(CGPoint));
			objc_Value->u.point = value;

			object = (struct lobject *)objc_Value;
		} else if (strcmp(type, @encode(NSRange)) == 0) {
			NSRange value;
			struct lobjc_Value *objc_Value;

			[invocation getArgument:&value atIndex:i];

			objc_Value = lobjc_Value_create(lemon, @encode(NSRange));
			objc_Value->u.range = value;

			object = (struct lobject *)objc_Value;
		} else if (strncmp(type, "^", 1) == 0) {
			void *value;
			struct lobjc_Value *objc_Value;

			[invocation getArgument:&value atIndex:i];

			objc_Value = lobjc_Value_create(lemon, type);
			objc_Value->u.ptr = value;

			object = (struct lobject *)objc_Value;
		} else if (strcmp(type, @encode(void)) == 0) {
			object = lemon->l_nil;
		} else {
			exception = [NSException exceptionWithName:@"Argument" reason:@"argument type unsupported" userInfo:nil];

			@throw exception;
		}

		if (object == NULL) {
			exception = [NSException exceptionWithName:@"Argument" reason:@"argument is null" userInfo:nil];

			@throw exception;
		}

		argv[argc++] = object;
	}

	string = NSStringFromSelector([invocation selector]);
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

	if (lemon_machine_halted(lemon)) {
		exception = [NSException exceptionWithName:@"Runtime" reason:@"lemon machine halted" userInfo:nil];

		@throw exception;
	}
	name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));

	struct lframe *pause;
	pause = lemon_machine_add_pause(lemon);

	object = (void *)objc_getAssociatedObject(self, &kLemonObjectKey);
	if (!object) {
		exception = [NSException exceptionWithName:@"Runtime" reason:@"object is not binding" userInfo:nil];

		@throw exception;
	}
	lobject_call_attr(lemon, object, name, argc, argv);
	object = lemon_machine_execute_loop(lemon);
	lemon_machine_del_pause(lemon, pause);
	if (lobject_is_error(lemon, object)) {
		lemon_machine_throw(lemon, object);
	} else {
		lemon_machine_return_frame(lemon, object);
	}

	type = [signature methodReturnType];
	if (strcmp(type, @encode(char)) == 0 ||
	    strcmp(type, @encode(int)) == 0 ||
	    strcmp(type, @encode(short)) == 0 ||
	    strcmp(type, @encode(long)) == 0 ||
	    strcmp(type, @encode(long long)) == 0)
	{
		long long value;

		value = 0;
		if (!lobject_is_integer(lemon, object)) {
			if (object == lemon->l_true) {
				value = YES;
			} else if (object== lemon->l_false) {
				value = NO;
			}
		} else {
			value = linteger_to_long(lemon, object);
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(unsigned char)) == 0 ||
	           strcmp(type, @encode(unsigned int)) == 0 ||
	           strcmp(type, @encode(unsigned short)) == 0 ||
	           strcmp(type, @encode(unsigned long)) == 0 ||
	           strcmp(type, @encode(unsigned long long)) == 0)
	{
		unsigned long long value;

		value = 0;
		if (!lobject_is_integer(lemon, object)) {
			if (object == lemon->l_true) {
				value = YES;
			} else if (object == lemon->l_false) {
				value = NO;
			}
		} else {
			value = linteger_to_long(lemon, object);
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(float)) == 0) {
		float value;

		value = 0.0;
		if (lobject_is_integer(lemon, object)) {
			value = (float)linteger_to_long(lemon, object);
		} else if (lobject_is_number(lemon, object)) {
			value = (float)lnumber_to_double(lemon, object);
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(double)) == 0) {
		double value;

		value = 0;
		if (lobject_is_integer(lemon, object)) {
			value = (double)linteger_to_long(lemon, object);
		} else if (lobject_is_number(lemon, object)) {
			value = lnumber_to_double(lemon, object);
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(char *)) == 0) {
		char *value;

		value = NULL;
		if (lobject_is_string(lemon, object)) {
			value = (char *)lstring_to_cstr(lemon, object);
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(Class)) == 0) {
		Class value;

		value = nil;
		if (lobjc_is_Class(lemon, object)) {
			value = ((struct lobjc_Class *)object)->target;
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(SEL)) == 0) {
		SEL value;

		value = nil;
		if (lobjc_is_Selector(lemon, object)) {
			value = ((struct lobjc_Selector *)object)->selector;
		}

		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(id)) == 0) {
		id value;

		value = nil;
		if (lobject_is_integer(lemon, object)) {
			value = [NSNumber numberWithLong:linteger_to_long(lemon, object)];
		} else if (lobject_is_number(lemon, object)) {
			value = [NSNumber numberWithDouble:linteger_to_long(lemon, object)];
		} else if (lobject_is_string(lemon, object)) {
			value = [NSString stringWithUTF8String:lstring_to_cstr(lemon, object)];
		} else if (lobjc_is_Object(lemon, object)) {
			value = ((struct lobjc_Object *)object)->target;
		} else if (lobject_is_instance(lemon, object)) {
			struct lobject *native = ((struct linstance *)object)->native;
			if (native && lobjc_is_Object(lemon, native)) {
				value = ((struct lobjc_Object *)native)->target;
			}
		}
		[invocation setReturnValue:&value];
	} else if (strcmp(type, @encode(CGRect)) == 0) {
		struct lobjc_Value *objc_Value;

		if (!lobjc_is_Value(lemon, object)) {
			return;
		}

		objc_Value = (struct lobjc_Value *)object;
		if (strcmp(objc_Value->type, type) != 0) {
			return;
		}
		[invocation setReturnValue:&objc_Value->u.rect];
	} else if (strcmp(type, @encode(CGSize)) == 0) {
		struct lobjc_Value *objc_Value;

		if (!lobjc_is_Value(lemon, object)) {
			return;
		}

		objc_Value = (struct lobjc_Value *)object;
		if (strcmp(objc_Value->type, type) != 0) {
			return;
		}
		[invocation setReturnValue:&objc_Value->u.size];
	} else if (strcmp(type, @encode(CGPoint)) == 0) {
		struct lobjc_Value *objc_Value;

		if (!lobjc_is_Value(lemon, object)) {
			return;
		}

		objc_Value = (struct lobjc_Value *)object;
		if (strcmp(objc_Value->type, type) != 0) {
			return;
		}
		[invocation setReturnValue:&objc_Value->u.point];
	} else if (strcmp(type, @encode(NSRange)) == 0) {
		struct lobjc_Value *objc_Value;

		if (!lobjc_is_Value(lemon, object)) {
			return;
		}

		objc_Value = (struct lobjc_Value *)object;
		if (strcmp(objc_Value->type, type) != 0) {
			return;
		}
		[invocation setReturnValue:&objc_Value->u.range];
	} else if (strcmp(type, @encode(void)) == 0) {
	} else {
		exception = [NSException exceptionWithName:@"Type" reason:@"object type unsupported" userInfo:nil];

		@throw exception;
	}
}

struct lobject *
lobjc_Class_subclass(struct lemon *lemon, struct lobjc_Class *self, struct lclass *clazz)
{
	int i;
	Class cls;
	const char *cstr;
	struct lobject *name;
	struct lobjc_Class *objc_Class;
	struct lframe *frame;

	frame = lemon_machine_get_frame(lemon, 0);
	objc_Class = NULL;
	for (i = 0; i < larray_length(lemon, clazz->bases); i++) {
		struct lobject *item;

		item = larray_get_item(lemon, clazz->bases, i);
		if (lobjc_is_Class(lemon, item)) {
			objc_Class = (struct lobjc_Class *)item;
			break;
		}
	}

	if (!objc_Class) {
		return NULL;
	}

	cls = objc_allocateClassPair(objc_Class->target, lstring_to_cstr(lemon, clazz->name), 0);

	IMP respondsToSelector = imp_implementationWithBlock(^BOOL(id self, SEL selector) {
		return lobjc_Class_respondsToSelector(lemon, clazz, self, selector);
	});
	class_addMethod(cls, @selector(respondsToSelector:), respondsToSelector, "c@::");

	IMP methodSignatureForSelector = imp_implementationWithBlock(^id(id self, SEL selector) {
		return lobjc_Class_methodSignatureForSelector(lemon, clazz, self, selector);
	});
	class_addMethod(cls, @selector(methodSignatureForSelector:), methodSignatureForSelector, "@@::");

	IMP forwardInvocation = imp_implementationWithBlock(^void(id self, NSInvocation *invocation) {
		lobjc_Class_forwardInvocation(lemon, clazz, self, invocation);
	});
	class_addMethod(cls, NSSelectorFromString(@"forwardInvocation:"), forwardInvocation, "v@:@");
	objc_registerClassPair(cls);
	
	objc_Class = lobjc_Class_create(lemon, cls);

	unsigned int count;
	Class supercls = class_getSuperclass(cls);
	while (supercls) {
		Method *methods = class_copyMethodList(supercls, &count);
		for (i = 0; i < count; i++) {
			NSString *string;
			struct lobject *name;

			string = NSStringFromSelector(method_getName(methods[i]));
			if ([string hasPrefix:@"_"]) {
				continue;
			}
			if (method_getName(methods[i]) == @selector(respondsToSelector:)) {
				continue;
			}
			if (method_getName(methods[i]) == @selector(methodSignatureForSelector:)) {
				continue;
			}
			if (method_getName(methods[i]) == @selector(forwardInvocation:)) {
				continue;
			}

			if (method_getName(methods[i]) == @selector(retain)) {
				continue;
			}

			if (method_getName(methods[i]) == @selector(release)) {
				continue;
			}
			if (method_getName(methods[i]) == @selector(autorelease)) {
				continue;
			}

			string = [string stringByReplacingOccurrencesOfString:@":" withString:@"_"];

			name = lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
			if (lobject_has_item(lemon, clazz->attr, name) == lemon->l_true) {
				NSLog(@"replacing: %@", string);

				int ret = class_addMethod(cls,
				                          method_getName(methods[i]),
				                          _objc_msgForward,
				                          method_getTypeEncoding(methods[i]));
				printf("ret: %d\n", ret);
			}
		}
		supercls = class_getSuperclass(supercls);
	}

	for (i = 0; i < larray_length(lemon, clazz->bases); i++) {
		struct lobject *item;

		item = larray_get_item(lemon, clazz->bases, i);
		if (lobjc_is_Class(lemon, item)) {
			larray_set_item(lemon, clazz->bases, i, (struct lobject *)objc_Class);
			break;
		}
	}

	return NULL;
}

struct lobject *
lobjc_Class_call(struct lemon *lemon, struct lobjc_Class *self, int argc, struct lobject *argv[])
{
	int i;
	id target;
	SEL selector;
	NSString *string;

	struct lobject *object;
	struct lobjc_Object *objc_Object;
	struct lobjc_Method *objc_Method;

	struct lframe *frame;
	frame = lemon_machine_push_new_frame(lemon,
	                                     NULL,
	                                     NULL,
	                                     lframe_default_callback,
	                                     0);
	if (!frame) {
		return NULL;
	}

	string = @"init";
	if (argc) {
		string = [string stringByAppendingString:@"With"];
		for (i = 0; i < argc; i++) {
			if (!lobject_is_karg(lemon, argv[i])) {
				return lobject_error_argument(lemon, "required keyword argument");
			}
			struct lkarg *karg;
			NSString *s;
	
			karg = (struct lkarg *)argv[i];
			NSString *keyword = [NSString stringWithUTF8String:lstring_to_cstr(lemon, karg->keyword)];
			argv[i] = karg->argument;
			if (i) {
				s = [NSString stringWithFormat:@"%@:", keyword];
			} else {
				if ([keyword length] == 1) {
					s = [keyword uppercaseString];
				} else if ([keyword length] > 1) {
					NSString *first;
					first = [[keyword substringToIndex:1] uppercaseString];
					s = [NSString stringWithFormat:@"%@%@:", first, [keyword substringFromIndex:1]];
				}
			}
			string = [string stringByAppendingString:s];
		}
	}
	target = [self->target alloc];
	selector = NSSelectorFromString(string);
	if (![target respondsToSelector:selector]) {
		[target release];

		return lobject_error_argument(lemon, "not found init function");
	}
	objc_Object = lobjc_Object_create(lemon, target);
	objc_Method = lobjc_Method_create(lemon, (struct lobject *)objc_Object, selector);

	object = lobject_call(lemon, (struct lobject *)objc_Method, argc, argv);
	if (lobject_is_error(lemon, object)) {
		return object;
	}

	if (!lobjc_is_Object(lemon, object)) {
		[target release];

		return lobject_error_type(lemon, "init return not object");
	}

	return object;
}

struct lobject *
lobjc_Class_method(struct lemon *lemon, struct lobject *self, int method, int argc, struct lobject *argv[])
{
#define cast(a) ((struct lobjc_Class *)(a))

	switch (method) {
	case LOBJECT_METHOD_CALL:
		return lobjc_Class_call(lemon, cast(self), argc, argv);

	case LOBJECT_METHOD_GET_ATTR: {
		id target;
		SEL selector;
		NSString *string;
		target = cast(self)->target;
		string = [NSString stringWithUTF8String:lstring_to_cstr(lemon, argv[0])];
		string = [string stringByReplacingOccurrencesOfString:@"_" withString:@":"];
		selector = NSSelectorFromString(string);
		if (![cast(self)->target respondsToSelector:selector]) {
			return NULL;
		}

		return lobjc_Method_create(lemon, self, selector);
	}
	case LOBJECT_METHOD_SUBCLASS:
		return lobjc_Class_subclass(lemon, cast(self), (struct lclass *)argv[0]);

	case LOBJECT_METHOD_STRING: {
		const char *buffer = [[NSString stringWithFormat:@"%@", cast(self)->target] UTF8String];
		return lstring_create(lemon, buffer, strlen(buffer));
	}

	default:
		return lobject_default(lemon, self, method, argc, argv);
	}
}

void *
lobjc_Class_create(struct lemon *lemon, Class target)
{
	struct lobjc_Class *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Class), lobjc_Class_method);
	if (self) {
		self->target = target;
	}

	return self;
}

int
lobjc_is_Class(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object->l_method == lobjc_Class_method;
	}

	return 0;
}

