export type JwtPayload = {
  readonly sub: string;
  readonly username: string;
  readonly tokenVersion: number;
};
