const mongoose = require("mongoose");

// Définition du schéma utilisateur
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true, // Assurez-vous que l'email est unique
    lowercase: true, // Convertit l'email en minuscules
    trim: true, // Supprime les espaces autour de l'email
  },
  password: {
    type: String,
    required: true, // Le mot de passe est requis
    minlength: 6, // Longueur minimale du mot de passe
  },
});

// Création du modèle utilisateur
const User = mongoose.model("User", userSchema);

// Exportation du modèle
module.exports = User;
