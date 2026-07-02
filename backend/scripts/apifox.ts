import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const PROJECT_ID = process.env.APIFOX_PROJECT_ID ?? '8525101';
const ACCESS_TOKEN = process.env.APIFOX_ACCESS_TOKEN;
const OPENAPI_FILE = resolve(
  process.cwd(),
  process.env.APIFOX_OPENAPI_FILE ?? '.generated/openapi.json',
);

type Mode = 'import' | 'test';

function sanitizeOutput(value: string): string {
  return ACCESS_TOKEN ? value.split(ACCESS_TOKEN).join('***') : value;
}

function ensureApifoxCli(): void {
  const result = spawnSync('apifox', ['--version'], { stdio: 'ignore' });

  if (result.error) {
    throw new Error(
      '未检测到 Apifox CLI。请先按 Apifox 官方文档安装 CLI，然后重试。',
    );
  }
}

function runApifox(args: string[], sensitive = false): void {
  const result = spawnSync('apifox', args, {
    encoding: 'utf8',
    stdio: sensitive ? 'pipe' : 'inherit',
  });

  if (result.error) {
    throw result.error;
  }

  if (sensitive) {
    const stdout = sanitizeOutput(result.stdout ?? '');
    const stderr = sanitizeOutput(result.stderr ?? '');

    if (stdout.trim()) {
      console.log(stdout.trim());
    }

    if (stderr.trim()) {
      console.error(stderr.trim());
    }
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function loginWhenTokenProvided(): void {
  if (!ACCESS_TOKEN) {
    console.warn(
      '未设置 APIFOX_ACCESS_TOKEN，将使用当前 Apifox CLI 登录态执行命令。',
    );
    return;
  }

  runApifox(['login', '--with-token', ACCESS_TOKEN], true);
}

function importOpenApi(): void {
  if (!existsSync(OPENAPI_FILE)) {
    throw new Error(
      `OpenAPI 文件不存在：${OPENAPI_FILE}。请先运行 pnpm openapi:export。`,
    );
  }

  loginWhenTokenProvided();
  runApifox([
    'import',
    '--project',
    PROJECT_ID,
    '--format',
    'openapi',
    '--file',
    OPENAPI_FILE,
  ]);
}

function runTestSuite(): void {
  const testSuiteId = process.env.APIFOX_TEST_SUITE_ID;
  const environmentId = process.env.APIFOX_ENV_ID;

  if (!testSuiteId || !environmentId) {
    throw new Error(
      '运行 Apifox 测试套件需要设置 APIFOX_TEST_SUITE_ID 和 APIFOX_ENV_ID。',
    );
  }

  loginWhenTokenProvided();
  runApifox([
    'test-suite',
    'run',
    testSuiteId,
    '--project',
    PROJECT_ID,
    '--environment',
    environmentId,
  ]);
}

function main(): void {
  const mode = process.argv[2] as Mode | undefined;

  ensureApifoxCli();

  if (mode === 'import') {
    importOpenApi();
    return;
  }

  if (mode === 'test') {
    runTestSuite();
    return;
  }

  throw new Error('用法错误：请使用 pnpm apifox:import 或 pnpm apifox:test。');
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}
