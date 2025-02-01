const jwt = require("jsonwebtoken");

function jwtAuth(req, res, next) {
  // Récupérer le token dans le header Authorization au format "Bearer <token>"
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ message: "Accès refusé, token manquant" });
  }
  const token = authHeader.split(" ")[1];
  if (!token) {
    return res.status(401).json({ message: "Accès refusé, token mal formaté" });
  }
  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET);
    req.user = verified;
    next();
  } catch (error) {
    console.error("Erreur JWT :", error);
    res.status(400).json({ message: "Token invalide" });
  }
}

module.exports = { jwtAuth };
