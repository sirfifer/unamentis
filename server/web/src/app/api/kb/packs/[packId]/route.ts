import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ packId: string }>;
}

/**
 * GET /api/kb/packs/[packId]
 * Get detailed information about a pack
 */
export async function GET(request: Request, { params }: RouteParams) {
  try {
    const { packId } = await params;
    const response = await fetch(`${BACKEND_URL}/api/kb/packs/${packId}`, {
      headers: {
        'Content-Type': 'application/json',
      },
      next: { revalidate: 0 },
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
    console.error('Error fetching pack:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch pack' }, { status: 503 });
  }
}

/**
 * PATCH /api/kb/packs/[packId]
 * Update pack metadata
 */
export async function PATCH(request: Request, { params }: RouteParams) {
  try {
    const { packId } = await params;
    const body = await request.json();

    const response = await fetch(`${BACKEND_URL}/api/kb/packs/${packId}`, {
      method: 'PATCH',
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
    console.error('Error updating pack:', error);
    return NextResponse.json({ success: false, error: 'Failed to update pack' }, { status: 503 });
  }
}

/**
 * DELETE /api/kb/packs/[packId]
 * Delete a pack
 */
export async function DELETE(request: Request, { params }: RouteParams) {
  try {
    const { packId } = await params;
    const response = await fetch(`${BACKEND_URL}/api/kb/packs/${packId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
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
    console.error('Error deleting pack:', error);
    return NextResponse.json({ success: false, error: 'Failed to delete pack' }, { status: 503 });
  }
}
