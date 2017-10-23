#import <objc/runtime.h>

#import "Selector.h"

#include "lemon.h"
#include "larray.h"
#include "linteger.h"

struct lobject *
lobjc_Selector_method(struct lemon *lemon, struct lobject *self_, int method, int argc, struct lobject *argv[])
{
	return lobject_default(lemon, self_, method, argc, argv);
}

void *
lobjc_Selector_create(struct lemon *lemon, SEL selector)
{
	struct lobjc_Selector *self;

	self = lobject_create(lemon, sizeof(struct lobjc_Selector), lobjc_Selector_method);
	if (self) {
		self->selector = selector;
	}

	return self;
}

int
lobjc_is_Selector(struct lemon *lemon, struct lobject *object)
{
	if (lobject_is_pointer(lemon, object)) {
		return object->l_method == lobjc_Selector_method;
	}

	return 0;
}
