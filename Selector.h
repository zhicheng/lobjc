#import <Foundation/Foundation.h>

#include "lobject.h"

struct lobjc_Selector {
	struct lobject object;

	SEL selector;
};

void *
lobjc_Selector_create(struct lemon *lemon, SEL selector);

int
lobjc_is_Selector(struct lemon *lemon, struct lobject *object);
