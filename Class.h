#import <Foundation/Foundation.h>

#include "lobject.h"

struct lobjc_Class {
	struct lobject object;

	Class target;
};

void *
lobjc_Class_create(struct lemon *lemon, Class target);

int
lobjc_is_Class(struct lemon *lemon, struct lobject *object);
