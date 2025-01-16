// routes/toys.js
const express = require("express");
const Toy = require("../models/Toy");
const router = express.Router();

// Route pour créer un nouveau jouet
router.post("/", async (req, res) => {
  try {
    console.log("Données reçues:", req.body);
    const { name, description, imageUrl, location, latitude, longitude } =
      req.body;

    // Vérification des champs requis avec plus de détails
    const missingFields = [];
    if (!name) missingFields.push("name");
    if (!description) missingFields.push("description");
    if (!imageUrl) missingFields.push("imageUrl");
    if (!location) missingFields.push("location");
    if (!latitude) missingFields.push("latitude");
    if (!longitude) missingFields.push("longitude");

    if (missingFields.length > 0) {
      console.log("Champs manquants:", missingFields);
      return res.status(400).json({
        message: "Champs manquants: " + missingFields.join(", "),
        receivedData: req.body,
      });
    }

    console.log("Création du jouet avec les données:", {
      name,
      description,
      imageUrl,
      location,
      coordinates: {
        type: "Point",
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
    });

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

    const savedToy = await toy.save();
    console.log("Jouet sauvegardé avec succès:", savedToy);
    res.status(201).json(savedToy);
  } catch (error) {
    console.error("Erreur détaillée lors de la création du jouet:", error);
    res.status(400).json({
      message: error.message,
      stack: error.stack,
      details: "Erreur lors de la création du jouet",
    });
  }
});

// Route pour obtenir tous les jouets
router.get("/", async (req, res) => {
  try {
    const toys = await Toy.find();
    res.json(toys);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Route pour obtenir les jouets à proximité
router.get("/nearby", async (req, res) => {
  try {
    const { latitude, longitude, maxDistance = 15000 } = req.query; // maxDistance en mètres

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
    res.status(500).json({ message: error.message });
  }
});

// Route pour mettre à jour les favoris
router.patch("/:id/favorites", async (req, res) => {
  try {
    const { id } = req.params;
    const { favorites } = req.body;

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
    res.status(400).json({ message: error.message });
  }
});

// Route pour supprimer un jouet
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const deletedToy = await Toy.findByIdAndDelete(id);

    if (!deletedToy) {
      return res.status(404).json({ message: "Jouet non trouvé" });
    }

    res.json({ message: "Jouet supprimé avec succès" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
