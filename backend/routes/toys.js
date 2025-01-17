// routes/toys.js
const express = require("express");
const Toy = require("../models/Toy");
const router = express.Router();

// Route pour créer un nouveau jouet
router.post("/", async (req, res) => {
  const { name, description, imageUrl, location, latitude, longitude } =
    req.body;

  const missingFields = [
    "name",
    "description",
    "imageUrl",
    "location",
    "latitude",
    "longitude",
  ].filter((field) => !req.body[field]);
  if (missingFields.length > 0) {
    return res.status(400).json({
      message: "Champs manquants: " + missingFields.join(", "),
      receivedData: req.body,
    });
  }

  const toy = new Toy({
    name,
    description,
    imageUrl,
    location,
    coordinates: {
      type: "Point",
      coordinates: [parseFloat(longitude), parseFloat(latitude)],
    },
    favorites: false,
  });

  try {
    const savedToy = await toy.save();
    res.status(201).json(savedToy);
  } catch (error) {
    console.error("Erreur lors de la création du jouet:", error);
    res.status(500).json({ message: "Erreur lors de la création du jouet" });
  }
});

// Route pour obtenir tous les jouets
router.get("/", async (req, res) => {
  try {
    const toys = await Toy.find();
    res.json(toys);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Erreur lors de la récupération des jouets" });
  }
});

// Route pour obtenir les jouets à proximité
router.get("/nearby", async (req, res) => {
  const { latitude, longitude, maxDistance = 15000 } = req.query;

  try {
    const toys = await Toy.find({
      coordinates: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(longitude), parseFloat(latitude)],
          },
          $maxDistance: parseInt(maxDistance),
        },
      },
    });
    res.json(toys);
  } catch (error) {
    res.status(500).json({
      message: "Erreur lors de la récupération des jouets à proximité",
    });
  }
});

// Route pour mettre à jour les favoris
router.patch("/:id/favorites", async (req, res) => {
  const { id } = req.params;
  const { favorites } = req.body;

  try {
    const updatedToy = await Toy.findByIdAndUpdate(
      id,
      { favorites },
      { new: true }
    );
    if (!updatedToy) {
      return res.status(404).json({ message: "Jouet non trouvé" });
    }
    res.json(updatedToy);
  } catch (error) {
    res
      .status(400)
      .json({ message: "Erreur lors de la mise à jour des favoris" });
  }
});

// Route pour supprimer un jouet
router.delete("/:id", async (req, res) => {
  const { id } = req.params;

  try {
    const deletedToy = await Toy.findByIdAndDelete(id);
    if (!deletedToy) {
      return res.status(404).json({ message: "Jouet non trouvé" });
    }
    res.json({ message: "Jouet supprimé avec succès" });
  } catch (error) {
    res.status(500).json({ message: "Erreur lors de la suppression du jouet" });
  }
});

module.exports = router;
