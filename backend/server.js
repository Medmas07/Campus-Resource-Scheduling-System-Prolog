import express from 'express';
import { execFile } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { generateFactsFile } from './generateFacts.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const frontendDist = path.join(projectRoot, 'frontend', 'dist');

const app = express();
const port = process.env.PORT || 3001;
const generatedFactsPath = path.join(projectRoot, 'generated_facts.pl');

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  next();
});

app.use(express.json({ limit: '1mb' }));

app.use((error, req, res, next) => {
  if (error instanceof SyntaxError && 'body' in error) {
    res.status(400).json({
      error: 'Invalid JSON body',
      details: error.message
    });
    return;
  }

  next(error);
});

function runProlog(files, res) {
  const args = ['-q'];

  files.forEach((file) => {
    args.push('-s', file);
  });

  args.push('-g', 'main:print_solution_json', '-t', 'halt');

  execFile('swipl', args, { cwd: projectRoot, timeout: 30000 }, (error, stdout, stderr) => {
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
  });
}

app.get('/api/solve', (req, res) => {
  runProlog(['main.pl'], res);
});

app.post('/api/solve-dataset', async (req, res) => {
  try {
    await generateFactsFile(req.body, generatedFactsPath);
    runProlog(['generated_facts.pl', 'constraints.pl', 'optimization.pl', 'main.pl'], res);
  } catch (error) {
    res.status(400).json({
      error: 'Invalid dataset',
      details: error.message
    });
  }
});

app.use(express.static(frontendDist));

app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(frontendDist, 'index.html'));
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Scheduler app listening on http://0.0.0.0:${port}`);
});
