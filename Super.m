#import <objc/runtime.h>

#import "lobjc.h"
#import "Super.h"
#import "Method.h"

#include "lemon.h"
#include "larray.h"
#include "lstring.h"
#include "linteger.h"

struct lobject *
lobjc_Super_method(struct lemon *lemon, struct lobject *self, int method, int argc, struct lobject *argv[])
{
#define cast(a) ((struct lobjc_Super *)(a))

	switch (method) {
	case LOBJECT_METHOD_GET_ATTR: {
		id target;
		SEL selector;
		NSString *string;
		struct lobjc_Method *method;
		target = cast(self)->target;
		string = [NSString stringWithUTF8String:lstring_to_cstr(lemon, argv[0])];
		string = [string stringByReplacingOccurrencesOfString:@"_" withString:@":"];
		selector = NSSelectorFromString(string);
		if (![cast(self)->target respondsToSelector:selector]) {
			return NULL;
		}
		return lobjc_Method_create(lemon, self, selector);
	}
	case LOBJECT_METHOD_STRING: {
		const char *buffer = [[NSString stringWithFormat:@"%@", cast(self)->target] UTF8String];
		return lstring_create(lemon, buffer, strlen(buffer));
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
lobjc_Super_create(struct lemon *lemon, id target)
{
	struct lobjc_Super *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Super), lobjc_Super_method);
	if (self) {
		[target retain];

		self->target = target;
	}

	return self;
}

int
lobjc_is_Super(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object->l_method == lobjc_Super_method;
	}

	return 0;
}
