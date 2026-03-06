'use strict';
require('dotenv').config();
const jwt = require('jsonwebtoken');

/**
 * Express middleware that reads the Bearer token from the Authorization
 * header, verifies it, and attaches { id, username, email } to req.user.
 */
function requireAuth(req, res, next) {
  const header = req.headers['authorization'];
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header.' });
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { id: payload.sub, sub: payload.sub, username: payload.username, email: payload.email };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

module.exports = { requireAuth };
