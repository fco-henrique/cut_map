/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access */
import { execSync, spawnSync } from 'child_process';
import { randomUUID } from 'crypto';
import * as net from 'net';
import { Client } from 'pg';

export class DockerPostgresHelper {
  private containerName: string;
  private port: number;
  private isRunning = false;
  private originalEnv = new Map<string, string | undefined>();

  private setEnv(key: string, value: string): void {
    if (!this.originalEnv.has(key)) {
      this.originalEnv.set(key, process.env[key]);
    }
    process.env[key] = value;
  }

  restoreEnv(): void {
    for (const [key, value] of this.originalEnv.entries()) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
    this.originalEnv.clear();
  }

  private async getFreeLoopbackPort(): Promise<number> {
    return new Promise((resolve, reject) => {
      const srv = net.createServer();
      srv.listen(0, '127.0.0.1', () => {
        const address = srv.address() as net.AddressInfo;
        const port = address.port;
        srv.close(err => {
          if (err) reject(err);
          else resolve(port);
        });
      });
      srv.on('error', reject);
    });
  }

  async start(): Promise<void> {
    this.port = await this.getFreeLoopbackPort();
    const suffix = randomUUID().replace(/-/g, '').slice(0, 10);
    this.containerName = `cutmap-e2e-${suffix}`;

    // Ephemeral credentials and database name (never logged)
    const ephemeralUser = `usr_${suffix}`;
    const ephemeralPassword = `pwd_${randomUUID().replace(/-/g, '')}`;
    const ephemeralDb = `db_${suffix}`;

    // Launch disposable container on loopback port without persistent volumes
    const dockerCmd = [
      'run',
      '-d',
      '--name',
      this.containerName,
      '-e',
      `POSTGRES_DB=${ephemeralDb}`,
      '-e',
      `POSTGRES_USER=${ephemeralUser}`,
      '-e',
      `POSTGRES_PASSWORD=${ephemeralPassword}`,
      '-p',
      `127.0.0.1:${this.port}:5432`,
      'postgres:16-alpine',
    ];

    const runResult = spawnSync('docker', dockerCmd, {
      encoding: 'utf-8',
      windowsHide: true,
    });

    if (runResult.status !== 0) {
      throw new Error(
        `Falha ao iniciar contêiner Postgres efêmero. Código: ${runResult.status}`,
      );
    }

    this.isRunning = true;

    // Register process cleanup handler
    const cleanup = () => {
      try {
        this.stop();
      } catch {
        // ignore errors during emergency exit
      }
    };
    process.once('exit', cleanup);
    process.once('SIGINT', cleanup);
    process.once('SIGTERM', cleanup);

    try {
      // Wait for PostgreSQL to be ready
      const startDeadline = Date.now() + 30000;
      let connected = false;

      while (Date.now() < startDeadline) {
        try {
          const client = new Client({
            host: '127.0.0.1',
            port: this.port,
            user: ephemeralUser,
            password: ephemeralPassword,
            database: ephemeralDb,
            connectionTimeoutMillis: 1000,
          });
          await client.connect();
          await client.end();
          connected = true;
          break;
        } catch {
          await new Promise(r => setTimeout(r, 250));
        }
      }

      if (!connected) {
        throw new Error(
          'PostgreSQL efêmero não respondeu dentro do limite de tempo',
        );
      }

      // Configure isolation barrier in environment BEFORE ORM initializes
      this.setEnv('DATABASE_TYPE', 'postgres');
      this.setEnv('DATABASE_HOST', '127.0.0.1');
      this.setEnv('DATABASE_PORT', String(this.port));
      this.setEnv('DATABASE_USERNAME', ephemeralUser);
      this.setEnv('DATABASE_PASSWORD', ephemeralPassword);
      this.setEnv('DATABASE_DATABASE', ephemeralDb);
      this.setEnv('DATABASE_AUTOLOADENTITIES', 'true');
      this.setEnv('DATABASE_SYNCHRONIZE', 'true');

      // Ephemeral JWT secrets for regression tests
      this.setEnv(
        'JWT_SECRET',
        'ephemeral-jwt-secret-for-q1-regression-testing-32-chars',
      );
      this.setEnv(
        'JWT_REFRESH_SECRET',
        'ephemeral-jwt-refresh-secret-for-q1-regression-32-chars',
      );
      this.setEnv(
        'JWT_RESET_SECRET',
        'ephemeral-jwt-reset-secret-for-q1-regression-32-chars',
      );
      this.setEnv('JWT_TOKEN_AUDIENCE', 'cut-map-e2e');
      this.setEnv('JWT_TOKEN_ISSUER', 'cut-map-e2e');
      this.setEnv('JWT_TTL', '3600');

      // Dummy mail configuration
      this.setEnv('MAIL_HOST', '127.0.0.1');
      this.setEnv('MAIL_PORT', '1025');
      this.setEnv('MAIL_USER', 'dummy@cutmap.local');
      this.setEnv('MAIL_PASS', 'dummy_pass');
    } catch (err) {
      this.stop();
      throw err;
    }
  }

  stop(): void {
    this.restoreEnv();
    if (!this.isRunning || !this.containerName) return;

    try {
      execSync(`docker rm -f ${this.containerName}`, { stdio: 'ignore' });
    } catch {
      // ignore teardown error
    } finally {
      this.isRunning = false;
    }
  }

  getPort(): number {
    return this.port;
  }
}
