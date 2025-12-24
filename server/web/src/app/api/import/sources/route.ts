import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

/**
 * GET /api/import/sources
 * Get list of all registered curriculum sources
 */
export async function GET() {
  try {
    const response = await fetch(`${BACKEND_URL}/api/import/sources`, {
      next: { revalidate: 60 }, // Cache for 1 minute
    });

    if (!response.ok) {
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching import sources:', error);
    return NextResponse.json(
      {
        success: false,
        sources: [],
        error: 'Failed to fetch import sources',
      },
      { status: 503 }
    );
  }
}
