const path = require('path');
const backendDir = 'C:/Users/DELL/Documents/BackendBarberSiteOficial/BackendOficial';

const dotenv = require(path.join(backendDir, 'node_modules/dotenv'));
dotenv.config({ path: path.join(backendDir, '.env') });

const { Pool } = require(path.join(backendDir, 'node_modules/pg'));
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function consultarUsuarios() {
  try {
    console.log("⏳ Conectando a PostgreSQL en Render...\n");
    const res = await pool.query(`
      SELECT 
        u.id_usuario, 
        u.nombre, 
        u.email, 
        u.id_rol,
        r.nombre_rol AS rol
      FROM usuarios u
      LEFT JOIN roles r ON u.id_rol = r.id_rol
      ORDER BY u.id_usuario ASC
    `);

    console.log("📋 --- LISTA DE USUARIOS REGISTRADOS ---");
    console.table(res.rows);
  } catch (err) {
    console.error("❌ Error al consultar la base de datos:", err.message);
  } finally {
    await pool.end();
  }
}

consultarUsuarios();
