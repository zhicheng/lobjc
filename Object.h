#import <Foundation/Foundation.h>

#include "lobject.h"

struct lobjc_Object {
	struct lobject object;

	id target;
};

void *
lobjc_Object_create(struct lemon *lemon, id target);

int
lobjc_is_Object(struct lemon *lemon, struct lobject *object);
