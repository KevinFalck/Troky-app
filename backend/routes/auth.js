const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const { OAuth2Client } = require("google-auth-library");
const { jwtAuth } = require("../middleware/jwtAuth");
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
const router = express.Router();

// Route de connexion
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

    // Pour les comptes Google, ne pas renvoyer le mot de passe
    if (user.googleId && !user.password) {
      user.password = undefined;
    }

    // Génération du token avec une durée d'expiration (1 jour par exemple)
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "1d",
    });

    // Retourne les informations de l'utilisateur et le token
    res.json({
      message: "Connexion réussie",
      userId: user._id,
      token,
      email: user.email,
      name: user.name,
      profileImage: user.profileImage,
      rating: user.rating, // Moyenne des avis
      reviewsCount: user.reviewsCount, // Nombre total d'avis
    });
  } catch (error) {
    console.error("Erreur lors de la connexion:", error);
    res.status(500).json({ message: "Erreur lors de la connexion" });
  }
});

// Route d'inscription
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

    // Génération du token pour le nouvel utilisateur
    const token = jwt.sign({ id: newUser._id }, process.env.JWT_SECRET, {
      expiresIn: "1d",
    });

    res.status(201).json({
      message: "Utilisateur créé avec succès",
      userId: newUser._id,
      token,
      email: newUser.email,
    });
  } catch (error) {
    console.error("Erreur lors de l'inscription:", error);
    res.status(500).json({ message: "Erreur lors de l'inscription" });
  }
});

// Route d'authentification Google
router.post("/google", async (req, res) => {
  try {
    if (!req.body || !req.body.idToken) {
      return res.status(400).json({ message: "Token manquant" });
    }

    const { idToken } = req.body;
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
          rating: null,
          reviewsCount: 0,
          totalListings: 0,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    // Générer un token JWT pour l'utilisateur connecté (compatible avec jwtAuth)
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: "1d",
    });

    // Si l'utilisateur est un compte Google, ne pas renvoyer le mot de passe
    if (user.googleId && !user.password) {
      user.password = undefined;
    }

    res.status(200).json({
      token, // On renvoie le token ici
      userId: user._id.toString(),
      email: user.email,
      name: user.name,
      profileImage: user.profileImage,
      rating: user.rating,
      reviewsCount: user.reviewsCount,
      favoriteToys: user.favoriteToys,
    });
  } catch (error) {
    console.error("Erreur Google :", error);
    res.status(500).json({ error: error.message });
  }
});

// Route pour récupérer le profil de l'utilisateur
router.get("/profile", jwtAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }
    res.status(200).json({
      _id: user._id,
      email: user.email,
      name: user.name,
      profileImage: user.profileImage,
      rating: user.rating,
      reviewsCount: user.reviewsCount,
      favoriteToys: user.favoriteToys,
      totalListings: user.totalListings,
    });
  } catch (error) {
    console.error("Erreur lors de la récupération du profil :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
});

// Route pour mettre à jour la photo de profil (attend { profileImage: "URL" } dans le body)
router.patch("/profile/image", jwtAuth, async (req, res) => {
  try {
    const newPhotoUrl = req.body.profileImage;
    if (!newPhotoUrl) {
      return res.status(400).json({ message: "L'URL de la photo est requise" });
    }
    const updatedUser = await User.findByIdAndUpdate(
      req.user.id,
      { profileImage: newPhotoUrl },
      { new: true }
    );
    if (!updatedUser) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }
    res.status(200).json({
      _id: updatedUser._id,
      email: updatedUser.email,
      name: updatedUser.name,
      profileImage: updatedUser.profileImage,
      rating: updatedUser.rating,
      reviewsCount: updatedUser.reviewsCount,
      favoriteToys: updatedUser.favoriteToys,
    });
  } catch (error) {
    console.error(
      "Erreur lors de la mise à jour de la photo de profil :",
      error
    );
    res
      .status(500)
      .json({ message: "Erreur lors de la mise à jour de la photo de profil" });
  }
});

module.exports = router;
