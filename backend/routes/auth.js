const express = require("express");
const bcrypt = require("bcrypt");
const User = require("../models/User");
const { OAuth2Client } = require("google-auth-library");
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
const router = express.Router();
// @ts-ignore
// Route pour la connexion
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "Utilisateur non trouvé" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Mot de passe incorrect" });
    }

    // Ajouter une validation supplémentaire pour les comptes Google
    if (user.googleId && !user.password) {
      user.password = undefined; // Force l'absence de password
    }

    res.json({ message: "Connexion réussie", userId: user._id });
  } catch (error) {
    console.error("Erreur lors de la connexion:", error);
    res.status(500).json({ message: "Erreur lors de la connexion" });
  }
});

// Route pour l'inscription
router.post("/register", async (req, res) => {
  const { email, password } = req.body;

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "L'utilisateur existe déjà" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({ email, password: hashedPassword });

    await newUser.save();
    res.status(201).json({ message: "Utilisateur créé avec succès" });
  } catch (error) {
    console.error("Erreur lors de l'inscription:", error);
    res.status(500).json({ message: "Erreur lors de l'inscription" });
  }
});

router.post("/google", async (req, res) => {
  try {
    if (!req.body || !req.body.idToken) {
      return res.status(400).json({ message: "Token manquant" });
    }

    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: "Token manquant" });
    }

    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();

    let user = await User.findOneAndUpdate(
      { email: payload.email },
      {
        $setOnInsert: {
          googleId: payload.sub,
          name: payload.name,
          profileImage: payload.picture,
          email: payload.email,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    console.log("Utilisateur Google trouvé/créé :", user);
    // Ajouter une validation supplémentaire pour les comptes Google
    if (user.googleId && !user.password) {
      user.password = undefined; // Force l'absence de password
    }
    res.status(200).json({
      userId: user._id.toString(),
      email: user.email,
      favoriteToys: user.favoriteToys,
    });
  } catch (error) {
    console.error("Erreur Google :", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
