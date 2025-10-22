import { Database } from 'bun:sqlite';
import { resolve } from 'path';

export type SummaryMode = 'realtime' | 'on-demand' | 'disabled';

export interface Settings {
  summaryMode: SummaryMode;
}

const dbPath = resolve(import.meta.dir, '../data/settings.db');
const db = new Database(dbPath);

// Initialize settings table
db.run(`
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
`);

// Initialize default settings if not exists
// Default to 'realtime' if API key exists, otherwise 'on-demand'
const defaultSettings: Settings = {
  summaryMode: process.env.ANTHROPIC_API_KEY ? 'realtime' : 'on-demand'
};

for (const [key, value] of Object.entries(defaultSettings)) {
  const existing = db.query('SELECT value FROM settings WHERE key = ?').get(key);
  if (!existing) {
    db.run('INSERT INTO settings (key, value) VALUES (?, ?)', [key, value]);
  }
}

export function getSettings(): Settings {
  const summaryMode = db.query('SELECT value FROM settings WHERE key = ?')
    .get('summaryMode') as { value: string } | null;

  return {
    summaryMode: (summaryMode?.value || 'on-demand') as SummaryMode
  };
}

export function updateSettings(settings: Partial<Settings>): Settings {
  for (const [key, value] of Object.entries(settings)) {
    db.run('UPDATE settings SET value = ? WHERE key = ?', [value, key]);
  }

  return getSettings();
}

export function hasAnthropicApiKey(): boolean {
  return !!process.env.ANTHROPIC_API_KEY;
}
