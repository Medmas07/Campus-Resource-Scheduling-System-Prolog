import express from 'express';
import { execFile } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const app = express();
const port = 3001;

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  next();
});

app.get('/api/solve', (req, res) => {
  execFile(
    'swipl',
    ['-q', '-s', 'main.pl', '-g', 'print_solution_json', '-t', 'halt'],
    { cwd: projectRoot, timeout: 30000 },
    (error, stdout, stderr) => {
      if (error) {
        res.status(500).json({
          error: 'Prolog solver failed',
          details: stderr || error.message
        });
        return;
      }

      try {
        res.json(JSON.parse(stdout));
      } catch (parseError) {
        res.status(500).json({
          error: 'Solver returned invalid JSON',
          details: parseError.message,
          raw: stdout
        });
      }
    }
  );
});

app.listen(port, () => {
  console.log(`Scheduler backend listening on http://localhost:${port}`);
});
