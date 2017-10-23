#import <objc/runtime.h>

#import "lobjc.h"
#import "Value.h"
#import "Class.h"
#import "Super.h"
#import "Object.h"
#import "Method.h"
#import "Selector.h"

#include "lemon.h"
#include "larray.h"
#include "lstring.h"
#include "lnumber.h"
#include "linteger.h"
#include "linstance.h"

struct lobject *
lobjc_Method_call(struct lemon *lemon, struct lobjc_Method *self, int argc, struct lobject *argv[])
{
	int i;
	id target;
	SEL selector;
	const char *type;
	struct lframe *frame;
	struct lobject *object;
	struct lobject *receiver;

	NSInvocation *invocation;
	NSMethodSignature *signature;

	frame = lemon_machine_push_new_frame(lemon,
	                                     NULL,
	                                     (struct lobject *)self,
	                                     lframe_default_callback,
	                                     0);
	if (!frame) {
		return NULL;
	}

	target = nil;
	receiver = self->receiver;
	if (lobjc_is_Class(lemon, receiver)) {
		target = ((struct lobjc_Class *)receiver)->target;
	} else if (lobjc_is_Super(lemon, receiver)) {
		target = ((struct lobjc_Super *)receiver)->target;
	} else if (lobjc_is_Object(lemon, receiver)) {
		target = ((struct lobjc_Object *)receiver)->target;
	}

	if (!target) {
		return lobject_error_type(lemon, "Method receiver doesn't have target");
	}

	selector = self->selector;
	signature = [target methodSignatureForSelector:selector];
	if (!signature) {
		return lobject_error_type(lemon,
		                          "Selector '%s' not found",
		                          [NSStringFromSelector(selector) UTF8String]);
	}

	invocation = [NSInvocation invocationWithMethodSignature:signature];
	[invocation setTarget:target];
	[invocation setSelector:selector];

	if (argc != [signature numberOfArguments] - 2) {
		return lobject_error_argument(lemon, "argc not match with Selector");
	}

	for (i = 0; i < argc; i++) {
		type = [signature getArgumentTypeAtIndex:i + 2];
		object = argv[i];

		if (strcmp(type, @encode(char)) == 0 ||
		    strcmp(type, @encode(int)) == 0 ||
		    strcmp(type, @encode(short)) == 0 ||
		    strcmp(type, @encode(long)) == 0 ||
		    strcmp(type, @encode(long long)) == 0)
		{
			long long value;

			if (!lobject_is_integer(lemon, object)) {
				if (object == lemon->l_true) {
					value = YES;
				} else if (object== lemon->l_false) {
					value = NO;
				} else {
					return lobject_error_argument(lemon, "a required integer");
				}
			} else {
				value = linteger_to_long(lemon, object);
			}

			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(unsigned char)) == 0 ||
		           strcmp(type, @encode(unsigned int)) == 0 ||
		           strcmp(type, @encode(unsigned short)) == 0 ||
		           strcmp(type, @encode(unsigned long)) == 0 ||
		           strcmp(type, @encode(unsigned long long)) == 0)
		{
			unsigned long long value;

			if (!lobject_is_integer(lemon, object)) {
				if (object == lemon->l_true) {
					value = YES;
				} else if (object == lemon->l_false) {
					value = NO;
				} else {
					return lobject_error_argument(lemon, "b required integer");
				}
			} else {
				value = linteger_to_long(lemon, object);
			}

			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(float)) == 0) {
			float value;

			if (lobject_is_integer(lemon, object)) {
				value = (float)linteger_to_long(lemon, object);
			} else if (lobject_is_number(lemon, object)) {
				value = (float)lnumber_to_double(lemon, object);
			} else {
				return lobject_error_argument(lemon, "required float");
			}

			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(double)) == 0) {
			double value;

			if (lobject_is_integer(lemon, object)) {
				value = (double)linteger_to_long(lemon, object);
			} else if (lobject_is_number(lemon, object)) {
				value = lnumber_to_double(lemon, object);
			} else {
				return lobject_error_argument(lemon, "required double");
			}

			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(char *)) == 0) {
			char *value;

			if (!lobject_is_string(lemon, object)) {
				return lobject_error_argument(lemon, "required string");
			}
			value = (char *)lstring_to_cstr(lemon, object);

			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(Class)) == 0) {
			struct lobjc_Class *objc_Class;

			if (!lobjc_is_Class(lemon, object)) {
				return lobject_error_argument(lemon, "required Class");
			}
			objc_Class = (struct lobjc_Class *)object;

			[invocation setArgument:&objc_Class->target atIndex:i + 2];
		} else if (strcmp(type, @encode(SEL)) == 0) {
			struct lobjc_Selector *objc_Selector;

			if (!lobjc_is_Selector(lemon, object)) {
				return lobject_error_argument(lemon, "required SEL");
			}
			objc_Selector = (struct lobjc_Selector *)object;

			[invocation setArgument:&objc_Selector->selector atIndex:i + 2];
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
				} else {
					return lobject_error_argument(lemon, "required object");
				}
			}
			[invocation setArgument:&value atIndex:i + 2];
		} else if (strcmp(type, @encode(CGRect)) == 0) {
			struct lobjc_Value *objc_Value;

			if (!lobjc_is_Value(lemon, object)) {
				return lobject_error_argument(lemon, "required CGRect");
			}

			objc_Value = (struct lobjc_Value *)object;
			if (strcmp(objc_Value->type, type) != 0) {
				return lobject_error_argument(lemon, "required CGRect");
			}
			[invocation setArgument:&objc_Value->u.rect atIndex:i + 2];
		} else if (strcmp(type, @encode(CGSize)) == 0) {
			struct lobjc_Value *objc_Value;

			if (!lobjc_is_Value(lemon, object)) {
				return lobject_error_argument(lemon, "required CGSize");
			}

			objc_Value = (struct lobjc_Value *)object;
			if (strcmp(objc_Value->type, type) != 0) {
				return lobject_error_argument(lemon, "required CGRect");
			}
			[invocation setArgument:&objc_Value->u.size atIndex:i + 2];
		} else if (strcmp(type, @encode(CGPoint)) == 0) {
			struct lobjc_Value *objc_Value;

			if (!lobjc_is_Value(lemon, object)) {
				return lobject_error_argument(lemon, "required CGPoint");
			}

			objc_Value = (struct lobjc_Value *)object;
			if (strcmp(objc_Value->type, type) != 0) {
				return lobject_error_argument(lemon, "required CGPoint");
			}
			[invocation setArgument:&objc_Value->u.point atIndex:i + 2];
		} else if (strcmp(type, @encode(NSRange)) == 0) {
			struct lobjc_Value *objc_Value;

			if (!lobjc_is_Value(lemon, object)) {
				return lobject_error_argument(lemon, "required NSRange");
			}

			objc_Value = (struct lobjc_Value *)object;
			if (strcmp(objc_Value->type, type) != 0) {
				return lobject_error_argument(lemon, "required NSRange");
			}
			[invocation setArgument:&objc_Value->u.range atIndex:i + 2];
		} else if (strncmp(type, "^", 1) == 0) {
			void *value;


			if (lobjc_is_Value(lemon, object)) {
				struct lobjc_Value *objc_Value;
				objc_Value = (struct lobjc_Value *)object;
				if (strcmp(objc_Value->type, type) != 0) {
					return lobject_error_argument(lemon, "required %s", type);
				}
				value = objc_Value->u.ptr;
			} else if (object == lemon->l_nil) {
				value = NULL;
			} else {
				return lobject_error_argument(lemon, "required void *");
			}

			[invocation setArgument:&value atIndex:i + 2];
		} else {
			return lobject_error_argument(lemon, "unknown argument type '%s'", type);
		}
	}

	if (lobjc_is_Super(lemon, receiver)) {
		Method method;
		NSString *string;

		method = class_getInstanceMethod([target superclass], selector);
		string = NSStringFromSelector(selector);
		string = [@"__super__" stringByAppendingString:string];
		selector = NSSelectorFromString(string);
		class_addMethod([target class],
		                selector, method_getImplementation(method), method_getTypeEncoding(method));
		[invocation setSelector:selector];
	}
	[invocation invoke];
    
	type = signature.methodReturnType;
	object = lemon->l_nil;

	if (strcmp(type, @encode(char)) == 0 ||
	    strcmp(type, @encode(int)) == 0 ||
	    strcmp(type, @encode(short)) == 0 ||
	    strcmp(type, @encode(long)) == 0 ||
	    strcmp(type, @encode(long long)) == 0)
	{
		long long value;

		value = 0;
		[invocation getReturnValue:&value];

		object = linteger_create_from_long(lemon, value);
	} else if (strcmp(type, @encode(unsigned char)) == 0 ||
	           strcmp(type, @encode(unsigned int)) == 0 ||
	           strcmp(type, @encode(unsigned short)) == 0 ||
	           strcmp(type, @encode(unsigned long)) == 0 ||
	           strcmp(type, @encode(unsigned long long)) == 0)
	{
		unsigned long long value;

		value = 0;
		[invocation getReturnValue:&value];

		object = linteger_create_from_long(lemon, value);
	} else if (strcmp(type, @encode(float)) == 0) {
		float value;
		char buffer[256];

		[invocation getReturnValue:&value];
		sprintf(buffer, "%g", value);

		object = lnumber_create_from_cstr(lemon, buffer);
	} else if (strcmp(type, @encode(double)) == 0) {
		double value;
		char buffer[256];

		[invocation getReturnValue:&value];
		sprintf(buffer, "%g", value);

		object = lnumber_create_from_cstr(lemon, buffer);
	} else if (strcmp(type, @encode(char *)) == 0) {
		char *value;

		[invocation getReturnValue:&value];

		object = lstring_create(lemon, value, strlen(value));
	} else if (strcmp(type, @encode(Class)) == 0) {
		Class value;

		[invocation getReturnValue:&value];

		object = lobjc_Class_create(lemon, value);
	} else if (strcmp(type, @encode(SEL)) == 0) {
		SEL value;

		[invocation getReturnValue:&value];

		object = lobjc_Selector_create(lemon, value);
	} else if (strcmp(type, @encode(id)) == 0) {
		id value;

		[invocation getReturnValue:&value];

		object = lobjc_Object_create(lemon, value);
	} else if (strcmp(type, @encode(CGRect)) == 0) {
		CGRect value;
		struct lobjc_Value *objc_Value;

		[invocation getReturnValue:&value];

		objc_Value = lobjc_Value_create(lemon, @encode(CGRect));
		objc_Value->u.rect = value;

		object = (struct lobject *)objc_Value;
	} else if (strcmp(type, @encode(CGSize)) == 0) {
		CGSize value;
		struct lobjc_Value *objc_Value;

		[invocation getReturnValue:&value];

		objc_Value = lobjc_Value_create(lemon, @encode(CGSize));
		objc_Value->u.size = value;

		object = (struct lobject *)objc_Value;
	} else if (strcmp(type, @encode(CGPoint)) == 0) {
		CGPoint value;
		struct lobjc_Value *objc_Value;

		[invocation getReturnValue:&value];

		objc_Value = lobjc_Value_create(lemon, @encode(CGPoint));
		objc_Value->u.point = value;

		object = (struct lobject *)objc_Value;
	} else if (strcmp(type, @encode(NSRange)) == 0) {
		NSRange value;
		struct lobjc_Value *objc_Value;

		[invocation getReturnValue:&value];

		objc_Value = lobjc_Value_create(lemon, @encode(NSRange));
		objc_Value->u.range = value;

		object = (struct lobject *)objc_Value;
	} else if (strcmp(type, @encode(void)) == 0) {
		object = lemon->l_nil;
	} else {
		return lobject_error_type(lemon, "unknown return type '%s'", type);
	}

	return (struct lobject *)object;
}

