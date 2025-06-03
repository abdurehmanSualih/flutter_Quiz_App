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

// JWT Middleware
const authenticateJWT = async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    console.log("No token provided");
    return res.status(401).json({ message: "No token provided" });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = await User.findById(decoded.userId);
    if (!req.user) {
      console.log("User not found for token:", decoded.userId);
      return res.status(401).json({ message: "User not found" });
    }
    next();
  } catch (err) {
    console.log("Invalid token:", err.message);
    return res.status(401).json({ message: "Invalid token" });
  }
};

// Admin API Key Middleware
const authenticateAdminKey = (req, res, next) => {
  const apiKey = req.headers["x-api-key"];
  if (apiKey && apiKey === ADMIN_API_KEY) {
    next();
  } else {
    console.log("Invalid or missing API key:", apiKey);
    res.status(401).json({ message: "Invalid or missing API key" });
  }
};

// Signup Endpoint
app.post("/api/auth/signup", async (req, res) => {
  try {
    console.log("Signup request:", req.body);
    const { email, password } = req.body;
    if (!email || !password) {
      console.log("Missing email or password");
      return res
        .status(400)
        .json({ message: "Email and password are required" });
    }
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log("User already exists:", email);
      return res.status(400).json({ message: "User already exists" });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ email, password: hashedPassword });
    await user.save();
    console.log("User created:", email);
    res.status(201).json({ message: "User created successfully" });
  } catch (err) {
    console.error("Signup error:", err);
    res
      .status(500)
      .json({ message: "Error creating user", error: err.message });
  }
});

// Signin Endpoint
app.post("/api/auth/signin", async (req, res) => {
  try {
    console.log("Signin request:", req.body);
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      console.log("Invalid credentials:", email);
      return res.status(401).json({ message: "Invalid credentials" });
    }
    const token = jwt.sign({ userId: user._id }, JWT_SECRET, {
      expiresIn: "1h",
    });
    console.log("Signin successful:", email);
    res.json({ token, user: { email: user.email } });
  } catch (err) {
    console.error("Signin error:", err);
    res.status(500).json({ message: "Error signing in", error: err.message });
  }
});

// Question Endpoints
app.get("/api/questions", async (req, res) => {
  try {
    console.log("Fetching questions");
    const questions = await Question.find();
    res.json(questions);
  } catch (err) {
    console.error("Fetch questions error:", err);
    res
      .status(500)
      .json({ message: "Error fetching questions", error: err.message });
  }
});

app.post(
  "/api/questions",
  authenticateJWT,
  authenticateAdminKey,
  async (req, res) => {
    try {
      console.log("Adding question:", req.body);
      const question = new Question(req.body);
      await question.save();
      res.status(201).json(question);
    } catch (err) {
      console.error("Add question error:", err);
      res
        .status(400)
        .json({ message: "Error adding question", error: err.message });
    }
  }
);

app.put(
  "/api/questions/:id",
  authenticateJWT,
  authenticateAdminKey,
  async (req, res) => {
    try {
      console.log("Updating question:", req.params.id, req.body);
      const question = await Question.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
      );
      if (!question) {
        console.log("Question not found:", req.params.id);
        return res.status(404).json({ message: "Question not found" });
      }
      res.json(question);
    } catch (err) {
      console.error("Update question error:", err);
      res
        .status(400)
        .json({ message: "Error updating question", error: err.message });
    }
  }
);

app.delete(
  "/api/questions/:id",
  authenticateJWT,
  authenticateAdminKey,
  async (req, res) => {
    try {
      console.log("Deleting question:", req.params.id);
      const question = await Question.findByIdAndDelete(req.params.id);
      if (!question) {
        console.log("Question not found:", req.params.id);
        return res.status(404).json({ message: "Question not found" });
      }
      res.status(204).send();
    } catch (err) {
      console.error("Delete question error:", err);
      res
        .status(400)
        .json({ message: "Error deleting question", error: err.message });
    }
  }
);

// Start Server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
