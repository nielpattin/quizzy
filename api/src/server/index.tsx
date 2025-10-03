import { serve } from "bun";
import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import index from "../client/index.html";

if (getApps().length === 0) {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const serviceAccount = await Bun.file(process.env.FIREBASE_SERVICE_ACCOUNT_PATH).json();
    initializeApp({
      credential: cert(serviceAccount)
    });
  }
  else {
    console.warn("⚠️  Firebase Admin SDK not initialized. Set FIREBASE_SERVICE_ACCOUNT_PATH.");
  }
}

const auth = getAuth();

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const server = serve({
  routes: {
    "/*": index,
    "/api/auth/verify": {
      async POST(req) {
        try {
          const authHeader = req.headers.get("Authorization");
          if (!authHeader?.startsWith("Bearer ")) {
            return Response.json({ error: "Missing or invalid authorization header" }, { status: 401, headers: corsHeaders });
          }

          const idToken = authHeader.split("Bearer ")[1];
          if (!idToken) {
            return Response.json({ error: "Invalid token format" }, { status: 401, headers: corsHeaders });
          }
          const decodedToken = await auth.verifyIdToken(idToken);
          
          return Response.json({
            uid: decodedToken.uid,
            email: decodedToken.email,
          }, { headers: corsHeaders });
        } catch (error) {
          return Response.json({ error: "Invalid token" }, { status: 401, headers: corsHeaders });
        }
      },
      async OPTIONS(req) {
        return new Response(null, { status: 204, headers: corsHeaders });
      },
    },

    "/api/data": {
      async GET(req) {
        try {
          const authHeader = req.headers.get("Authorization");
          if (!authHeader?.startsWith("Bearer ")) {
            return Response.json({ error: "Missing or invalid authorization header" }, { status: 401, headers: corsHeaders });
          }

          const idToken = authHeader.split("Bearer ")[1];
          if (!idToken) {
            return Response.json({ error: "Invalid token format" }, { status: 401, headers: corsHeaders });
          }

          const decodedToken = await auth.verifyIdToken(idToken);
          
          return Response.json({
            message: `Hello ${decodedToken.email}! This is protected data.`,
            uid: decodedToken.uid,
            timestamp: new Date().toISOString(),
          }, { headers: corsHeaders });
        } catch (error) {
          return Response.json({ error: "Invalid token" }, { status: 401, headers: corsHeaders });
        }
      },
      async OPTIONS(req) {
        return new Response(null, { status: 204, headers: corsHeaders });
      },
    },
  },

  development: process.env.NODE_ENV !== "production" && {
    hmr: true,
    console: true,
  },
});

console.log(`🚀 Server running at ${server.url}`);
console.log(`🔥 Firebase Auth initialized: ${getApps().length > 0 ? "✅" : "❌"}`);
