const path = require('path');
const backendDir = 'C:/Users/DELL/Documents/BackendBarberSiteOficial/BackendOficial';

const dotenv = require(path.join(backendDir, 'node_modules/dotenv'));
dotenv.config({ path: path.join(backendDir, '.env') });

console.log("⏳ Conectando a PostgreSQL en Render...");

const { Pool } = require(path.join(backendDir, 'node_modules/pg'));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function cleanDatabase() {
  let client;
  try {
    client = await pool.connect();
    console.log("✅ Conexión establecida con éxito.");

    // Obtener todas las tablas existentes en la BD
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    `);
    const existingTables = tablesRes.rows.map(r => r.table_name.toLowerCase());
    console.log("📋 Tablas encontradas en la BD:", existingTables.join(", "));

    // Lista de tablas objetivo en orden seguro (o usando CASCADE / TRUNCATE)
    const targetTables = [
      'detalles_venta',
      'detalle_ventas',
      'ventas',
      'pagos',
      'citas',
      'disponibilidad_barberos',
      'servicios',
      'productos',
      'proveedores'
    ];

    for (const table of targetTables) {
      if (existingTables.includes(table.toLowerCase())) {
        try {
          const res = await client.query(`DELETE FROM "${table}"`);
          console.log(`- Tabla '${table}': ${res.rowCount} registros eliminados.`);
        } catch (err) {
          try {
            // Intentar TRUNCATE con CASCADE si hay restricciones de clave foránea
            await client.query(`TRUNCATE TABLE "${table}" CASCADE`);
            console.log(`- Tabla '${table}': Vaciada con TRUNCATE CASCADE.`);
          } catch (e2) {
            console.log(`- Tabla '${table}': ${e2.message}`);
          }
        }
      }
    }

    // Limpieza de usuarios
    if (existingTables.includes('usuarios')) {
      try {
        const deleteUsers = await client.query("DELETE FROM usuarios WHERE LOWER(email) != 'miguelangelcardonalopez0@gmail.com'");
        console.log(`- Usuarios de prueba eliminados: ${deleteUsers.rowCount}`);

        const updateAdmin = await client.query("UPDATE usuarios SET id_rol = 1 WHERE LOWER(email) = 'miguelangelcardonalopez0@gmail.com'");
        console.log(`- Admin verificado/actualizado: ${updateAdmin.rowCount} fila(s).`);

        const adminCheck = await client.query("SELECT id_usuario, email, nombre, id_rol FROM usuarios");
        console.log("\n👤 Usuario Administrador conservado:");
        console.log(adminCheck.rows);
      } catch (err) {
        console.log(`- Error procesando usuarios: ${err.message}`);
      }
    }

    console.log("\n=============================================");
    console.log("🎉 ¡LIMPIEZA COMPLETADA CON ÉXITO!");
    console.log("=============================================");
  } catch (e) {
    console.error("❌ Error al ejecutar la limpieza:", e.message);
  } finally {
    if (client) client.release();
    await pool.end();
    process.exit(0);
  }
}

cleanDatabase();
