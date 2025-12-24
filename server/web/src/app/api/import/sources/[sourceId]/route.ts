import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ sourceId: string }>;
}

/**
 * GET /api/import/sources/[sourceId]
 * Get details for a specific source
 */
export async function GET(request: NextRequest, { params }: RouteParams) {
  const { sourceId } = await params;

  try {
    const response = await fetch(`${BACKEND_URL}/api/import/sources/${sourceId}`, {
      next: { revalidate: 60 },
    });

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json(
          { success: false, error: `Source not found: ${sourceId}` },
          { status: 404 }
        );
      }
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error(`Error fetching source ${sourceId}:`, error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch source details' },
      { status: 503 }
    );
  }
}
