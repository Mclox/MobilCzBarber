const fs = require('fs');
const path = require('path');

const backendDir = 'C:/Users/DELL/Documents/BackendBarberSiteOficial/BackendOficial';

function searchInDir(dir, pattern) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (file === 'node_modules' || file === '.git' || file === 'dist' || file === 'build') continue;
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      searchInDir(fullPath, pattern);
    } else if (file.endsWith('.js') || file.endsWith('.json') || file.endsWith('.env')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      if (content.toLowerCase().includes(pattern.toLowerCase())) {
        console.log(`\n=== FOUND IN: ${fullPath} ===`);
        const lines = content.split('\n');
        lines.forEach((line, idx) => {
          if (line.toLowerCase().includes(pattern.toLowerCase())) {
            console.log(`  L${idx + 1}: ${line.trim()}`);
          }
        });
      }
    }
  }
}

console.log("Searching for 'app-version' or 'version' in backend files...");
searchInDir(backendDir, 'app-version');
searchInDir(backendDir, 'version_code');
