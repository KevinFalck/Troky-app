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
    required: function () {
      return !this.googleId;
    }, // Conditionnel
    minlength: 6, // Longueur minimale du mot de passe
  },
  googleId: {
    type: String,
    unique: true,
    sparse: true,
  },
  name: {
    type: String,
  },
  profileImage: {
    type: String,
  },
  favoriteToys: [{ type: mongoose.Schema.Types.ObjectId, ref: "Toy" }],
  // Système d'avis : moyenne et nombre total d'avis
  rating: { type: Number, default: null }, // null signifie "aucun avis"
  reviewsCount: { type: Number, default: 0 },
});

// Ajouter une méthode pour gérer les favoris
userSchema.methods.toggleFavorite = async function (toyId) {
  if (!toyId) throw new Error("ID de jouet requis");

  let toyObjectId;
  try {
    toyObjectId = new mongoose.Types.ObjectId(toyId);
  } catch (error) {
    throw new Error("ID de jouet invalide: format incorrect");
  }

  const index = this.favoriteToys.findIndex((t) => t.equals(toyObjectId));
  if (index > -1) {
    this.favoriteToys.splice(index, 1);
  } else {
    this.favoriteToys.push(toyObjectId);
  }
  return this.save();
};

// Création du modèle utilisateur
const User = mongoose.model("User", userSchema);

// Exportation du modèle
module.exports = User;
