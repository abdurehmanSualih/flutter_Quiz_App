const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const dotenv = require("dotenv");

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || "your-jwt-secret-key";
const ADMIN_API_KEY = process.env.ADMIN_API_KEY || "your-secret-admin-key";
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/quiz_db";

// CORS configuration (temporary: allow all origins for testing)
app.use(cors({ origin: "*", credentials: true }));
// For production, use:
// const corsOptions = {
//   origin: (origin, callback) => {
//     const allowedOrigins = [
//       'http://localhost:8080',
//       'http://localhost:8000',
//       'http://localhost:4200',
//     ];
//     if (!origin || allowedOrigins.includes(origin)) {
//       callback(null, true);
//     } else {
//       console.log('Blocked CORS request from:', origin);
//       callback(new Error('Not allowed by CORS'));
//     }
//   },
//   credentials: true,
//   optionsSuccessStatus: 200
// };
// app.use(cors(corsOptions));

// Log incoming requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

app.use(express.json());

mongoose
  .connect(MONGODB_URI)
  .then(() => {
    console.log(
      "Connected to MongoDB:",
      MONGODB_URI.replace(/:[^@]+@/, ":<password>@")
    );
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err);
  });


  // Question Schema
const questionSchema = new mongoose.Schema(
  {
    question: { type: String, required: true },
    options: { type: [String], required: true },
    correctAnswer: { type: String, required: true },
    explanation: { type: String, required: true },
  },
  { timestamps: true }
);

const Question = mongoose.model("Question", questionSchema);

// User Schema
const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
  },
  { timestamps: true }
);

const User = mongoose.model("User", userSchema);