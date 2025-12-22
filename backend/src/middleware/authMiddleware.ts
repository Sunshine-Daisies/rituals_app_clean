import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: any;
}

export const protect = (req: AuthRequest, res: Response, next: NextFunction) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET as string);
      req.user = decoded;
      next();
    } catch (error) {
      res.status(401).json({ error: 'Unauthorized discovery, invalid token' });
    }
  }

  if (!token) {
    res.status(401).json({ error: 'Unauthorized access, no token provided' });
  }
};

export const optionalAuth = (req: AuthRequest, res: Response, next: NextFunction) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET as string);
      req.user = decoded;
    } catch (error) {
      // Token invalid, but we don't block, just don't set user
    }
  }
  next();
};
