// Configuration de la base de données avec Vault
const mysql = require('mysql2/promise');
const vaultClient = require('../vault-client');

let pool = null;

/**
 * Initialize database connection with Vault secrets
 */
async function initializeDatabase() {
  try {
    console.log('[DB] Fetching database credentials from Vault...');
    
    // Get database config from Vault
    const dbConfig = await vaultClient.getDatabaseConfig();
    
    console.log('[DB] Connecting to database:', {
      host: dbConfig.host,
      port: dbConfig.port,
      database: dbConfig.database,
      user: dbConfig.user
      // Ne pas logger le mot de passe !
    });
    
    // Create connection pool
    pool = mysql.createPool(dbConfig);
    
    // Test connection
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    
    console.log('[DB] Database connected successfully using Vault secrets');
    
    return pool;
  } catch (error) {
    console.error('[DB] ❌ Failed to connect to database:', error.message);
    
    // Retry with environment variables as fallback
    console.log('[DB] Attempting connection with environment variables...');
    
    const fallbackConfig = {
      host: process.env.DB_HOST || 'db',
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || 'SecurePassword123!',
      database: process.env.DB_NAME || 'cia_database',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    };
    
    pool = mysql.createPool(fallbackConfig);
    
    // Test fallback connection
    const connection = await pool.getConnection();
    await connection.ping();
    connection.release();
    
    console.log('[DB] Database connected using fallback configuration');
    
    return pool;
  }
}

/**
 * Get database pool instance
 */
function getPool() {
  if (!pool) {
    throw new Error('Database not initialized. Call initializeDatabase() first.');
  }
  return pool;
}

/**
 * Close database connections
 */
async function closeDatabase() {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('[DB] Database connections closed');
  }
}

module.exports = {
  initializeDatabase,
  getPool,
  closeDatabase
};