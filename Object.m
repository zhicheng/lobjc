#import <objc/runtime.h>
#import <objc/message.h>

#import "lobjc.h"
#import "Super.h"
#import "Object.h"
#import "Method.h"

#include "lemon.h"
#include "machine.h"
#include "larray.h"
#include "lstring.h"
#include "linteger.h"
#include "linstance.h"

extern void *kLemonObjectKey;

struct lobject *
lobjc_Object_super(struct lemon *lemon, struct lobjc_Object *self)
{
	return lobjc_Super_create(lemon, self->target);
}

struct lobject *
lobjc_Object_method(struct lemon *lemon, struct lobject *self, int method, int argc, struct lobject *argv[])
{
#define cast(a) ((struct lobjc_Object *)(a))

	switch (method) {
	case LOBJECT_METHOD_GET_ATTR: {
		SEL selector;
		const char *cstr;
		NSString *string;

		cstr = lstring_to_cstr(lemon, argv[0]);
		if (strcmp(cstr, "__init__") == 0) {
			return NULL;
		}
		string = [NSString stringWithUTF8String:cstr];
		string = [string stringByReplacingOccurrencesOfString:@"_" withString:@":"];
		selector = NSSelectorFromString(string);
		if (![cast(self)->target respondsToSelector:selector]) {
			return NULL;
		}

		return lobjc_Method_create(lemon, self, selector);
	}
	case LOBJECT_METHOD_SUPER: {
		return lobjc_Object_super(lemon, cast(self));
	}
	case LOBJECT_METHOD_INSTANCE: {
		struct linstance *instance;

		instance = (struct linstance *)argv[0];
		if (instance->native && lobjc_is_Object(lemon, instance->native)) {
			objc_setAssociatedObject(cast(self)->target,
			                         &kLemonObjectKey,
			                         (__bridge id)argv[0],
			                         OBJC_ASSOCIATION_ASSIGN);
		}

		return NULL;
	}

	case LOBJECT_METHOD_STRING: {
		id target;
		const char *buffer;

		target = cast(self)->target;
		if ([target isProxy]) {
			target = [target target];
		}
		buffer = [[NSString stringWithFormat:@"%@", target] UTF8String];

		return lstring_create(lemon, buffer, strlen(buffer));
	}

	case LOBJECT_METHOD_MARK: {
		id target;
		struct lobject *object;

		target = cast(self)->target;
		object = (void *)objc_getAssociatedObject(target, &kLemonObjectKey);
		if (object) {
			lobject_mark(lemon, object);
		}

		return NULL;
	}
	case LOBJECT_METHOD_DESTROY: {
		[cast(self)->target release];

		return NULL;
	}

	default:
		return lobject_default(lemon, self, method, argc, argv);
	}
}

void *
lobjc_Object_create(struct lemon *lemon, id target)
{
	struct lobjc_Object *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Object), lobjc_Object_method);
	if (self) {
		[target retain];

		self->target = target;
	}

	return self;
}

int
lobjc_is_Object(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object->l_method == lobjc_Object_method;
	}

	return 0;
}
