import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

export async function GET() {
  try {
    const response = await fetch(`${BACKEND_URL}/api/kb/database-status`, {
      cache: 'no-store',
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: `Backend error: ${error}` }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error checking database status:', error);
    return NextResponse.json({ error: 'Failed to check database status' }, { status: 500 });
  }
}
