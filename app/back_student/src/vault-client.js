// Vault Client - Gestion sécurisée des secrets
const http = require('http');

class VaultClient {
  constructor() {
    this.vaultAddr = process.env.VAULT_ADDR || 'http://vault:8200';
    this.vaultToken = process.env.VAULT_TOKEN || 'myroot';
    this.cache = new Map();
    this.cacheTimeout = 300000; // 5 minutes
  }

  /**
   * Récupère un secret depuis Vault
   */
  async getSecret(path) {
    // Check cache first
    const cached = this.cache.get(path);
    if (cached && cached.expires > Date.now()) {
      console.log(`[Vault] Using cached secret for: ${path}`);
      return cached.data;
    }

    try {
      const secret = await this.fetchFromVault(path);
      
      // Cache the result
      this.cache.set(path, {
        data: secret,
        expires: Date.now() + this.cacheTimeout
      });
      
      return secret;
    } catch (error) {
      console.error(`[Vault] Error fetching secret ${path}:`, error.message);
      
      // Fallback to environment variables if Vault is unavailable
      console.log('[Vault] Falling back to environment variables');
      return this.getFallbackSecrets(path);
    }
  }

  /**
   * Fetch secret from Vault API
   */
  fetchFromVault(path) {
    return new Promise((resolve, reject) => {
      const url = new URL(`/v1/secret/data/${path}`, this.vaultAddr);
      
      const options = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname,
        method: 'GET',
        headers: {
          'X-Vault-Token': this.vaultToken,
          'Content-Type': 'application/json'
        }
      };

      const req = http.request(options, (res) => {
        let data = '';
        
        res.on('data', chunk => {
          data += chunk;
        });
        
        res.on('end', () => {
          if (res.statusCode === 200) {
            try {
              const parsed = JSON.parse(data);
              resolve(parsed.data.data);
            } catch (e) {
              reject(new Error('Invalid JSON response from Vault'));
            }
          } else {
            reject(new Error(`Vault returned status ${res.statusCode}`));
          }
        });
      });

      req.on('error', reject);
      req.setTimeout(5000, () => {
        req.destroy();
        reject(new Error('Vault request timeout'));
      });
      
      req.end();
    });
  }

  /**
   * Fallback to environment variables if Vault is unavailable
   */
  getFallbackSecrets(path) {
    const fallbacks = {
      'database/mysql': {
        host: process.env.DB_HOST || 'db',
        port: process.env.DB_PORT || '3306',
        username: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || 'SecurePassword123!',
        database: process.env.DB_NAME || 'cia_database'
      },
      'api/config': {
        jwt_secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-me-in-production',
        node_env: process.env.NODE_ENV || 'production',
        api_port: process.env.API_PORT || '3000',
        api_host: process.env.API_HOST || '0.0.0.0'
      }
    };

    return fallbacks[path] || {};
  }

  /**
   * Get database configuration from Vault
   */
  async getDatabaseConfig() {
    const secrets = await this.getSecret('database/mysql');
    return {
      host: secrets.host,
      port: parseInt(secrets.port),
      user: secrets.username,
      password: secrets.password,
      database: secrets.database,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    };
  }

  /**
   * Get JWT secret from Vault
   */
  async getJwtSecret() {
    const secrets = await this.getSecret('api/config');
    return secrets.jwt_secret;
  }

  /**
   * Get API configuration from Vault
   */
  async getApiConfig() {
    return await this.getSecret('api/config');
  }

  /**
   * Clear cache
   */
  clearCache() {
    this.cache.clear();
    console.log('[Vault] Cache cleared');
  }
}

// Singleton instance
const vaultClient = new VaultClient();

module.exports = vaultClient;