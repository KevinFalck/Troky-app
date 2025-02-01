// routes/toys.js
const express = require("express");
const Toy = require("../models/Toy");
const mongoose = require("mongoose");
const router = express.Router();

// Route pour créer un nouveau jouet
router.post("/", async (req, res) => {
  try {
    const {
      name,
      description,
      imageUrl,
      location,
      latitude,
      longitude,
      owner,
    } = req.body;

    // Vérification simple des champs requis
    if (
      !name ||
      !description ||
      !imageUrl ||
      !location ||
      !latitude ||
      !longitude ||
      !owner
    ) {
      return res.status(400).json({ message: "Tous les champs sont requis" });
    }

    const toy = new Toy({
      name,
      description,
      imageUrl,
      location,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      coordinates: {
        type: "Point",
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
      owner,
    });

    await toy.save();
    res.status(201).json(toy);
  } catch (error) {
    res.status(500).json({
      message: "Erreur lors de la création du jouet",
      error: error.message,
    });
  }
});

// Route pour obtenir tous les jouets
router.get("/", async (req, res) => {
  try {
    const toys = await Toy.find();
    console.log("Toys récupérés :", toys); // Log pour vérifier le contenu
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

router.post("/by-ids", async (req, res) => {
  try {
    const { ids } = req.body;
    const objectIds = ids.map((id) => new mongoose.Types.ObjectId(id));
    const toys = await Toy.find({ _id: { $in: objectIds } });
    res.json(toys);
  } catch (error) {
    res.status(500).json({ message: "Erreur récupération jouets" });
  }
});

module.exports = router;
