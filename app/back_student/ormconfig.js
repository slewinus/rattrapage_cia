module.exports = {
   type: "mysql",
   host: process.env.DB_HOST || "db",
   port: process.env.DB_PORT || 3306,
   username: process.env.DB_USER || "root",
   password: process.env.DB_PASSWORD || "SecurePassword123!",
   database: process.env.DB_NAME || "cia_database",
   synchronize: true,
   logging: false,
   migrationsRun: true,
   "entities": [
      process.env.NODE_ENV === 'production' ? "build/entity/**/*.js" : "src/entity/**/*.ts"
   ],
   "migrations": [
      process.env.NODE_ENV === 'production' ? "build/migration/**/*.js" : "src/migration/**/*.ts"
   ],
   "subscribers": [
      process.env.NODE_ENV === 'production' ? "build/subscriber/**/*.js" : "src/subscriber/**/*.ts"
   ],
   "cli": {
      "entitiesDir": "src/entity",
      "migrationsDir": "src/migration",
      "subscribersDir": "src/subscriber"
   }
};
