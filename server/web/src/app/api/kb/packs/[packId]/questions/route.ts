import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ packId: string }>;
}

/**
 * POST /api/kb/packs/[packId]/questions
 * Add questions to a pack
 */
export async function POST(request: Request, { params }: RouteParams) {
  try {
    const { packId } = await params;
    const body = await request.json();

    const response = await fetch(`${BACKEND_URL}/api/kb/packs/${packId}/questions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      return NextResponse.json(
        { success: false, error: error.error || `Backend returned ${response.status}` },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error adding questions to pack:', error);
    return NextResponse.json({ success: false, error: 'Failed to add questions' }, { status: 503 });
  }
}
