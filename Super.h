#import <Foundation/Foundation.h>

#include "lobject.h"

struct lobjc_Super {
	struct lobject object;

	id target;
};

void *
lobjc_Super_create(struct lemon *lemon, id target);

int
lobjc_is_Super(struct lemon *lemon, struct lobject *object);
