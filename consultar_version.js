const fs = require('fs');
const path = require('path');

const backendDir = 'C:/Users/DELL/Documents/BackendBarberSiteOficial/BackendOficial';

function searchFiles(dir) {
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    if (item === 'node_modules' || item === '.git') continue;
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      searchFiles(fullPath);
    } else if (item.endsWith('.js')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      if (content.includes('app_version') || content.includes('app-version')) {
        console.log('=== FILE:', fullPath);
        console.log(content);
      }
    }
  }
}

searchFiles(backendDir);
