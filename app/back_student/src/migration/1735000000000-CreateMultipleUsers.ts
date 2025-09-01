import { MigrationInterface, QueryRunner, getRepository } from "typeorm";
import { User } from "../entity/User";

export class CreateMultipleUsers1735000000000 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        const userRepository = getRepository(User);
        
        const users = [
            { username: "admin", password: "admin", role: "ADMIN" },
            { username: "manager", password: "manager123", role: "USER" },
            { username: "developer", password: "dev123", role: "USER" },
            { username: "test", password: "test123", role: "USER" },
            { username: "guest", password: "guest123", role: "USER" }
        ];
        
        for (const userData of users) {
            // Check if user already exists
            const existingUser = await userRepository.findOne({ username: userData.username });
            
            if (!existingUser) {
                const user = new User();
                user.username = userData.username;
                user.password = userData.password;
                user.hashPassword();
                user.role = userData.role;
                
                await userRepository.save(user);
                console.log(`Created user: ${userData.username}`);
            } else {
                console.log(`User already exists: ${userData.username}`);
            }
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DELETE FROM user WHERE username IN ('admin', 'manager', 'developer', 'test', 'guest')`);
    }
}