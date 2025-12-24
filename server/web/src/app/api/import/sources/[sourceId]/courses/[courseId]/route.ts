import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ sourceId: string; courseId: string }>;
}

/**
 * GET /api/import/sources/[sourceId]/courses/[courseId]
 * Get detailed information for a specific course
 */
export async function GET(request: NextRequest, { params }: RouteParams) {
  const { sourceId, courseId } = await params;

  try {
    const response = await fetch(
      `${BACKEND_URL}/api/import/sources/${sourceId}/courses/${courseId}`,
      { next: { revalidate: 300 } }
    );

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json(
          { success: false, error: `Course not found: ${courseId}` },
          { status: 404 }
        );
      }
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error(`Error fetching course ${sourceId}/${courseId}:`, error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch course details' },
      { status: 503 }
    );
  }
}
