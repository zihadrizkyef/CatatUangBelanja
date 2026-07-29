import jwt from 'jsonwebtoken';

const secret: string = (() => {
  const value = process.env.JWT_SECRET;
  if (!value) {
    throw new Error('JWT_SECRET is not set');
  }
  return value;
})();

export function signSessionToken(userId: string): string {
  return jwt.sign({ sub: userId }, secret, { expiresIn: '30d' });
}

export function verifySessionToken(token: string): string {
  const payload = jwt.verify(token, secret) as jwt.JwtPayload;
  if (typeof payload.sub !== 'string') {
    throw new Error('Invalid token payload');
  }
  return payload.sub;
}
