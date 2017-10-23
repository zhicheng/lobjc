#import <Foundation/Foundation.h>

#include "lobject.h"

struct lobjc_Method {
	struct lobject object;

	SEL selector;
	struct lobject *receiver;
};

void *
lobjc_Method_create(struct lemon *lemon, struct lobject *receiver, SEL selector);

int
lobjc_is_Method(struct lemon *lemon, struct lobject *object);
