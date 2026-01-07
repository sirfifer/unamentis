import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

/**
 * GET /api/import/jobs
 * List all import jobs
 *
 * Query parameters:
 * - status: Filter by status (optional)
 */
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const status = searchParams.get('status');

  try {
    const url = status
      ? `${BACKEND_URL}/api/import/jobs?status=${status}`
      : `${BACKEND_URL}/api/import/jobs`;

    const response = await fetch(url, {
      cache: 'no-store', // Always get fresh data for jobs
    });

    if (!response.ok) {
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching import jobs:', error);
    return NextResponse.json(
      { success: false, jobs: [], error: 'Failed to fetch import jobs' },
      { status: 503 }
    );
  }
}

/**
 * POST /api/import/jobs
 * Start a new import job
 *
 * Request body: ImportConfig
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const response = await fetch(`${BACKEND_URL}/api/import/jobs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      return NextResponse.json(data, { status: response.status });
    }

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error starting import:', error);
    return NextResponse.json({ success: false, error: 'Failed to start import' }, { status: 503 });
  }
}
