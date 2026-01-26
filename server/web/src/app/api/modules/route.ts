import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const includeDisabled = searchParams.get('include_disabled') || 'false';

    const response = await fetch(`${BACKEND_URL}/api/modules?include_disabled=${includeDisabled}`, {
      cache: 'no-store',
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: `Backend error: ${error}` }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching modules:', error);
    return NextResponse.json({ error: 'Failed to fetch modules' }, { status: 500 });
  }
}
