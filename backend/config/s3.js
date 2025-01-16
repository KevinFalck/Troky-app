const { S3Client } = require("@aws-sdk/client-s3");
const multer = require("multer");
const multerS3 = require("multer-s3");
require("dotenv").config();

// Vérifiez ces valeurs dans votre console AWS
console.log("AWS Config:", {
  region: process.env.AWS_REGION,
  bucket: process.env.AWS_BUCKET_NAME,
});

const s3Client = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: process.env.AWS_BUCKET_NAME,
    metadata: function (req, file, cb) {
      console.log("Metadata function called with file:", file);
      cb(null, { fieldName: file.fieldname });
    },
    key: function (req, file, cb) {
      console.log("Key function called with file:", file);
      const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
      const key = "toys/" + uniqueSuffix + "-" + file.originalname;
      console.log("Generated key:", key);
      cb(null, key);
    },
    contentType: multerS3.AUTO_CONTENT_TYPE,
  }),
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
});

// Test de connexion au démarrage
const testConnection = async () => {
  try {
    console.log("Testing S3 connection...");
    const { ListObjectsV2Command } = require("@aws-sdk/client-s3");
    const command = new ListObjectsV2Command({
      Bucket: process.env.AWS_BUCKET_NAME,
      MaxKeys: 1,
    });
    const response = await s3Client.send(command);
    console.log("S3 connection successful:", response);
  } catch (error) {
    console.error("S3 connection error:", error);
    console.error("Error details:", {
      code: error.code,
      message: error.message,
      region: process.env.AWS_REGION,
      bucket: process.env.AWS_BUCKET_NAME,
    });
  }
};

testConnection();

module.exports = { s3Client, upload };
