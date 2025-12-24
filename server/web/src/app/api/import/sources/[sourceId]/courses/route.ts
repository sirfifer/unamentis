import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ sourceId: string }>;
}

/**
 * GET /api/import/sources/[sourceId]/courses
 * Get course catalog for a source
 *
 * Query parameters:
 * - page: Page number (default: 1)
 * - pageSize: Items per page (default: 20)
 * - search: Search query
 * - subject: Subject filter
 * - level: Level filter
 * - features: Feature filter (comma-separated)
 */
export async function GET(request: NextRequest, { params }: RouteParams) {
  const { sourceId } = await params;
  const searchParams = request.nextUrl.searchParams;

  try {
    // Forward all query parameters to backend
    const queryString = searchParams.toString();
    const url = `${BACKEND_URL}/api/import/sources/${sourceId}/courses${queryString ? `?${queryString}` : ''}`;

    const response = await fetch(url, {
      next: { revalidate: 300 }, // Cache for 5 minutes
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
    console.error(`Error fetching courses for ${sourceId}:`, error);
    return NextResponse.json(
      {
        success: false,
        courses: [],
        pagination: { page: 1, pageSize: 20, total: 0, totalPages: 0 },
        error: 'Failed to fetch courses',
      },
      { status: 503 }
    );
  }
}