struct lobject *
lobjc_Method_method(struct lemon *lemon, struct lobject *self, int method, int argc, struct lobject *argv[])
{
#define cast(a) ((struct lobjc_Method *)(a))

	switch (method) {
	case LOBJECT_METHOD_CALL:
		return lobjc_Method_call(lemon, cast(self), argc, argv);

	case LOBJECT_METHOD_CALLABLE:
		return lemon->l_true;

	case LOBJECT_METHOD_STRING: {
		id target;
		NSString *string;
		struct lobject *receiver;

		receiver = cast(self)->receiver;
		if (lobjc_is_Class(lemon, receiver)) {
			target = ((struct lobjc_Class *)receiver)->target;
		} else if (lobjc_is_Super(lemon, receiver)) {
			target = ((struct lobjc_Super *)receiver)->target;
		} else if (lobjc_is_Object(lemon, receiver)) {
			target = ((struct lobjc_Object *)receiver)->target;
		}

		if (!target) {
			string = [NSString stringWithFormat:@"[%@]",
					NSStringFromSelector(cast(self)->selector)];
		} else {
			string = [NSString stringWithFormat:@"[%@ %@]",
					target, NSStringFromSelector(cast(self)->selector)];
		}

		return lstring_create(lemon, [string UTF8String], strlen([string UTF8String]));
	}

	case LOBJECT_METHOD_MARK:
		lobject_mark(lemon, cast(self)->receiver);
		return NULL;

	default:
		return lobject_default(lemon, self, method, argc, argv);
	}
}

void *
lobjc_Method_create(struct lemon *lemon, struct lobject *receiver, SEL selector)
{
	struct lobjc_Method *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Method), lobjc_Method_method);
	if (self) {
		self->selector = selector;
		self->receiver = receiver;
	}

	return self;
}

int
lobjc_is_Method(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object->l_method == lobjc_Method_method;
	}

	return 0;
}
