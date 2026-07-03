import type { Request } from 'express';

import { CurrentUserPayload } from './current-user.model';

export type AuthenticatedRequest = Request & {
  user?: CurrentUserPayload;
};
