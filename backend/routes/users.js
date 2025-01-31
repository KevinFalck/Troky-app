const express = require("express");
const router = express.Router();
const User = require("../models/User");
const mongoose = require("mongoose");
const Toy = require("../models/Toy");

router.patch("/:id/favorites", async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    const toyId = mongoose.Types.ObjectId.isValid(req.body.toyId)
      ? new mongoose.Types.ObjectId(req.body.toyId)
      : req.body.toyId;

    const index = user.favoriteToys.findIndex((id) => id.equals(toyId)); // Comparaison ObjectId
    if (index > -1) {
      user.favoriteToys.splice(index, 1);
    } else {
      user.favoriteToys.push(toyId); // Stockage en ObjectId
    }

    await user.save();
    res.json(user.favoriteToys.map((id) => id.toString())); // Envoie uniquement la liste des IDs
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
