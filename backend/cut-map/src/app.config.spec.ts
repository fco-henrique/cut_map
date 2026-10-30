import appConfig from './app.config';

describe('configuração do banco', () => {
  const originalAutoLoad = process.env.DATABASE_AUTOLOADENTITIES;
  const originalSynchronize = process.env.DATABASE_SYNCHRONIZE;

  afterAll(() => {
    if (originalAutoLoad === undefined) {
      delete process.env.DATABASE_AUTOLOADENTITIES;
    } else {
      process.env.DATABASE_AUTOLOADENTITIES = originalAutoLoad;
    }
    if (originalSynchronize === undefined) {
      delete process.env.DATABASE_SYNCHRONIZE;
    } else {
      process.env.DATABASE_SYNCHRONIZE = originalSynchronize;
    }
  });

  it('respeita o valor false no arquivo de ambiente', () => {
    process.env.DATABASE_AUTOLOADENTITIES = 'false';
    process.env.DATABASE_SYNCHRONIZE = 'false';

    expect(appConfig().database.autoLoadEntities).toBe(false);
    expect(appConfig().database.synchronize).toBe(false);
  });

  it('habilita as opções somente com true', () => {
    process.env.DATABASE_AUTOLOADENTITIES = 'true';
    process.env.DATABASE_SYNCHRONIZE = 'true';

    expect(appConfig().database.autoLoadEntities).toBe(true);
    expect(appConfig().database.synchronize).toBe(true);
  });
});
