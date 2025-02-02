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

// Déplacer les hooks AVANT la création du modèle
toySchema.post("save", async function (doc, next) {
  try {
    console.log("🔄 Déclenchement hook post-save pour jouet:", doc._id);
    console.log(
      "🔍 Owner ID:",
      doc.owner,
      "Type:",
      typeof doc.owner,
      "Valid:",
      mongoose.isValidObjectId(doc.owner)
    );

    const result = await mongoose
      .model("User")
      .findByIdAndUpdate(
        doc.owner,
        { $inc: { totalListings: 1 } },
        { new: true, runValidators: true }
      );

    console.log("✅ Résultat mise à jour utilisateur:", result);
    next();
  } catch (error) {
    console.error("❌ Erreur hook post-save:", error);
    next(error);
  }
});

// Modifier le hook existant pour les suppressions
toySchema.post(["deleteOne", "findOneAndDelete"], async function (doc) {
  await User.findByIdAndUpdate(
    doc.owner,
    { $inc: { totalListings: -1 } },
    { new: true }
  );
});

const Toy = mongoose.model("Toy", toySchema);

module.exports = Toy;
