// models/Toy.js
const mongoose = require("mongoose");
const User = require("./User");

const toySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    imageUrl: {
      type: String,
      required: true,
    },
    location: {
      type: String,
      required: true,
    },
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
    coordinates: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Ajouter un index géospatial
toySchema.index({ coordinates: "2dsphere" });

const Toy = mongoose.model("Toy", toySchema);

// Nettoyage des favoris après suppression
toySchema.post(["deleteOne", "findOneAndDelete"], async function (doc) {
  await User.updateMany(
    { favoriteToys: doc._id },
    { $pull: { favoriteToys: doc._id } }
  );
});

module.exports = Toy;
