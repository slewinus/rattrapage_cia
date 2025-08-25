import express from "express";
import pkg from "pg";
const { Pool } = pkg;

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function init() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS items(
      id SERIAL PRIMARY KEY,
      label TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);
}
init().catch(console.error);

app.get("/health", (req,res)=> res.json({ok:true, ts:Date.now()}));

app.get("/items", async (req,res)=>{
  const {rows} = await pool.query("SELECT * FROM items ORDER BY id DESC");
  res.json(rows);
});

app.post("/items", async (req,res)=>{
  const label = req.body?.label ?? "no-label";
  const {rows} = await pool.query("INSERT INTO items(label) VALUES($1) RETURNING *",[label]);
  res.status(201).json(rows[0]);
});

app.listen(PORT, ()=> console.log("API listening on", PORT));