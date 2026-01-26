import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8766';

interface RouteParams {
  params: Promise<{ moduleId: string }>;
}

export async function PATCH(request: NextRequest, { params }: RouteParams) {
  try {
    const { moduleId } = await params;
    const body = await request.json();

    const response = await fetch(`${BACKEND_URL}/api/modules/${moduleId}/settings`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json({ error: `Backend error: ${error}` }, { status: response.status });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error updating module settings:', error);
    return NextResponse.json({ error: 'Failed to update module settings' }, { status: 500 });
  }
}
