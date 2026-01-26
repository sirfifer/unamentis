import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

export async function POST() {
  try {
    const response = await fetch(`${BACKEND_URL}/api/kb/sync-to-database`, {
      method: 'POST',
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: `Backend error: ${error}` }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error syncing to database:', error);
    return NextResponse.json({ error: 'Failed to sync to database' }, { status: 500 });
  }
}
