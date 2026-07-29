import jwt from 'jsonwebtoken';
import { describe, expect, it } from 'vitest';

import { signSessionToken, verifySessionToken } from './jwt';

describe('jwt', () => {
  it('round-trips a userId through sign and verify', () => {
    const token = signSessionToken('user-123');
    expect(verifySessionToken(token)).toBe('user-123');
  });

  it('rejects a garbage token', () => {
    expect(() => verifySessionToken('not-a-real-token')).toThrow();
  });

  it('rejects a token signed with a different secret', () => {
    // Simulates a forged token — jsonwebtoken itself already covers most of
    // this, but this pins the behavior our middleware relies on.
    const forged = jwt.sign({ sub: 'user-123' }, 'wrong-secret');
    expect(() => verifySessionToken(forged)).toThrow();
  });
});
