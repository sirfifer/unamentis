import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ jobId: string }>;
}

/**
 * GET /api/import/jobs/[jobId]
 * Get progress for an import job
 */
export async function GET(request: NextRequest, { params }: RouteParams) {
  const { jobId } = await params;

  try {
    const response = await fetch(`${BACKEND_URL}/api/import/jobs/${jobId}`, {
      cache: 'no-store', // Always get fresh progress
    });

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json(
          { success: false, error: `Job not found: ${jobId}` },
          { status: 404 }
        );
      }
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error(`Error fetching job progress ${jobId}:`, error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch job progress' },
      { status: 503 }
    );
  }
}

/**
 * DELETE /api/import/jobs/[jobId]
 * Cancel an import job
 */
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  const { jobId } = await params;

  try {
    const response = await fetch(`${BACKEND_URL}/api/import/jobs/${jobId}`, {
      method: 'DELETE',
    });

    if (!response.ok) {
      if (response.status === 400) {
        const data = await response.json();
        return NextResponse.json(data, { status: 400 });
      }
      throw new Error(`Backend returned ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error(`Error cancelling job ${jobId}:`, error);
    return NextResponse.json(
      { success: false, error: 'Failed to cancel job' },
      { status: 503 }
    );
  }
}
